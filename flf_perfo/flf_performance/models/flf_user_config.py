# -*- coding: utf-8 -*-
from odoo import api, fields, models, _
from odoo.exceptions import ValidationError


class FlfUserConfig(models.Model):
    _name = 'flf.user_config'
    _description = 'FLF User Configuration'
    _inherit = ['mail.thread', 'mail.activity.mixin']

    name = fields.Char(string='Name', compute='_compute_name', store=False)
    company_id = fields.Many2one('res.company', string='Company', required=True, default=lambda self: self.env.company, index=True, tracking=True)
    user_id = fields.Many2one('res.users', string='User', required=True, index=True, tracking=True)
    primary_partner_id = fields.Many2one('res.partner', string='Primary Partner', tracking=True)

    _sql_constraints = [
        ('flf_user_config_unique_user_company', 'unique(user_id, company_id)', 'User config must be unique per company.'),
    ]

    @api.depends('user_id', 'company_id')
    def _compute_name(self):
        for rec in self:
            rec.name = f"{rec.user_id.display_name or ''} ({rec.company_id.display_name or ''})".strip()

    @api.constrains('user_id', 'company_id')
    def _check_user_company(self):
        for rec in self:
            if rec.user_id and rec.company_id and rec.company_id not in rec.user_id.company_ids:
                raise ValidationError(_("Selected user is not allowed in the chosen company."))
