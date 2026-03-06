# -*- coding: utf-8 -*-
from collections import defaultdict
from datetime import timedelta
from odoo import api, fields, models
from . import wallboard_helpers as wh
from . import wallboard_partners as wp


class FlfWallboardBlocks(models.AbstractModel):
    _name = 'flf.performance.wallboard.blocks'
    _description = 'Wallboard blocks & helpers'

    # --- helpers ---
    @api.model
    def _allowed_companies(self):
        ids = self.env.context.get('allowed_company_ids') or self.env.user.company_ids.ids
        return ids or [self.env.company.id]

    @api.model
    def _today_range(self):
        today = fields.Date.context_today(self)
        start = fields.Datetime.to_datetime(f"{today} 00:00:00")
        end = start + timedelta(days=1)
        return today, start, end

    @api.model
    def _wavg(self, cur_avg, cur_n, add_avg, add_n):
        tot = (cur_avg * cur_n) + (add_avg * add_n)
        n = cur_n + add_n
        return (tot / n) if n else 0.0

    # --- blocks ---
    @api.model
    def build_summary(self, today=None, company_ids=None):
        if not today:
            today = fields.Date.context_today(self)
        company_ids = company_ids or self._allowed_companies()
        return wh.compute_summary(self.env, today, company_ids)

    @api.model
    def build_partners(self, start_dt, end_dt, company_ids=None):
        company_ids = company_ids or self._allowed_companies()
        return wp.compute_partners(self.env, start_dt, end_dt, company_ids)

    @api.model
    def build_at_risk(self, company_ids=None):
        company_ids = company_ids or self._allowed_companies()
        return wh.compute_at_risk(self.env, company_ids)

    
