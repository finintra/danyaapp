# -*- coding: utf-8 -*-
from odoo import api, fields, models
import random


class FlfPerfSyntUtil(models.AbstractModel):
    _name = 'flf.perf.synt.util'
    _description = 'Utils for synthetic minute engine'

    @api.model
    def allowed_companies(self):
        ids = self.env.context.get('allowed_company_ids') or self.env.user.company_ids.ids
        try:
            test_ids = self.env['res.company'].sudo().search([('name', 'ilike', 'FLF Test Co')]).ids
            if test_ids:
                ids = list({*(ids or []), *test_ids})
        except Exception:
            pass
        return ids or [self.env.company.id]

    @api.model
    def today_origin(self):
        return f"DEMO {fields.Date.today()}"

    @api.model
    def company_weight(self, company):
        return int(getattr(company, 'x_flf_synt_weight', 1) or 1)

    @api.model
    def pick_types(self, company):
        Wh = self.env['stock.warehouse'].sudo().search([('company_id', '=', company.id)], limit=1)
        if not Wh:
            return (False, False)
        out_type = Wh.out_type_id or self.env['stock.picking.type'].sudo().search([
            ('warehouse_id', '=', Wh.id), ('code', '=', 'outgoing')
        ], limit=1)
        in_type = Wh.in_type_id or self.env['stock.picking.type'].sudo().search([
            ('warehouse_id', '=', Wh.id), ('code', '=', 'incoming')
        ], limit=1)
        return (out_type, in_type)

    @api.model
    def choose_partner(self, company):
        Partner = self.env['res.partner'].sudo()
        # grab small pool and pick randomly in Python (avoid SQL random())
        pool = Partner.search([('is_company', '=', True), ('company_id', 'in', [company.id, False])], limit=30)
        if pool:
            return random.choice(pool)
        pool2 = Partner.search([('is_company', '=', True)], limit=30)
        if pool2:
            return random.choice(pool2)
        return False

    @api.model
    def pick_qty(self):
        r = random.random()
        if r < 0.80:
            return 1
        if r < 0.99:
            return random.randint(2, 8)
        return random.randint(50, 100)

    @api.model
    def big_order_today_once(self, company):
        ICP = self.env['ir.config_parameter'].sudo()
        key = f"flf_perf_synt.big_once_{company.id}_{fields.Date.today()}"
        if ICP.get_param(key):
            return False
        ICP.set_param(key, '1')
        return True

    @api.model
    def available_product(self, company):
        Quant = self.env['stock.quant'].sudo()
        # Прив’язуємося до складу (wh_stock) компанії, щоб Reservation працював
        Wh = self.env['stock.warehouse'].sudo().search([('company_id', '=', company.id)], limit=1)
        wh_stock = Wh.lot_stock_id.id if Wh and Wh.lot_stock_id else False
        domain = [
            ('company_id', 'in', [company.id, False]),
            ('quantity', '>', 0),
            ('product_id.tracking', '=', 'none'),
        ]
        if wh_stock:
            domain.append(('location_id', '=', wh_stock))
        else:
            domain.append(('location_id.usage', '=', 'internal'))
        quants = Quant.search(domain, limit=50)
        if not quants:
            return False, 0.0, False
        q = random.choice(quants)
        avail = max(0.0, (q.quantity or 0.0) - (q.reserved_quantity or 0.0))
        return q.product_id, avail, (q.location_id.id if q.location_id else False)
