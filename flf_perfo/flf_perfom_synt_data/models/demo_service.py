# -*- coding: utf-8 -*-
from datetime import datetime, timedelta
import random
import logging
from odoo import api, fields, models
from .outgoing_helper import setup_outgoing

_logger = logging.getLogger(__name__)


class FlfPerfSyntData(models.AbstractModel):
    _name = 'flf.perf.synt.data'
    _description = 'Synthetic data service for FLF Performance (dev/demo)'

    # --- helpers ---
    @api.model
    def _allowed_companies(self):
        ids = self.env.context.get('allowed_company_ids') or self.env.user.company_ids.ids
        try:
            test_ids = self.env['res.company'].sudo().search([('name', 'ilike', 'FLF Test Co')]).ids
            if test_ids:
                ids = list({*(ids or []), *test_ids})
        except Exception:
            pass
        return ids or [self.env.company.id]

    @api.model
    def _today_range(self):
        today = fields.Date.context_today(self)
        start = fields.Datetime.to_datetime(f"{today} 00:00:00")
        end = start + timedelta(days=1)
        return today, start, end

    @api.model
    def _demo_origin(self):
        return f"DEMO {fields.Date.today()}"

    # --- public API (manual) ---
    @api.model
    def demo_daily_init(self, per_company_out=8, per_company_in=2, force=False):
        """Делегуємо створення сьогоднішніх пікингів у окремий модуль daily_init."""
        from .daily_init import run_daily_init
        res = run_daily_init(self.env, per_company_out=per_company_out, per_company_in=per_company_in, force=force)
        _logger.info("[flf_perf_synt] demo_daily_init -> %s", res)
        return res

    @api.model
    def demo_tick(self, max_updates=10):
        """Підтримка живості: делегуємо в minute engine.
        Якщо на сьогодні ще немає DEMO — спочатку створюємо seed.
        """
        # ensure seed exists
        self.demo_daily_init()
        # delegate updates to minute engine (print/done/risks)
        self.env['flf.perf.synt.minute'].sudo().minute_tick()
        return {'updated': True}

    @api.model
    def demo_backfill(self, days=30, daily_per_company=6):
        """Одноразове заповнення минулих періодів мінімальними пікингами."""
        ICP = self.env['ir.config_parameter'].sudo()
        daily_per_company = int(ICP.get_param('flf_perf_synt.daily_per_company', daily_per_company))
        companies = self.env['res.company'].sudo().browse(self._allowed_companies())
        Backfill = self.env['flf.perf.synt.backfill'].sudo()
        for d in range(days, 0, -1):
            day = fields.Date.today() - timedelta(days=d)
            Backfill._demo_for_date(day, companies, daily_per_company)
        return {'backfilled_days': days}

    

    # --- internals removed to backfill model ---

