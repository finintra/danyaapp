# -*- coding: utf-8 -*-
from datetime import datetime, time, timedelta
import pytz
from odoo import api, fields, models


class StockPicking(models.Model):
    _inherit = 'stock.picking'

    x_flf_done_user_id = fields.Many2one(
        'res.users',
        string='Validated By (FLF)',
        readonly=True,
        help='Хто натиснув Validate (Done) для цього відвантаження/прийомки.'
    )

    x_flf_risk_today = fields.Boolean(
        string='At Risk Today (FLF)',
        compute='_compute_x_flf_risk_today',
        search='_search_x_flf_risk_today',
    )
    
    x_flf_print_ts = fields.Datetime(
        string='First Print Time (FLF)',
        copy=False,
        index=True,
    )
    x_flf_print_user_id = fields.Many2one(
        'res.users',
        string='Printed By (FLF)',
        copy=False,
    )
    x_flf_deadline_at = fields.Datetime(
        string='FLF Deadline At (UTC)',
        compute='_compute_x_flf_deadline_at',
        store=True,
        index=True,
    )
    x_flf_in_deadline = fields.Boolean(
        string='In Deadline (FLF)',
        compute='_compute_x_flf_in_deadline',
        store=True,
        index=True,
    )

    def button_validate(self):
        res = super().button_validate()
        for picking in self:
            if not picking.x_flf_done_user_id:
                # sudo щоб записати навіть якщо доступи обмежені
                picking.sudo().write({'x_flf_done_user_id': self.env.user.id})
        return res

    def write(self, vals):
        if 'printed' in vals and vals.get('printed'):
            to_mark = self.filtered(lambda p: not getattr(p, 'printed', False) and not p.x_flf_print_ts)
            res = super().write(vals)
            if to_mark:
                now = fields.Datetime.now()
                user_id = self.env.user.id
                try:
                    to_mark.sudo().write({'x_flf_print_ts': now, 'x_flf_print_user_id': user_id})
                except Exception:
                    to_mark.sudo().write({'x_flf_print_ts': now})
            return res
        return super().write(vals)

    # Helpers
    def _tz(self):
        tzname = self.env.user.tz or 'UTC'
        try:
            return pytz.timezone(tzname)
        except Exception:
            return pytz.UTC

    def _localize(self, dt):
        if not dt:
            return None
        tz = self._tz()
        # dt is naive UTC in Odoo; localize to UTC then convert to user TZ
        if dt.tzinfo is None:
            dt = pytz.UTC.localize(dt)
        return dt.astimezone(tz)

    @api.depends('partner_id.x_flf_deadline_hour', 'create_date')
    def _compute_x_flf_deadline_at(self):
        tz = self._tz()
        for rec in self:
            try:
                if not rec.partner_id or not rec.create_date:
                    rec.x_flf_deadline_at = False
                    continue
                hour = rec.partner_id.x_flf_deadline_hour or 17.0
                h = int(hour)
                m = int(round((hour - h) * 60))
                create_local = rec._localize(rec.create_date)
                if not create_local:
                    rec.x_flf_deadline_at = False
                    continue
                deadline_naive = datetime.combine(create_local.date(), time(h, m))
                try:
                    deadline_local = tz.localize(deadline_naive)
                except Exception:
                    deadline_local = pytz.UTC.localize(deadline_naive).astimezone(tz)
                deadline_utc_naive = deadline_local.astimezone(pytz.UTC).replace(tzinfo=None)
                rec.x_flf_deadline_at = deadline_utc_naive
            except Exception:
                rec.x_flf_deadline_at = False

    @api.depends('date_done', 'x_flf_deadline_at')
    def _compute_x_flf_in_deadline(self):
        for rec in self:
            dd = rec.date_done
            dl = rec.x_flf_deadline_at
            rec.x_flf_in_deadline = bool(dd and dl and dd <= dl)

    def _compute_x_flf_risk_today(self):
        tz = self._tz()
        now_utc = fields.Datetime.now()
        now_local = self._localize(now_utc)
        today_local = now_local.date()
        for rec in self:
            risk = False
            try:
                if rec.state == 'done' or rec.picking_type_id.code != 'outgoing' or not rec.partner_id:
                    rec.x_flf_risk_today = False
                    continue
                create_local = self._localize(rec.create_date)
                if not create_local or create_local.date() != today_local:
                    rec.x_flf_risk_today = False
                    continue
                hour = rec.partner_id.x_flf_deadline_hour or 17.0
                h = int(hour)
                m = int(round((hour - h) * 60))
                # localize deadline to user timezone to match aware now_local
                deadline_naive = datetime.combine(today_local, time(h, m))
                try:
                    deadline_local = tz.localize(deadline_naive)
                except Exception:
                    # fallback: treat as UTC then convert to tz
                    deadline_local = pytz.UTC.localize(deadline_naive).astimezone(tz)
                delta_min = (deadline_local - now_local).total_seconds() / 60.0
                risk = 0 <= delta_min <= 60
            except Exception:
                risk = False
            rec.x_flf_risk_today = risk

    def _search_x_flf_risk_today(self, operator, value):
        # Support only [('x_flf_risk_today', '=', True)]
        if operator not in ('=', '==') or not value:
            return [('id', '=', 0)]
        tz = self._tz()
        now_local = datetime.now(tz)
        today = now_local.date()
        # Local day bounds to UTC (make aware before conversion)
        start_local_naive = datetime.combine(today, time(0, 0))
        end_local_naive = start_local_naive + timedelta(days=1)
        try:
            start_local = tz.localize(start_local_naive)
            end_local = tz.localize(end_local_naive)
        except Exception:
            start_local = pytz.UTC.localize(start_local_naive).astimezone(tz)
            end_local = pytz.UTC.localize(end_local_naive).astimezone(tz)
        start_utc = start_local.astimezone(pytz.UTC).replace(tzinfo=None)
        end_utc = end_local.astimezone(pytz.UTC).replace(tzinfo=None)

        domain = [
            ('state', '!=', 'done'),
            ('picking_type_id.code', '=', 'outgoing'),
            ('create_date', '>=', start_utc),
            ('create_date', '<', end_utc),
        ]
        candidates = self.search(domain)
        risk_ids = []
        for rec in candidates:
            try:
                hour = rec.partner_id.x_flf_deadline_hour or 17.0
                h = int(hour)
                m = int(round((hour - h) * 60))
                create_local = self._localize(rec.create_date)
                if not create_local:
                    continue
                deadline_naive = datetime.combine(create_local.date(), time(h, m))
                try:
                    deadline_local = tz.localize(deadline_naive)
                except Exception:
                    deadline_local = pytz.UTC.localize(deadline_naive).astimezone(tz)
                delta_min = (deadline_local - now_local).total_seconds() / 60.0
                if 0 <= delta_min <= 60:
                    risk_ids.append(rec.id)
            except Exception:
                continue
        return [('id', 'in', risk_ids)]
