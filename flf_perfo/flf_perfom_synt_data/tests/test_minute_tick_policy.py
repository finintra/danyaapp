# -*- coding: utf-8 -*-
from odoo.tests.common import SavepointCase
from odoo.tests import tagged
from odoo import fields


@tagged('post_install', '-at_install')
class TestMinuteTickPolicy(SavepointCase):
    @classmethod
    def setUpClass(cls):
        super().setUpClass()
        cls.Synt = cls.env['flf.perf.synt.data'].sudo()
        cls.Min = cls.env['flf.perf.synt.minute'].sudo()
        cls.ICP = cls.env['ir.config_parameter'].sudo()
        cls.Picking = cls.env['stock.picking'].sudo()

    def test_print_only_ready_and_done_only_assigned(self):
        self.ICP.set_param('flf_perf_synt.minute_print_ratio', 1.0)
        self.ICP.set_param('flf_perf_synt.minute_done_ratio', 1.0)
        res = self.Synt.demo_daily_init(force=True)
        origin = res['origin']
        self.Min.minute_tick()
        picks = self.Picking.search([('origin', '=', origin), ('picking_type_id.code', '=', 'outgoing')])
        printed = picks.filtered(lambda p: getattr(p, 'x_flf_print_ts', False))
        for p in printed:
            self.assertEqual(p.state, 'assigned')
        done = picks.filtered(lambda p: p.state == 'done')
        for p in done:
            self.assertEqual(p.state, 'done')
