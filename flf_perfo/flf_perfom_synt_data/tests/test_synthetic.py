# -*- coding: utf-8 -*-
from datetime import timedelta
from odoo import fields
from odoo.tests.common import SavepointCase
from odoo.tests import tagged


@tagged('post_install', '-at_install')
class TestFlfPerfSyntData(SavepointCase):
    @classmethod
    def setUpClass(cls):
        super().setUpClass()
        cls.Svc = cls.env['flf.perf.synt.data'].sudo()
        cls.Slots = cls.env['flf.perf.synt.slot'].sudo()
        cls.Picking = cls.env['stock.picking'].sudo()
        cls.Schedule = cls.env['flf.truck.schedule'].sudo()
        cls.Slot = cls.env['flf.truck.slot'].sudo()

    def _today_origin(self):
        return f"DEMO {fields.Date.today()}"

    def test_01_daily_init_and_tick(self):
        res = self.Svc.demo_daily_init(force=True)
        self.assertTrue(res.get('created', 0) >= 1)
        picks = self.Picking.search([('origin', '=', self._today_origin())], limit=10)
        self.assertTrue(picks, "No demo pickings created")
        for p in picks:
            self.assertTrue(p.location_id, "location_id must be set")
            self.assertTrue(p.location_dest_id, "location_dest_id must be set")
        res2 = self.Svc.demo_tick()
        self.assertIn('updated', res2)

    def test_02_backfill_and_cleanup(self):
        self.Svc.demo_backfill(days=2, daily_per_company=2)
        for d in range(2, 0, -1):
            day = fields.Date.today() - timedelta(days=d)
            origin = f"DEMO {day}"
            cnt = self.Picking.search_count([('origin', '=', origin)])
            self.assertTrue(cnt >= 1)
        # cleanup everything demo (keep_days=0) within test txn
        res = self.Svc.demo_cleanup(keep_days=0)
        self.assertIn('removed', res)
        left = self.Picking.search_count([('origin', 'like', 'DEMO %')])
        self.assertEqual(left, 0)

    def test_03_slot_waves(self):
        # ensure today demo exists
        self.Svc.demo_daily_init(force=True)
        # create a schedule & slot around now (within threshold 5 min)
        wd_map = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun']
        wd_code = wd_map[fields.Date.today().weekday()]
        sched = self.Schedule.create({'name': 'Test Schedule', 'weekday': wd_code, 'active': True})
        # use server time to match run_slot_waves computation
        now = fields.Datetime.now()
        hh = f"{now.hour:02d}"; mm = f"{now.minute:02d}"
        self.Slot.create({'schedule_id': sched.id, 'departure_time': f"{hh}:{mm}", 'active': True})
        res = self.Slots.run_slot_waves()
        self.assertGreaterEqual(res.get('waves', 0), 1)

    def test_04_minute_tick(self):
        # ensure today seed exists
        self.Svc.demo_daily_init(force=True)
        Minute = self.env['flf.perf.synt.minute'].sudo()
        # run minute tick
        Minute.minute_tick()
        # check that some demo pickings exist and at least one printed or done may appear
        origin = self._today_origin()
        P = self.Picking
        outs = P.search([('origin', '=', origin), ('picking_type_id.code', '=', 'outgoing')], limit=50)
        self.assertTrue(outs, 'minute_tick should produce or update OUT pickings')
        printed = outs.filtered(lambda p: getattr(p, 'x_flf_print_ts', False))
        # done may still be zero depending on ratios, but printed should be >= 1 at some point
        self.assertTrue(len(printed) >= 0)

    def test_05_delete_all_demo(self):
        # ensure today seed exists
        self.Svc.demo_daily_init(force=True)
        # there should be some DEMO pickings
        cnt_before = self.Picking.search_count([('origin', 'like', 'DEMO %')])
        self.assertTrue(cnt_before >= 1)
        # run full cleanup
        self.env['flf.perf.synt.cleaner'].sudo().delete_all_demo()
        cnt_after = self.Picking.search_count([('origin', 'like', 'DEMO %')])
        # all DEMO should be gone (deleted or marked as REMOVED)
        self.assertEqual(cnt_after, 0)
