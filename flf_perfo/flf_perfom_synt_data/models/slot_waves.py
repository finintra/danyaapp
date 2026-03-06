# -*- coding: utf-8 -*-
from datetime import datetime, timedelta
import random
import logging
from odoo import api, fields, models

_logger = logging.getLogger(__name__)


class FlfPerfSyntSlot(models.AbstractModel):
    _name = 'flf.perf.synt.slot'
    _description = 'Synthetic slot waves for FLF Performance (dev/demo)'

    # helpers
    @api.model
    def _allowed_companies(self):
        ids = self.env.context.get('allowed_company_ids') or self.env.user.company_ids.ids
        try:
            if (self.env.user.id == 1) and (not ids or len(ids) <= 1):
                ids = self.env['res.company'].sudo().search([('name', 'ilike', 'FLF Test Co')]).ids or ids
        except Exception:
            pass
        return ids or [self.env.company.id]

    @api.model
    def _today_range(self):
        today = fields.Date.today()
        start = fields.Datetime.to_datetime(f"{today} 00:00:00")
        end = start + timedelta(days=1)
        return today, start, end

    @api.model
    def _demo_origin(self):
        return f"DEMO {fields.Date.today()}"

    # public API
    @api.model
    def run_slot_waves(self, threshold_min=5, miss_ratio=0.2, ship_ratio=0.6, sample_limit=80):
        ICP = self.env['ir.config_parameter'].sudo()
        threshold_min = int(ICP.get_param('flf_perf_synt.threshold_min', threshold_min))
        miss_ratio = float(ICP.get_param('flf_perf_synt.miss_ratio', miss_ratio))
        ship_ratio = float(ICP.get_param('flf_perf_synt.ship_ratio', ship_ratio))
        sample_limit = int(ICP.get_param('flf_perf_synt.sample_limit', sample_limit))

        Picking = self.env['stock.picking'].sudo()
        Schedule = self.env['flf.truck.schedule'].sudo()
        Demo = self.env['flf.perf.synt.data'].sudo()

        origin = self._demo_origin()
        today, start_dt, end_dt = self._today_range()
        # ensure seed exists for today (handles late server start)
        if not Picking.search_count([('origin', '=', origin), ('create_date', '>=', start_dt), ('create_date', '<', end_dt)]):
            Demo.demo_daily_init()

        # find today's active schedules & slots
        wd_map = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun']
        wd_code = wd_map[fields.Date.today().weekday()]
        scheds = Schedule.search(['&', ('active', '=', True), '|', ('date', '=', today), '&', ('date', '=', False), ('weekday', '=', wd_code)])
        now = fields.Datetime.now()
        waves = 0
        for s in scheds:
            for slot in s.slot_ids.filtered(lambda r: r.active and r.departure_time):
                # parse HH:MM
                try:
                    hh, mm = [int(x) for x in slot.departure_time.split(':', 1)]
                except Exception:
                    continue
                slot_dt = fields.Datetime.to_datetime(f"{today} {hh:02d}:{mm:02d}:00")
                diff_min = abs((now - slot_dt).total_seconds()) / 60.0
                if diff_min > threshold_min:
                    continue
                waves += 1
                # select today's demo pickings (not done)
                dom = [
                    ('origin', '=', origin), ('create_date', '>=', start_dt), ('create_date', '<', end_dt),
                    ('state', '!=', 'done')
                ]
                pool = Picking.search(dom, limit=sample_limit)
                if not pool:
                    continue

                n = len(pool)
                miss_n = max(1, int(n * miss_ratio))
                ship_n = max(1, int(n * ship_ratio))
                chosen = random.sample(pool, min(n, miss_n + ship_n))
                miss = chosen[:miss_n]
                ship = chosen[miss_n:miss_n + ship_n]

                # missed: tighten deadline, mark risk
                for p in miss:
                    vals = {}
                    if hasattr(p, 'x_flf_deadline_at'):
                        vals['x_flf_deadline_at'] = now - timedelta(minutes=random.randint(5, 45))
                    if hasattr(p, 'x_flf_risk_today'):
                        vals['x_flf_risk_today'] = True
                    if hasattr(p, 'x_flf_print_ts') and not p.x_flf_print_ts:
                        try:
                            if p.state == 'draft' and not getattr(p.partner_id, 'x_flf_use_draft_trigger', False):
                                p.action_confirm(); p.action_assign()
                        except Exception:
                            pass
                        if p.state == 'assigned':
                            vals['x_flf_print_ts'] = now - timedelta(minutes=5)
                    if vals:
                        p.sudo().write(vals)

                for p in ship:
                    try:
                        if p.state == 'draft' and not getattr(p.partner_id, 'x_flf_use_draft_trigger', False):
                            p.action_confirm(); p.action_assign()
                    except Exception:
                        pass
                    if p.state != 'assigned':
                        continue
                    vals = {}
                    if hasattr(p, 'x_flf_deadline_at'):
                        vals['x_flf_deadline_at'] = now + timedelta(minutes=random.randint(60, 180))
                    if hasattr(p, 'x_flf_risk_today'):
                        vals['x_flf_risk_today'] = False
                    if hasattr(p, 'x_flf_print_ts') and not p.x_flf_print_ts:
                        vals['x_flf_print_ts'] = now - timedelta(minutes=10)
                    if vals:
                        p.sudo().write(vals)
                    # ensure move lines done and validate
                    try:
                        for mv in p.move_ids_without_package:
                            if mv.move_line_ids:
                                for ml in mv.move_line_ids:
                                    if (ml.qty_done or 0.0) <= 0.0:
                                        ml.qty_done = mv.product_uom_qty
                            else:
                                self.env['stock.move.line'].sudo().create({
                                    'move_id': mv.id,
                                    'picking_id': p.id,
                                    'product_id': mv.product_id.id,
                                    'product_uom_id': mv.product_uom.id,
                                    'qty_done': mv.product_uom_qty,
                                    'location_id': p.location_id.id,
                                    'location_dest_id': p.location_dest_id.id,
                                    'company_id': p.company_id.id,
                                })
                        p.button_validate()
                        # attribute to any responsible user for partner or current user
                        users = getattr(p.partner_id, 'x_flf_responsible_user_ids', False) or self.env['res.users']
                        actor = users and users[:1] or self.env.user
                        p.sudo().write({'date_done': fields.Datetime.now(), 'x_flf_done_user_id': actor.id})
                    except Exception:
                        continue
        _logger.info("[flf_perf_synt] slot waves executed: %s", waves)
        return {'waves': waves}
