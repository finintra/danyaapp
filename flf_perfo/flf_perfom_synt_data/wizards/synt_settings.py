# -*- coding: utf-8 -*-
from odoo import api, fields, models


class FlfPerfSyntSettings(models.TransientModel):
    _inherit = 'res.config.settings'

    # Demo generation
    flf_per_company_out = fields.Integer(string='Demo: Out pickings per company', default=8)
    flf_per_company_in = fields.Integer(string='Demo: In pickings per company', default=2)
    flf_daily_per_company = fields.Integer(string='Backfill: daily per company', default=6)
    flf_keep_days = fields.Integer(string='Cleanup: keep days', default=45)

    # Slot waves
    flf_threshold_min = fields.Integer(string='Waves: threshold min', default=5)
    flf_miss_ratio = fields.Float(string='Waves: miss ratio', default=0.2)
    flf_ship_ratio = fields.Float(string='Waves: ship ratio', default=0.6)
    flf_sample_limit = fields.Integer(string='Waves: sample limit', default=80)

    # Minute engine
    flf_minute_new_per_company = fields.Integer(string='Minute: new OUT per company', default=2)
    flf_minute_print_ratio = fields.Float(string='Minute: print ratio', default=0.35)
    flf_minute_done_ratio = fields.Float(string='Minute: done ratio', default=0.25)

    def get_values(self):
        res = super().get_values()
        ICP = self.env['ir.config_parameter'].sudo()
        def _g(key, cast, dflt):
            v = ICP.get_param(key, default=None)
            return cast(v) if v is not None else dflt
        res.update(
            flf_per_company_out=_g('flf_perf_synt.per_company_out', int, 8),
            flf_per_company_in=_g('flf_perf_synt.per_company_in', int, 2),
            flf_daily_per_company=_g('flf_perf_synt.daily_per_company', int, 6),
            flf_keep_days=_g('flf_perf_synt.keep_days', int, 45),
            flf_threshold_min=_g('flf_perf_synt.threshold_min', int, 5),
            flf_miss_ratio=_g('flf_perf_synt.miss_ratio', float, 0.2),
            flf_ship_ratio=_g('flf_perf_synt.ship_ratio', float, 0.6),
            flf_sample_limit=_g('flf_perf_synt.sample_limit', int, 80),
            flf_minute_new_per_company=_g('flf_perf_synt.minute_new_per_company', int, 2),
            flf_minute_print_ratio=_g('flf_perf_synt.minute_print_ratio', float, 0.35),
            flf_minute_done_ratio=_g('flf_perf_synt.minute_done_ratio', float, 0.25),
        )
        return res

    def set_values(self):
        super().set_values()
        ICP = self.env['ir.config_parameter'].sudo()
        ICP.set_param('flf_perf_synt.per_company_out', int(self.flf_per_company_out or 8))
        ICP.set_param('flf_perf_synt.per_company_in', int(self.flf_per_company_in or 2))
        ICP.set_param('flf_perf_synt.daily_per_company', int(self.flf_daily_per_company or 6))
        ICP.set_param('flf_perf_synt.keep_days', int(self.flf_keep_days or 45))
        ICP.set_param('flf_perf_synt.threshold_min', int(self.flf_threshold_min or 5))
        ICP.set_param('flf_perf_synt.miss_ratio', float(self.flf_miss_ratio or 0.2))
        ICP.set_param('flf_perf_synt.ship_ratio', float(self.flf_ship_ratio or 0.6))
        ICP.set_param('flf_perf_synt.sample_limit', int(self.flf_sample_limit or 80))
        ICP.set_param('flf_perf_synt.minute_new_per_company', int(self.flf_minute_new_per_company or 2))
        ICP.set_param('flf_perf_synt.minute_print_ratio', float(self.flf_minute_print_ratio or 0.35))
        ICP.set_param('flf_perf_synt.minute_done_ratio', float(self.flf_minute_done_ratio or 0.25))

