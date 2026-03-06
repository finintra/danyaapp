# -*- coding: utf-8 -*-
from odoo import fields, models


class ResUsers(models.Model):
    _inherit = 'res.users'

    x_flf_primary_partner_id = fields.Many2one(
        'res.partner',
        string='FLF Primary Partner',
        help='Основний партнер користувача для акценту в персональній панелі.',
    )
