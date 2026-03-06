# -*- coding: utf-8 -*-
from odoo import fields, models


class ResConfigSettings(models.TransientModel):
    _inherit = 'res.config.settings'

    # Effort consolidation thresholds
    flf_consolidation_x_percent = fields.Float(
        string='Consolidation X (%)',
        config_parameter='flf_performance.consolidation_x_percent',
        default=40.0,
        company_dependent=True,
    )
    flf_consolidation_y_percent = fields.Float(
        string='Consolidation Y (%)',
        config_parameter='flf_performance.consolidation_y_percent',
        default=30.0,
        company_dependent=True,
    )
    flf_consolidation_window_days = fields.Integer(
        string='Consolidation Window (days)',
        config_parameter='flf_performance.consolidation_window_days',
        default=14,
        company_dependent=True,
    )

    # Flexible Saturday thresholds
    flf_sat_backlog_orders_11 = fields.Integer(
        string='Fri backlog orders → start 11:00',
        config_parameter='flf_performance.sat_backlog_orders_11',
        default=20,
        company_dependent=True,
    )
    flf_sat_backlog_orders_10 = fields.Integer(
        string='Fri backlog orders → start 10:00',
        config_parameter='flf_performance.sat_backlog_orders_10',
        default=40,
        company_dependent=True,
    )
    flf_sat_backlog_orders_09 = fields.Integer(
        string='Fri backlog orders → start 09:00',
        config_parameter='flf_performance.sat_backlog_orders_09',
        default=80,
        company_dependent=True,
    )
    flf_sat_backlog_lines_11 = fields.Integer(
        string='Fri backlog lines → start 11:00',
        config_parameter='flf_performance.sat_backlog_lines_11',
        default=400,
        company_dependent=True,
    )
    flf_sat_backlog_lines_10 = fields.Integer(
        string='Fri backlog lines → start 10:00',
        config_parameter='flf_performance.sat_backlog_lines_10',
        default=800,
        company_dependent=True,
    )
    flf_sat_backlog_lines_09 = fields.Integer(
        string='Fri backlog lines → start 09:00',
        config_parameter='flf_performance.sat_backlog_lines_09',
        default=1500,
        company_dependent=True,
    )
    flf_sat_created_today_by_10 = fields.Integer(
        string='Sat created by 10:00 (surge)',
        config_parameter='flf_performance.sat_created_today_by_10',
        default=50,
        company_dependent=True,
    )

    # Refresh / Off-day
    flf_refresh_interval_sec = fields.Integer(
        string='Refresh interval (sec)',
        config_parameter='flf_performance.refresh_interval_sec',
        default=120,
        company_dependent=True,
    )
    flf_refresh_offset_base = fields.Integer(
        string='Refresh offset base (sec)',
        config_parameter='flf_performance.refresh_offset_base',
        default=0,
        company_dependent=True,
    )
    flf_offday_shipments_enabled = fields.Boolean(
        string='Enable Off-day Shipments bonus',
        config_parameter='flf_performance.offday_shipments_enabled',
        default=True,
        company_dependent=True,
    )

    # Start event policy: Draft vs Ready (company-level)
    flf_use_draft_as_start = fields.Boolean(
        string='Use Draft as start event (else Ready)',
        help='If enabled, lead-time starts at Draft creation. If disabled, it starts when document becomes Ready (confirmed).',
        related='company_id.flf_use_draft_as_start',
        readonly=False,
    )

    # Synthetic data volume weight (company-level)
    flf_synt_weight = fields.Integer(
        string='Synthetic Volume Weight',
        help='Relative weight for synthetic data generator (1=small, 2=medium, 3+=big).',
        related='company_id.x_flf_synt_weight',
        readonly=False,
    )

    def set_values(self):
        res = super().set_values()
        try:
            companies = self.mapped('company_id')
            for co in companies:
                use_draft = bool(co.flf_use_draft_as_start)
                partners = self.env['res.partner'].sudo().search([('company_id', '=', co.id), ('is_company', '=', True)])
                if partners:
                    partners.write({'x_flf_use_draft_trigger': use_draft})
        except Exception:
            pass
        return res
