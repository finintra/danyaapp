# -*- coding: utf-8 -*-
from datetime import timedelta
import random
import logging
from odoo import api, fields, models

_logger = logging.getLogger(__name__)


class FlfPerfSyntBackfill(models.AbstractModel):
    _name = 'flf.perf.synt.backfill'
    _description = 'Backfill helpers for FLF Performance Synthetic Data'

    @api.model
    def _demo_for_date(self, day, companies, per_company=6):
        PickingType = self.env['stock.picking.type'].sudo()
        Partner = self.env['res.partner'].sudo()
        Picking = self.env['stock.picking'].sudo()
        start = fields.Datetime.to_datetime(f"{day} 00:00:00")
        origin = f"DEMO {day}"
        for c in companies:
            partners = Partner.search([('is_company', '=', True)], limit=50)
            out_type = PickingType.search([('company_id', '=', c.id), ('code', '=', 'outgoing')], limit=1)
            if not (partners and out_type):
                continue
            # resolve locations with fallbacks
            Loc = self.env['stock.location'].sudo()
            Wh = self.env['stock.warehouse'].sudo().search([('company_id', '=', c.id)], limit=1)
            wh_stock = Wh.lot_stock_id.id if Wh and Wh.lot_stock_id else False
            src_def = out_type.default_location_src_id.id if out_type.default_location_src_id else False
            dst_def = out_type.default_location_dest_id.id if out_type.default_location_dest_id else False
            src = src_def or wh_stock or Loc.search([('usage', '=', 'internal'), ('company_id', 'in', [c.id, False])], limit=1, order='company_id desc').id
            dst = dst_def or Loc.search([('usage', '=', 'customer'), ('company_id', 'in', [c.id, False])], limit=1, order='company_id desc').id
            if not (src and dst):
                _logger.warning("[flf_perf_synt] skip backfill: cannot resolve locations for company %s", c.id)
                continue
            for _ in range(per_company):
                partner = random.choice(partners)
                p = Picking.create({
                    'picking_type_id': out_type.id,
                    'company_id': c.id,
                    'partner_id': partner.id,
                    'origin': origin,
                    'location_id': src or False,
                    'location_dest_id': dst or False,
                    'scheduled_date': start + timedelta(hours=random.randint(8, 20)),
                })
                if hasattr(p, 'x_flf_deadline_at'):
                    p.sudo().write({'x_flf_deadline_at': start + timedelta(hours=17, minutes=random.choice([0, 30, 90]))})
