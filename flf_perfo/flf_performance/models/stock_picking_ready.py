# -*- coding: utf-8 -*-
from odoo import api, fields, models


class StockPicking(models.Model):
    _inherit = 'stock.picking'

    x_flf_ready_ts = fields.Datetime(copy=False, index=True)

    def action_assign(self):
        res = super().action_assign()
        now = fields.Datetime.now()
        for p in self:
            if p.state == 'assigned' and not p.x_flf_ready_ts:
                try:
                    p.sudo().write({'x_flf_ready_ts': now})
                except Exception:
                    pass
        return res

    def write(self, vals):
        set_assigned = ('state' in vals and vals.get('state') == 'assigned')
        res = super().write(vals)
        if set_assigned:
            now = fields.Datetime.now()
            for p in self:
                if p.state == 'assigned' and not p.x_flf_ready_ts:
                    try:
                        p.sudo().write({'x_flf_ready_ts': now})
                    except Exception:
                        pass
        return res
