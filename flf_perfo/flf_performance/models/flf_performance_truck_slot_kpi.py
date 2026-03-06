# -*- coding: utf-8 -*-
from odoo import fields, models


class FlfPerformanceTruckSlotKPI(models.Model):
    _name = 'flf.performance.truck_slot_kpi'
    _description = 'FLF Performance KPI by Truck Slot'

    date = fields.Date(index=True, required=True)
    slot_time = fields.Char(string='Slot Time (HH:MM)', required=True)
    company_id = fields.Many2one('res.company', required=True, default=lambda self: self.env.company, index=True)
    partner_id = fields.Many2one('res.partner', index=True)
    user_id = fields.Many2one('res.users', index=True)

    created_since_prev_slot = fields.Integer(default=0)
    shipped_in_slot = fields.Integer(default=0)
    missed_in_slot = fields.Integer(default=0)
    slot_fulfillment_ratio = fields.Float(default=0.0)
