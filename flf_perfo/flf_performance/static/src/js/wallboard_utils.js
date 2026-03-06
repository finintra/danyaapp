odoo.define('flf_performance.WallboardUtils', function (require) {
    'use strict';

    const session = require('web.session');

    function _label(v){
        if (typeof v === 'string') return v;
        if (!v) return '';
        if (Array.isArray(v)) return v[1] || String(v[0] || '');
        return v.name || String(v);
    }

    function fmtPct1(v){
        const n = Number(v||0);
        return (Math.round(n*10)/10).toFixed(1);
    }

    function fmtMin1(sec){
        const n = Number(sec||0)/60.0;
        return (Math.round(n*10)/10).toFixed(1);
    }

    function companyRows(items, idsOverride){
        const allowedDict = (session.user_companies && session.user_companies.allowed_companies) || {};
        let ids = (idsOverride && idsOverride.length) ? idsOverride.slice() : Object.keys(allowedDict).map(x=>parseInt(x,10));
        if (!ids.length) {
            const ctxIds = (session.user_context && session.user_context.allowed_company_ids) || [];
            ids = (ctxIds && ctxIds.length) ? ctxIds.map(x=>parseInt(x,10)) : (session.company_id ? [session.company_id] : []);
        }
        const flows = ['out','in'];
        const nameById = {}; ids.forEach(id=>{ nameById[id] = _label(allowedDict[id]) || ('Company ' + id); });
        const key = (cid,flow)=>cid+':'+flow;
        const map = {}; ids.forEach(cid=>{ flows.forEach(flow=>{ map[key(cid,flow)] = {
            company_id: cid, company_name: nameById[cid], flow,
            unprinted:0, printed_not_picked:0, done:0, overdue:0,
            time_to_deadline_sec:null, waiting_count:0, waiting_oldest:null, waiting_new_today:0,
            users_today:[], print_sum_sec:0, print_n:0, print_avg_min:0
        }; }); });
        const idByName = {}; Object.keys(nameById).forEach(id=>{ idByName[nameById[id]] = parseInt(id,10); });
        const userAgg = {};
        (items||[]).forEach(r=>{
            const cid = r.company_id || idByName[r.company_name];
            const flow = r.flow || 'out';
            const k = key(cid, flow);
            if (!cid || !map[k]) return;
            const t = map[k];
            t.unprinted += r.unprinted||0; t.printed_not_picked += r.printed_not_picked||0; t.done += r.done||0; t.overdue += r.overdue||0;
            if (r.time_to_deadline_sec != null) t.time_to_deadline_sec = (t.time_to_deadline_sec==null) ? r.time_to_deadline_sec : Math.min(t.time_to_deadline_sec, r.time_to_deadline_sec);
            t.waiting_count += r.waiting_count||0; t.waiting_new_today += r.waiting_new_today||0;
            if (r.waiting_oldest && (!t.waiting_oldest || r.waiting_oldest < t.waiting_oldest)) t.waiting_oldest = r.waiting_oldest;
            if (r.print_sum_sec) t.print_sum_sec += r.print_sum_sec; if (r.print_n) t.print_n += r.print_n;
            (r.users_today||[]).forEach(u=>{ userAgg[k] = userAgg[k] || {}; userAgg[k][u.name] = (userAgg[k][u.name]||0)+(u.count||0); });
        });
        Object.keys(userAgg).forEach(k=>{ map[k].users_today = Object.keys(userAgg[k]).map(name=>({name, count:userAgg[k][name]})); });
        Object.keys(map).forEach(k=>{ const t = map[k]; t.print_avg_min = t.print_n ? (Math.round(((t.print_sum_sec/t.print_n)/60)*10)/10) : 0; });
        // Порядок: для кожної компанії спочатку out, потім in
        const rows = [];
        ids.forEach(cid=>{ flows.forEach(flow=>{ rows.push(map[key(cid,flow)]); }); });
        return rows;
    }

    function deadlineHint(row){
        if (row.time_to_deadline_sec == null) return '';
        const now = new Date(); const dl = new Date(now.getTime() + row.time_to_deadline_sec*1000);
        const pad=n=>n<10?'0'+n:''+n; const hhmm = pad(dl.getHours())+':'+pad(dl.getMinutes());
        const mm = Math.round(row.time_to_deadline_sec/60); const sign = (mm>=0?'+':'');
        const sameDay = now.toDateString() === dl.toDateString();
        return (sameDay?hhmm+' ':'— ') + '('+sign+mm+'m)';
    }

    function makeTopsFromPartners(partners){
        const byUser = {}; (partners||[]).forEach(r=>{ (r.users_today||[]).forEach(u=>{ byUser[u.name]=(byUser[u.name]||0)+(u.count||0); }); });
        return Object.keys(byUser).map(name=>({name, orders: byUser[name]})).sort((a,b)=> (b.orders - a.orders)).slice(0,5);
    }

    return { companyRows, deadlineHint, makeTopsFromPartners, fmtPct1, fmtMin1 };
});
