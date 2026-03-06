# -*- coding: utf-8 -*-
from datetime import timedelta
from odoo import fields


def compute_summary(env, today, company_ids):
    """
    Live summary from stock.picking to avoid KPI lag and to count Lines as stock.move.
    Returns list with two rows: flow='out' and flow='in'.
    """
    Picking = env['stock.picking'].sudo()
    Move = env['stock.move'].sudo()
    MoveLine = env['stock.move.line'].sudo()

    start_dt = fields.Datetime.to_datetime(f"{today} 00:00:00")
    end_dt = start_dt + timedelta(days=1)

    def live(flow):
        code = 'outgoing' if flow == 'out' else 'incoming'
        dom = [
            ('company_id', 'in', company_ids),
            ('picking_type_id.code', '=', code),
            ('state', '=', 'done'),
            ('date_done', '>=', start_dt), ('date_done', '<', end_dt),
        ]
        picks = Picking.search(dom)
        pickings_done = len(picks)

        lines_done = 0
        qty_done = 0.0
        if picks:
            lines_done = Move.search_count([('picking_id', 'in', picks.ids)])
            mls = MoveLine.search([('picking_id', 'in', picks.ids)])
            qty_done = sum(mls.mapped('qty_done')) if mls else 0.0

        in_deadline_count = len(picks.filtered(lambda p: getattr(p, 'x_flf_in_deadline', False)))
        pct_in_deadline = (in_deadline_count * 100.0 / pickings_done) if pickings_done else 0.0

        durations = []
        for p in picks:
            ts = getattr(p, 'x_flf_print_ts', None)
            dd = p.date_done
            if ts and dd:
                try:
                    durations.append((dd - ts).total_seconds())
                except Exception:
                    pass
        avg_sec_print_to_done = (sum(durations) / len(durations)) if durations else 0.0

        if flow == 'out':
            risk_domain = [
                ('company_id', 'in', company_ids),
                ('picking_type_id.code', '=', 'outgoing'),
                ('x_flf_risk_today', '=', True),
            ]
            pickings_risk_count = Picking.search_count(risk_domain)
        else:
            pickings_risk_count = 0

        offday_shipments = pickings_done if today.weekday() == 6 else 0

        return {
            'flow': flow,
            'pickings_done': pickings_done,
            'lines_done': lines_done,
            'qty_done': qty_done,
            'pct_in_deadline': pct_in_deadline,
            'avg_sec_print_to_done': avg_sec_print_to_done,
            'pickings_risk_count': pickings_risk_count,
            'offday_shipments': offday_shipments,
        }

    return [live('out'), live('in')]
