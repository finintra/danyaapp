# -*- coding: utf-8 -*-
from odoo import api, fields, models


class FlfTruckSlot(models.Model):
    _name = 'flf.truck.slot'
    _description = 'FLF Truck Slot'

    name = fields.Char(string='Name', compute='_compute_name', store=True)
    schedule_id = fields.Many2one('flf.truck.schedule', required=True, ondelete='cascade')
    departure_time = fields.Char(
        string='Departure Time (HH:MM)',
        help='Час відправлення у форматі HH:MM, локальний час.'
    )
    is_weekend = fields.Boolean(default=False)
    sequence = fields.Integer(default=10)
    active = fields.Boolean(default=True)

    @api.depends('departure_time')
    def _compute_name(self):
        for rec in self:
            rec.name = rec.departure_time or 'Slot'
