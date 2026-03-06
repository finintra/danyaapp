# -*- coding: utf-8 -*-
from datetime import timedelta
from odoo import api, fields, models


class FlfPerfSyntWizard(models.TransientModel):
    _name = 'flf.perf.synt.wizard'
    _description = 'FLF Synthetic Data Dev Tools'

    info = fields.Char(readonly=True, default='Run demo data utilities')
    temp_wave_interval = fields.Selection(
        selection=[('30', 'Every 30 minutes'), ('60', 'Every 60 minutes'), ('120', 'Every 120 minutes'), ('180', 'Every 180 minutes')],
        default='60',
        string='Temporary Waves Frequency'
    )

    def _reload_action(self):
        return {"type": "ir.actions.client", "tag": "reload"}

    @api.model
    def _svc(self):
        return self.env['flf.perf.synt.data'].sudo()

    @api.model
    def _slot(self):
        return self.env['flf.perf.synt.slot'].sudo()

    def action_generate_today(self):
        self._svc().demo_daily_init(force=True)
        return self._reload_action()

    def action_tick_now(self):
        self._svc().demo_tick()
        return self._reload_action()

    def action_backfill_30(self):
        self._svc().demo_backfill(days=30, daily_per_company=6)
        return self._reload_action()

    def action_cleanup_45(self):
        self._svc().demo_cleanup(keep_days=45)
        return self._reload_action()

    def action_slot_waves(self):
        self._slot().run_slot_waves()
        return self._reload_action()

    def action_delete_all_demo(self):
        self.env['flf.perf.synt.cleaner'].sudo().delete_all_demo()
        return self._reload_action()

    def action_create_temp_waves(self):
        Schedule = self.env['flf.truck.schedule'].sudo()
        Slot = self.env['flf.truck.slot'].sudo()
        today = fields.Date.today()
        now = fields.Datetime.now()
        # delete previous DEMO TEMP for today to avoid duplicates of names
        old = Schedule.search([('name', 'ilike', 'DEMO TEMP%'), ('date', '=', today)])
        if old:
            old.unlink()
        sched = Schedule.create({
            'name': f'DEMO TEMP Waves {today} {now.strftime("%H:%M")}',
            'date': today,
            'active': True,
        })
        interval_min = int(self.temp_wave_interval or '60')
        duration_hours = 4
        end_at = now + timedelta(hours=duration_hours)
        cur = now
        while cur <= end_at:
            Slot.create({
                'schedule_id': sched.id,
                'departure_time': f"{cur.hour:02d}:{cur.minute:02d}",
                'active': True,
            })
            cur += timedelta(minutes=interval_min)
        return self._reload_action()

    def action_delete_temp_waves(self):
        Schedule = self.env['flf.truck.schedule'].sudo()
        today = fields.Date.today()
        recs = Schedule.search([('name', 'ilike', 'DEMO TEMP%'), ('date', '=', today)])
        if recs:
            recs.unlink()
        return self._reload_action()
