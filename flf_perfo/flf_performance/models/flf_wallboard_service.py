# -*- coding: utf-8 -*-
from datetime import timedelta
from odoo import api, fields, models
import pytz
from datetime import datetime, time
from . import wallboard_helpers as wh


class FlfWallboardService(models.AbstractModel):
    _name = 'flf.performance.wallboard'
    _description = 'Wallboard payload builder (no UI switches)'

    @api.model
    def _allowed_companies(self):
        return self.env.context.get('allowed_company_ids') or self.env.user.company_ids.ids or [self.env.company.id]

    @api.model
    def _today_range(self):
        # Обчислюємо межі «сьогодні» у TZ користувача і конвертуємо в UTC (naive)
        today = fields.Date.context_today(self)
        tzname = self.env.user.tz or 'UTC'
        try:
            tz = pytz.timezone(tzname)
        except Exception:
            tz = pytz.UTC
        start_local_naive = datetime.combine(today, time(0, 0))
        try:
            start_local = tz.localize(start_local_naive)
        except Exception:
            start_local = pytz.UTC.localize(start_local_naive).astimezone(tz)
        end_local = start_local + timedelta(days=1)
        start_utc_naive = start_local.astimezone(pytz.UTC).replace(tzinfo=None)
        end_utc_naive = end_local.astimezone(pytz.UTC).replace(tzinfo=None)
        return today, start_utc_naive, end_utc_naive

    @api.model
    def read_payload(self):
        today, start_dt, end_dt = self._today_range()
        company_ids = self._allowed_companies()
        blocks = self.env['flf.performance.wallboard.blocks']
        ICP = self.env['ir.config_parameter'].sudo()
        interval_sec = int(ICP.get_param('flf_performance.refresh_interval_sec', 30))
        offset_base = int(ICP.get_param('flf_performance.refresh_offset_base', 0))
        # Build blocks
        summary = blocks.build_summary(today=today, company_ids=company_ids)
        partners = blocks.build_partners(start_dt, end_dt, company_ids=company_ids)
        at_risk = blocks.build_at_risk(company_ids=company_ids)
        # TOPs via helper (robust); UI має ще й JS‑фолбек на partners
        tops = wh.compute_tops(self.env, today, company_ids)
        return {
            'summary': summary,
            'partners': partners,
            'at_risk': at_risk,
            'tops': tops or {},
            'generated_at': fields.Datetime.now(),
            'refresh': {'interval_sec': interval_sec, 'offset_base': offset_base},
        }
