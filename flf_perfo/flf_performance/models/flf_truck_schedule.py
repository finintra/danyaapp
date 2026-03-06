# -*- coding: utf-8 -*-
from odoo import fields, models


class FlfTruckSchedule(models.Model):
    _name = 'flf.truck.schedule'
    _description = 'FLF Truck Schedule'

    name = fields.Char(required=True, default='Truck Schedule')
    weekday = fields.Selection([
        ('mon', 'Monday'), ('tue', 'Tuesday'), ('wed', 'Wednesday'),
        ('thu', 'Thursday'), ('fri', 'Friday'), ('sat', 'Saturday'), ('sun', 'Sunday')
    ], help='Базовий день тижня цього правила.', index=True)
    date = fields.Date(
        help='Опціональний оверрайд на конкретну дату. Має пріоритет над weekday.'
    )
    active = fields.Boolean(default=True)
    note = fields.Text()
    slot_ids = fields.One2many('flf.truck.slot', 'schedule_id', string='Slots')
