console.log('[flf_performance] wallboard.js asset loaded');
odoo.define('flf_performance.WallboardAction', function (require) {
    'use strict';

    const AbstractAction = require('web.AbstractAction');
    const core = require('web.core');
    const rpc = require('web.rpc');
    const session = require('web.session');
    const Utils = require('flf_performance.WallboardUtils');
    const qweb = core.qweb;

    const WallboardAction = AbstractAction.extend({
        template: 'flf_performance.Wallboard',
        init() {
            this._super.apply(this, arguments);
            if (!this.$el || !this.el || typeof (this.$el && this.$el.on) !== 'function') {
                this.setElement(document.createElement('div'));
            }
            this.kpis = [];
            this._interval = null;
            this._rotate = null;
            this._page = 0;
            this._pageSize = 12;
            this._lastH = 0;
            this._coIds = [];
            this._coIndex = 0;
            this._byCo = {}; // company_id -> payload
            this.payload = {summary: [], partners: [], at_risk: [], tops: {}, refresh: {interval_sec: 30, offset_base: 0}};
            this._refreshMs = 30000;
        },
        willStart() {
            // важливо: лише ініціалізація базового Action; перший рендер чекатиме повне оновлення
            return this._super.apply(this, arguments);
        },
        start() {
            return this._super.apply(this, arguments).then(async () => {
                // перший рендер лише після повного оновлення всіх компаній
                await this._fetchKpis(true);
                this._render();
                // періодичне оновлення: одна компанія за цикл, із випадковим зсувом offset_base
                const skewMs = Math.max(0, Math.floor((((this.payload && this.payload.refresh && this.payload.refresh.offset_base) || 0) * 1000) * Math.random()));
                setTimeout(() => {
                    this._interval = setInterval(() => { this._fetchKpis(false).then(() => this._render()); }, this._refreshMs);
                }, skewMs);
                // rotate partners every ~12s
                this._rotate = setInterval(() => { this._page = (this._page + 1) % Math.max(1, this._pageCount()); this._render(); }, 12000);
                // recompute on resize
                window.addEventListener('resize', this._onResizeBound = this._onResize.bind(this));
                // manual refresh button: оновити всі компанії негайно
                if (this.$el && this.$el.off && this.$el.on) {
                    this.$el.off('click.flf_refresh').on('click.flf_refresh', '.o_flf_refresh', (ev) => {
                        ev.preventDefault();
                        this._page = 0;
                        this._fetchKpis(true).then(() => this._render());
                    });
                }
            });
        },
        renderButtons() {
            if (!this.$buttons) {
                this.$buttons = $('<div/>');
            }
            return this.$buttons;
        },
        on_attach_callback() {
            if (!this.$el) {
                const node = this.el || document.createElement('div');
                this.setElement(node);
            }
            if (!this.$buttons && typeof $ === 'function') {
                this.$buttons = $('<div/>');
            }
            // Do not call super: parent expects searchModel; we don't use it.
            // This avoids errors when AbstractAction tries to access searchModel.
        },
        on_detach_callback() {
            // Do not call super to avoid touching searchModel on detach.
        },
        destroy() {
            if (this._interval) {
                clearInterval(this._interval);
            }
            if (this._rotate) {
                clearInterval(this._rotate);
            }
            if (this._onResizeBound) {
                window.removeEventListener('resize', this._onResizeBound);
            }
            this._super.apply(this, arguments);
        },
        // _todayStr not used; removed to keep file compact
        _fetchKpis(all=false) {
            // з’ясувати перелік компаній один раз
            if (!this._coIds.length) {
                const allowedDict = (session.user_companies && session.user_companies.allowed_companies) || null;
                const allowed = allowedDict ? Object.keys(allowedDict).map((x) => parseInt(x, 10)) : ((session.user_context && session.user_context.allowed_company_ids) || []);
                this._coIds = (allowed && allowed.length) ? allowed : (session.company_id ? [session.company_id] : []);
            }
            const runOne = (cid) => {
                const ctx = Object.assign({}, session.user_context || {}, {allowed_company_ids: [cid]});
                return rpc.query({ model: 'flf.performance.wallboard', method: 'read_payload', args: [], context: ctx })
                    .then((res) => {
                        this._byCo[cid] = res || {summary: [], partners: [], at_risk: [], tops: {}};
                        const isec = (res && res.refresh && res.refresh.interval_sec) || (this.payload.refresh && this.payload.refresh.interval_sec) || 30;
                        this._refreshMs = Math.max(5000, isec * 1000);
                    });
            };
            if (all) {
                const ids = this._coIds.length ? this._coIds : (session.company_id ? [session.company_id] : []);
                const calls = ids.map((cid) => runOne(cid));
                return Promise.all(calls).then(() => { this._aggregate(); });
            } else {
                const cid = this._coIds.length ? this._coIds[this._coIndex % this._coIds.length] : null;
                this._coIndex = (this._coIndex + 1) % Math.max(1, this._coIds.length || 1);
                if (!cid) return Promise.resolve();
                return runOne(cid).then(() => { this._aggregate(); });
            }
        },
        _aggregate() {
            const payloads = Object.values(this._byCo);
            if (!payloads.length) return; // ще немає по-компанійних даних
            // summary: сума + вагові середні
            const agg = {out: {pickings_done:0,lines_done:0,qty_done:0,pickings_risk_count:0,offday_shipments:0,pct_sum:0,avg_sum:0,n:0},
                         in:  {pickings_done:0,lines_done:0,qty_done:0,pickings_risk_count:0,offday_shipments:0,pct_sum:0,avg_sum:0,n:0}};
            const out = ()=>({});
            payloads.forEach(p => {
                (p.summary||[]).forEach(s => {
                    const a = agg[s.flow];
                    a.pickings_done += s.pickings_done; a.lines_done += s.lines_done; a.qty_done += s.qty_done;
                    a.pickings_risk_count += s.pickings_risk_count; a.offday_shipments += s.offday_shipments;
                    const n = s.pickings_done || 0; if (n){ a.pct_sum += s.pct_in_deadline * n; a.avg_sum += s.avg_sec_print_to_done * n; a.n += n; }
                });
            });
            const sumToRow = (k)=>({flow:k, pickings_done:agg[k].pickings_done, lines_done:agg[k].lines_done, qty_done:agg[k].qty_done,
                                     pct_in_deadline: agg[k].n ? agg[k].pct_sum/agg[k].n : 0,
                                     avg_sec_print_to_done: agg[k].n ? agg[k].avg_sum/agg[k].n : 0,
                                     pickings_risk_count: agg[k].pickings_risk_count, offday_shipments: agg[k].offday_shipments});
            const partners = [].concat(...payloads.map(p=>p.partners||[]));
            const at_risk = [].concat(...payloads.map(p=>p.at_risk||[])).slice(0,12);
            let tops = (payloads.find(p=>p.tops && p.tops.day && p.tops.day.users && (p.tops.day.users.orders||[]).length) || {}).tops;
            if (!tops){
                // Фолбек: зробити TOPs з partners (тільки day/users/orders)
                tops = { day: { users: { orders: Utils.makeTopsFromPartners(partners) } }, week:{users:{orders:[]}}, month:{users:{orders:[]}} };
            }
            this.payload = {summary:[sumToRow('out'), sumToRow('in')], partners, at_risk, tops, refresh:this.payload.refresh};
        },
        _pageCount() {
            const rows = Utils.companyRows(((this.payload && this.payload.partners) || []).slice(), this._coIds);
            return Math.max(1, Math.ceil(rows.length / Math.max(1, this._pageSize)));
        },
        _measureAndScale() {
            // simple base on 1920x1080 for big wall displays
            const base = Math.min(window.innerWidth / 1920, window.innerHeight / 1080) || 1;
            document.documentElement.style.setProperty('--flf-base', String(Math.max(0.8, Math.min(1.6, base))));
            const h = window.innerHeight || 800;
            if (Math.abs(h - this._lastH) > 10) {
                this._lastH = h;
                // estimate available height for partners table body
                const topReserve = 140; // summary + headers approx
                const rowH = 26 * (parseFloat(getComputedStyle(document.documentElement).getPropertyValue('--flf-base')) || 1);
                const avail = Math.max(200, h - topReserve);
                this._pageSize = Math.max(6, Math.floor(avail / rowH) - 6); // reserve for AtRisk/TOPs
                this._page = Math.min(this._page, this._pageCount() - 1);
            }
        },
        _payloadWithPagination() {
            this._measureAndScale();
            const p = Object.assign({}, this.payload || {});
            if (!p.partners_scope) p.partners_scope = 'today';
            const partners = Utils.companyRows((p.partners || []).slice(), this._coIds);
            const pages = Math.max(1, Math.ceil(partners.length / Math.max(1, this._pageSize)));
            if (this._page >= pages) this._page = 0;
            const start = this._page * this._pageSize;
            const end = start + this._pageSize;
            p.partners = partners.slice(start, end);
            // keep At Risk concise
            if (p.at_risk && p.at_risk.length > 12) p.at_risk = p.at_risk.slice(0, 12);
            return p;
        },
        _render() {
            const data = this._payloadWithPagination();
            this.$el.html(qweb.render('flf_performance.Wallboard.Body', {p: data, utils: Utils}));
        },
        _onResize() {
            const oldSize = this._pageSize;
            this._measureAndScale();
            if (this._pageSize !== oldSize) {
                this._page = 0;
                this._render();
            }
        },
    });

    console.log('[flf_performance] registering action tag:', 'flf_performance.wallboard');
    core.action_registry.add('flf_performance.wallboard', WallboardAction);
    return WallboardAction;
});
