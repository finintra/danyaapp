# -*- coding: utf-8 -*-
from datetime import timedelta
import random
from odoo import fields
from .outgoing_helper import setup_outgoing, resolve_locations


def run_daily_init(env, per_company_out=8, per_company_in=2, force=False):
    PickingType = env['stock.picking.type'].sudo()
    Partner = env['res.partner'].sudo()
    Picking = env['stock.picking'].sudo()
    ICP = env['ir.config_parameter'].sudo()

    per_company_out = int(ICP.get_param('flf_perf_synt.per_company_out', per_company_out))
    per_company_in = int(ICP.get_param('flf_perf_synt.per_company_in', per_company_in))

    today = fields.Date.context_today(env['stock.picking'])
    start_dt = fields.Datetime.to_datetime(f"{today} 00:00:00")
    end_dt = start_dt + timedelta(days=1)
    origin = f"DEMO {fields.Date.today()}"

    # skip check moved per-company below

    companies = env['res.company'].sudo().browse(
        env['flf.perf.synt.util'].sudo().allowed_companies()
    )

    created = 0
    for c in companies:
        if not force:
            existing = Picking.search_count([
                ('origin', '=', origin),
                ('company_id', '=', c.id),
                ('create_date', '>=', start_dt), ('create_date', '<', end_dt),
            ])
            if existing:
                continue
        partners = Partner.search([('is_company', '=', True)], limit=50)
        if not partners:
            continue
        out_type = PickingType.search([('company_id', '=', c.id), ('code', '=', 'outgoing')], limit=1)
        in_type = PickingType.search([('company_id', '=', c.id), ('code', '=', 'incoming')], limit=1)
        if not out_type:
            continue

        def _create(type_rec, partner, printed=False, risk=False, minutes_to_deadline=120):
            src, dst = resolve_locations(env, type_rec, c)
            if not (src and dst):
                return False
            p = Picking.create({
                'picking_type_id': type_rec.id,
                'company_id': c.id,
                'partner_id': partner.id,
                'origin': origin,
                'location_id': src,
                'location_dest_id': dst,
                'scheduled_date': fields.Datetime.now() + timedelta(minutes=random.randint(-60, 240)),
            })
            if getattr(type_rec, 'code', '') == 'outgoing':
                ok = True
                try:
                    mv = setup_outgoing(env, p, partner, c, type_rec)
                    ok = bool(mv)
                except Exception:
                    ok = False
                if not ok:
                    try:
                        p.unlink()
                    except Exception:
                        pass
                    return False
            ddl = fields.Datetime.now() + timedelta(minutes=minutes_to_deadline)
            if hasattr(p, 'x_flf_deadline_at'):
                p.sudo().write({'x_flf_deadline_at': ddl})
            if printed and hasattr(p, 'x_flf_print_ts'):
                try:
                    if p.state == 'draft' and not getattr(partner, 'x_flf_use_draft_trigger', False):
                        p.action_confirm(); p.action_assign()
                except Exception:
                    pass
                if p.state == 'assigned':
                    p.sudo().write({'x_flf_print_ts': fields.Datetime.now() - timedelta(minutes=random.randint(1, 90))})
            if risk and hasattr(p, 'x_flf_risk_today'):
                p.sudo().write({'x_flf_risk_today': True})
            return p

        # Outgoing (each attempt isolated to avoid aborting whole txn)
        for i in range(per_company_out):
            partner = random.choice(partners)
            printed = (i % 3 == 0)
            risk = (i == 0)
            try:
                with env.cr.savepoint():
                    if _create(out_type, partner, printed=printed, risk=risk, minutes_to_deadline=random.choice([20, 45, 90, 180])):
                        created += 1
            except Exception:
                # ignore and continue to next attempt
                pass

        # Incoming
        if in_type:
            for i in range(per_company_in):
                partner = random.choice(partners)
                try:
                    with env.cr.savepoint():
                        if _create(in_type, partner, printed=False, risk=False, minutes_to_deadline=random.choice([60, 120])):
                            created += 1
                except Exception:
                    pass

    return {'created': created, 'origin': origin}
