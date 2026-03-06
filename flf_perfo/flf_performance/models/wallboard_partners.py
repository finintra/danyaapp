# -*- coding: utf-8 -*-
from collections import defaultdict
from datetime import timedelta
from odoo import fields


def compute_partners(env, start_dt, end_dt, company_ids):
    """
    Partners by company for two flows with policy‑aware "today" and backlog totals.
    Returns rows with 'flow' in {'out','in'} so UI може показати 2 рядки на компанію.
    """
    Picking = env['stock.picking'].sudo()

    def _row(flow):
        return {
            'flow': flow,
            'partner_id': False, 'partner_name': '', 'company_name': '', 'company_id': False,
            'unprinted': 0, 'printed_not_picked': 0, 'done': 0, 'overdue': 0,
            'time_to_deadline_sec': None,
            'waiting_count': 0, 'waiting_oldest': None, 'waiting_new_today': 0,
            'users_today': [],
            'deadline_at': None, 'soft_deadline_at': None,
            'print_sum_sec': 0, 'print_n': 0,
        }

    def _finalize(rows):
        lst = [v for v in rows.values() if (v['unprinted'] or v['printed_not_picked'] or v['done'] or v['waiting_count'])]
        def _key(x):
            t = x['time_to_deadline_sec'] if x['time_to_deadline_sec'] is not None else 10**9
            return (t, -x['waiting_count'])
        lst.sort(key=_key)
        return lst

    now = fields.Datetime.now()

    # --- OUT ---
    base_out = [('company_id', 'in', company_ids), ('picking_type_id.code', '=', 'outgoing')]
    rows_out = defaultdict(lambda: _row('out'))

    # backlog: всі не done
    for p in Picking.search(base_out + [('state', '!=', 'done')]):
        k = rows_out[p.partner_id.id]
        k.update({'partner_id': p.partner_id.id, 'partner_name': p.partner_id.display_name, 'company_name': p.company_id.name, 'company_id': p.company_id.id})
        if getattr(p, 'x_flf_print_ts', False):
            k['printed_not_picked'] += 1
        else:
            k['unprinted'] += 1
        ddl = getattr(p, 'x_flf_deadline_at', False)
        if ddl:
            soft_min = getattr(p.partner_id, 'x_flf_soft_window_minutes', 0) or 0
            ddl_soft = ddl + timedelta(minutes=soft_min)
            delta = (ddl_soft - now).total_seconds()
            if (k['time_to_deadline_sec'] is None) or (delta < k['time_to_deadline_sec']):
                k['time_to_deadline_sec'] = delta
            k['deadline_at'] = ddl
            k['soft_deadline_at'] = ddl_soft
            if ddl_soft <= now:
                k['overdue'] += 1

    # сьогодні для latency
    undone_draft = Picking.search(base_out + [('state', '!=', 'done'), ('partner_id.x_flf_use_draft_trigger', '=', True), ('create_date', '>=', start_dt), ('create_date', '<', end_dt)])
    undone_ready = Picking.search(base_out + [('state', '!=', 'done'), ('partner_id.x_flf_use_draft_trigger', '=', False), ('x_flf_ready_ts', '!=', False), ('x_flf_ready_ts', '>=', start_dt), ('x_flf_ready_ts', '<', end_dt)])
    for p in (undone_draft | undone_ready):
        k = rows_out[p.partner_id.id]
        pts = getattr(p, 'x_flf_print_ts', False)
        if pts:
            base_ts = p.create_date if getattr(p.partner_id, 'x_flf_use_draft_trigger', False) else (getattr(p, 'x_flf_ready_ts', False) or p.scheduled_date or p.create_date)
            if base_ts:
                try:
                    k['print_sum_sec'] += max(0.0, (pts - base_ts).total_seconds())
                    k['print_n'] += 1
                except Exception:
                    pass

    # done + users
    for p in Picking.search(base_out + [('state', '=', 'done'), ('date_done', '>=', start_dt), ('date_done', '<', end_dt)]):
        k = rows_out[p.partner_id.id]
        k.update({'partner_id': p.partner_id.id, 'partner_name': p.partner_id.display_name, 'company_name': p.company_id.name, 'company_id': p.company_id.id})
        k['done'] += 1
        du = getattr(p, 'x_flf_done_user_id', False)
        if du:
            k.setdefault('_users', defaultdict(int))[du.id] += 1

    # waiting total + new today
    for p in Picking.search(base_out + [('state', 'in', ('waiting', 'confirmed'))]):
        k = rows_out[p.partner_id.id]
        k['waiting_count'] += 1
        if p.scheduled_date and ((k['waiting_oldest'] is None) or (p.scheduled_date < k['waiting_oldest'])):
            k['waiting_oldest'] = p.scheduled_date
    for p in (Picking.search(base_out + [('state', 'in', ('waiting', 'confirmed')), ('partner_id.x_flf_use_draft_trigger', '=', True), ('create_date', '>=', start_dt), ('create_date', '<', end_dt)]) | Picking.search(base_out + [('state', 'in', ('waiting', 'confirmed')), ('partner_id.x_flf_use_draft_trigger', '=', False), ('x_flf_ready_ts', '!=', False), ('x_flf_ready_ts', '>=', start_dt), ('x_flf_ready_ts', '<', end_dt)])):
        rows_out[p.partner_id.id]['waiting_new_today'] += 1

    for k in rows_out.values():
        users_map = k.pop('_users', {}) or {}
        if users_map:
            users = env['res.users'].browse(list(users_map.keys()))
            k['users_today'] = [{'name': u.name, 'count': users_map[u.id]} for u in users]

    out_rows = _finalize(rows_out)

    # --- IN ---
    base_in = [('company_id', 'in', company_ids), ('picking_type_id.code', '=', 'incoming')]
    rows_in = defaultdict(lambda: _row('in'))

    for p in Picking.search(base_in + [('state', '!=', 'done')]):
        k = rows_in[p.partner_id.id]
        k.update({'partner_id': p.partner_id.id, 'partner_name': p.partner_id.display_name, 'company_name': p.company_id.name, 'company_id': p.company_id.id})
        if getattr(p, 'x_flf_print_ts', False):
            k['printed_not_picked'] += 1
        else:
            k['unprinted'] += 1
        max_days = int(getattr(p.partner_id, 'x_flf_inbound_max_days', 2) or 2)
        base_ts = p.scheduled_date or p.create_date
        if base_ts:
            ddl_soft = base_ts + timedelta(days=max_days)
            delta = (ddl_soft - now).total_seconds()
            if (k['time_to_deadline_sec'] is None) or (delta < k['time_to_deadline_sec']):
                k['time_to_deadline_sec'] = delta
            k['soft_deadline_at'] = ddl_soft
            if ddl_soft <= now:
                k['overdue'] += 1

    for p in Picking.search(base_in + [('state', '=', 'done'), ('date_done', '>=', start_dt), ('date_done', '<', end_dt)]):
        k = rows_in[p.partner_id.id]
        k.update({'partner_id': p.partner_id.id, 'partner_name': p.partner_id.display_name, 'company_name': p.company_id.name, 'company_id': p.company_id.id})
        k['done'] += 1
        du = getattr(p, 'x_flf_done_user_id', False)
        if du:
            k.setdefault('_users', defaultdict(int))[du.id] += 1

    for p in Picking.search(base_in + [('state', 'in', ('waiting', 'confirmed'))]):
        k = rows_in[p.partner_id.id]
        k['waiting_count'] += 1
        if p.scheduled_date and ((k['waiting_oldest'] is None) or (p.scheduled_date < k['waiting_oldest'])):
            k['waiting_oldest'] = p.scheduled_date
    for p in Picking.search(base_in + [('state', 'in', ('waiting', 'confirmed')), ('create_date', '>=', start_dt), ('create_date', '<', end_dt)]):
        rows_in[p.partner_id.id]['waiting_new_today'] += 1

    for k in rows_in.values():
        users_map = k.pop('_users', {}) or {}
        if users_map:
            users = env['res.users'].browse(list(users_map.keys()))
            k['users_today'] = [{'name': u.name, 'count': users_map[u.id]} for u in users]

    in_rows = _finalize(rows_in)

    return out_rows + in_rows
