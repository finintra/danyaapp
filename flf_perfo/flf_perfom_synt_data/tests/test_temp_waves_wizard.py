# -*- coding: utf-8 -*-
from odoo.tests.common import SavepointCase
from odoo.tests import tagged
from odoo import fields


@tagged('post_install', '-at_install')
class TestTempWavesWizard(SavepointCase):
    @classmethod
    def setUpClass(cls):
        super().setUpClass()
        cls.Wiz = cls.env['flf.perf.synt.wizard'].sudo()
        cls.Schedule = cls.env['flf.truck.schedule'].sudo()
        cls.Slot = cls.env['flf.truck.slot'].sudo()

    def test_create_and_delete_temp_waves(self):
        today = fields.Date.today()
        # ensure clean slate
        self.Schedule.search([('name', 'ilike', 'DEMO TEMP%'), ('date', '=', today)]).unlink()
        # create wizard and generate waves every 60 minutes
        wiz = self.Wiz.create({'temp_wave_interval': '60'})
        wiz.action_create_temp_waves()
        scheds = self.Schedule.search([('name', 'ilike', 'DEMO TEMP%'), ('date', '=', today)])
        self.assertTrue(scheds, "Temporary DEMO schedule should be created")
        # expect some slots
        total_slots = self.Slot.search_count([('schedule_id', 'in', scheds.ids)])
        self.assertGreater(total_slots, 0)
        # delete
        wiz2 = self.Wiz.create({})
        wiz2.action_delete_temp_waves()
        left = self.Schedule.search_count([('name', 'ilike', 'DEMO TEMP%'), ('date', '=', today)])
        self.assertEqual(left, 0, "Temporary DEMO schedules should be deleted")
