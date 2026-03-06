# -*- coding: utf-8 -*-
from collections import defaultdict
from datetime import timedelta
from odoo import fields


def compute_summary(env, today, company_ids):
    """Delegate to lightweight module to keep file size small."""
    from .wallboard_summary import compute_summary as _compute
    return _compute(env, today, company_ids)


def compute_partners(env, start_dt, end_dt, company_ids):
    """Delegate to wallboard_partners implementation."""
    from . import wallboard_partners as wp
    return wp.compute_partners(env, start_dt, end_dt, company_ids)


def compute_at_risk(env, company_ids):
    Picking = env['stock.picking'].sudo()
    # Межі «сьогодні» у часовій зоні користувача → UTC naive
    today = fields.Date.context_today(env['stock.picking'])
    start_dt = fields.Datetime.to_datetime(f"{today} 00:00:00")
    end_dt = start_dt + timedelta(days=1)
    base = [
        ('company_id', 'in', company_ids),
        ('picking_type_id.code', '=', 'outgoing'),
        ('state', '!=', 'done'),
    ]
    recs = Picking.search(base + [
        ('x_flf_risk_today', '=', True),
        ('create_date', '>=', start_dt), ('create_date', '<', end_dt),
    ], order='x_flf_deadline_at asc', limit=30)
    if not recs:
        # Фолбек: беремо лише сьогоднішні створені OUT з відомим дедлайном
        recs = Picking.search(base + [
            ('x_flf_deadline_at', '!=', False),
            ('create_date', '>=', start_dt), ('create_date', '<', end_dt),
        ], order='x_flf_deadline_at asc', limit=60)
    now = fields.Datetime.now()
    # Group by company: keep earliest deadline and summarize count
    by_co = {}
    for r in recs:
        ddl = getattr(r, 'x_flf_deadline_at', False)
        if not ddl:
            continue
        soft_min = getattr(r.partner_id, 'x_flf_soft_window_minutes', 0) or 0
        ddl_soft = ddl + timedelta(minutes=soft_min)
        key = r.company_id.id
        ent = by_co.get(key)
        row = {
            'name': r.name,
            'partner': r.partner_id.display_name,
            'company': r.company_id.name,
            'deadline': ddl_soft if soft_min else ddl,
            'time_to_deadline_sec': (ddl_soft - now).total_seconds(),
            '_count': 1,
        }
        if not ent or row['time_to_deadline_sec'] < ent['time_to_deadline_sec']:
            by_co[key] = row
        else:
            ent['_count'] += 1
            by_co[key] = ent
    # finalize partner label to show totals
    rows = []
    for v in by_co.values():
        cnt = v.pop('_count', 1)
        if cnt > 1:
            v['partner'] = f"{v['partner']} (+{cnt-1})"
        rows.append(v)
    rows.sort(key=lambda x: x['time_to_deadline_sec'] if x['time_to_deadline_sec'] is not None else 10**9)
    return rows[:12]


def compute_tops(env, today, company_ids):
    KPI = env['flf.performance.kpi'].sudo()
    start_week = fields.Date.from_string(str(today)) - timedelta(days=6)
    start_month = fields.Date.from_string(str(today)) - timedelta(days=29)

    def _top(period_start):
        dom = [('date', '>=', period_start), ('date', '<=', today), ('company_id', 'in', company_ids), ('flow', '=', 'out')]
        rows = KPI.search_read(dom, ['user_id', 'partner_id', 'pickings_done', 'lines_done', 'qty_done'])
        by_user = {}
        by_partner = {}
        for r in rows:
            if r.get('user_id'):
                uid, uname = r['user_id']
                u = by_user.setdefault(uid, {'name': uname, 'orders': 0, 'lines': 0, 'qty': 0.0})
                u['orders'] += r['pickings_done']
                u['lines'] += r['lines_done']
                u['qty'] += r['qty_done']
            if r.get('partner_id'):
                pid, pname = r['partner_id']
                p = by_partner.setdefault(pid, {'name': pname, 'orders': 0, 'lines': 0, 'qty': 0.0})
                p['orders'] += r['pickings_done']
                p['lines'] += r['lines_done']
                p['qty'] += r['qty_done']
        if not by_user and not by_partner:
            Picking = env['stock.picking'].sudo()
            start_dt = fields.Datetime.to_datetime(f"{period_start} 00:00:00")
            end_dt = fields.Datetime.to_datetime(f"{today} 00:00:00") + timedelta(days=1)
            picks = Picking.search([
                ('company_id', 'in', company_ids),
                ('picking_type_id.code', '=', 'outgoing'),
                ('state', '=', 'done'),
                ('date_done', '>=', start_dt), ('date_done', '<', end_dt),
            ])
            for p in picks:
                u = getattr(p, 'x_flf_done_user_id', False)
                if u:
                    uu = by_user.setdefault(u.id, {'name': u.name, 'orders': 0, 'lines': 0, 'qty': 0.0})
                    uu['orders'] += 1
                    for mv in p.move_line_ids:
                        uu['lines'] += 1
                        uu['qty'] += mv.qty_done or 0.0
                par = p.partner_id
                if par:
                    pp = by_partner.setdefault(par.id, {'name': par.display_name, 'orders': 0, 'lines': 0, 'qty': 0.0})
                    pp['orders'] += 1
                    for mv in p.move_line_ids:
                        pp['lines'] += 1
                        pp['qty'] += mv.qty_done or 0.0
        def topn(d, key, n=5):
            return sorted(d.values(), key=lambda x: (-x[key], -x['orders']))[:n]
        return {
            'users': {'orders': topn(by_user, 'orders'), 'lines': topn(by_user, 'lines'), 'qty': topn(by_user, 'qty')},
            'partners': {'orders': topn(by_partner, 'orders'), 'lines': topn(by_partner, 'lines'), 'qty': topn(by_partner, 'qty')},
        }

    return {'day': _top(today), 'week': _top(start_week), 'month': _top(start_month)}
