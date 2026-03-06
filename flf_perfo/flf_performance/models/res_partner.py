# -*- coding: utf-8 -*-
from odoo import api, fields, models


class ResPartner(models.Model):
    _inherit = 'res.partner'

    x_flf_deadline_hour = fields.Float(
        string='FLF Deadline Hour (local)',
        help='Локальний час дедлайну, години (наприклад 17.0 означає 17:00).',
        default=17.0,
    )
    x_flf_soft_window_minutes = fields.Integer(
        string='FLF Soft Window (min)',
        help='М’яке вікно після дедлайну, хвилини (наприклад 90 означає до 18:30).',
        compute='_compute_x_flf_soft_window_minutes',
        store=True,
    )
    x_flf_last_shipment_hour = fields.Float(
        string='FLF Last Shipment Hour',
        help='Остання «машина» (години, наприклад 19.0). Може бути перекрито глобальним розкладом.',
        default=19.0,
    )
    x_flf_afterhours_credit = fields.Boolean(
        string='FLF After-hours Credit',
        help='Кредитувати «передачу зміни» як краще, ніж повну прострочку.',
        default=True,
    )
    x_flf_use_draft_trigger = fields.Boolean(
        string='FLF Draft Triggers Work',
        help='Якщо увімкнено — для цього партнера «Draft» вже сигналізує, що можна збирати.',
        default=False,
    )
    x_flf_big_order_line_count = fields.Integer(
        string='FLF Big Order: Lines',
        default=50,
    )
    x_flf_big_order_qty = fields.Integer(
        string='FLF Big Order: Qty',
        default=150,
    )
    x_flf_responsible_user_ids = fields.Many2many(
        'res.users',
        'flf_partner_responsible_rel',
        'partner_id', 'user_id',
        string='FLF Responsible Users',
        help='Співробітники, відповідальні за цього партнера (для відображення метрик/ризиків).',
    )

    x_flf_is_res_company_partner = fields.Boolean(
        string='FLF Is Res Company Partner',
        compute='_compute_x_flf_is_res_company_partner',
        search='_search_x_flf_is_res_company_partner',
    )

    # Inbound SLA: max days between receipt and validation
    x_flf_inbound_max_days = fields.Integer(
        string='FLF Inbound Max Days',
        help='Максимальна кількість діб між надходженням (створенням) та затвердженням прийомки (Done).',
        default=2,
    )

    @api.depends('x_flf_last_shipment_hour', 'x_flf_deadline_hour')
    def _compute_x_flf_soft_window_minutes(self):
        for rec in self:
            last_h = rec.x_flf_last_shipment_hour or 0.0
            dl_h = rec.x_flf_deadline_hour or 0.0
            minutes = int(round(max(0.0, (last_h - dl_h) * 60.0)))
            rec.x_flf_soft_window_minutes = minutes

    def _compute_x_flf_is_res_company_partner(self):
        ids = set(self.env['res.company'].sudo().search([]).mapped('partner_id').ids)
        for rec in self:
            rec.x_flf_is_res_company_partner = rec.id in ids

    def _search_x_flf_is_res_company_partner(self, operator, value):
        ids = self.env['res.company'].sudo().search([]).mapped('partner_id').ids
        if operator in ('=', '=='):
            return [('id', 'in', ids if value else [])] if value else [('id', 'not in', ids)]
        return [('id', '=', 0)]
