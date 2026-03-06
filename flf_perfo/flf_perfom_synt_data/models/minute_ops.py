# -*- coding: utf-8 -*-
from datetime import timedelta
import random
from odoo import api, fields, models
from .outgoing_helper import resolve_locations


class FlfPerfSyntOps(models.AbstractModel):
    _name = 'flf.perf.synt.ops'
    _description = 'Ops helpers for synthetic minute engine'

    @api.model
    def new_outgoings(self, company, out_type, origin, now, n_new):
        U = self.env['flf.perf.synt.util'].sudo()
        Picking = self.env['stock.picking'].sudo()
        Move = self.env['stock.move'].sudo()
        MoveLine = self.env['stock.move.line'].sudo()
        uom_unit = self.env.ref('uom.product_uom_unit')
        for _ in range(n_new):
            partner = U.choose_partner(company)
            prod, avail, src_loc = U.available_product(company)
            if not prod or avail <= 0:
                continue
            qty = U.pick_qty()
            if qty >= 50 and not U.big_order_today_once(company):
                qty = min(3, int(avail) or 1)
            qty = min(qty, int(avail) or 1)
            src, dst = resolve_locations(self.env, out_type, company)
            if src_loc:
                src = src_loc
            if not (src and dst):
                continue
            p = Picking.with_company(company).create({
                'picking_type_id': out_type.id,
                'company_id': company.id,
                'partner_id': partner.id if partner else False,
                'origin': origin,
                'location_id': src,
                'location_dest_id': dst,
                'scheduled_date': now + timedelta(minutes=random.randint(10, 240)),
            })
            mv = Move.create({
                'name': f'OUT {prod.display_name}',
                'picking_id': p.id,
                'product_id': prod.id,
                'product_uom': uom_unit.id,
                'product_uom_qty': float(qty),
                'location_id': p.location_id.id,
                'location_dest_id': p.location_dest_id.id,
                'company_id': company.id,
            })
            if not getattr(partner, 'x_flf_use_draft_trigger', False):
                try:
                    p.action_confirm(); p.action_assign()
                except Exception:
                    pass
            if not mv.move_line_ids:
                MoveLine.create({'move_id': mv.id, 'picking_id': p.id, 'product_id': prod.id,
                                 'product_uom_id': uom_unit.id, 'qty_done': 0.0,
                                 'location_id': p.location_id.id, 'location_dest_id': p.location_dest_id.id,
                                 'company_id': company.id})
        return True
