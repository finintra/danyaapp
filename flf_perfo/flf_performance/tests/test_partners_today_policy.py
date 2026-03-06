# -*- coding: utf-8 -*-
from odoo.tests.common import SavepointCase
from odoo.tests import tagged
from odoo import fields


@tagged('post_install', '-at_install')
class TestPartnersTodayPolicy(SavepointCase):
    @classmethod
    def setUpClass(cls):
        super().setUpClass()
        cls.KPI = cls.env['flf.performance.kpi'].sudo()
        cls.Blocks = cls.env['flf.performance.wallboard.blocks'].sudo()

    def test_partners_today_basic(self):
        # Seed ensures today data and demo partners/companies exist
        self.KPI.seed_demo_data()
        today = fields.Date.context_today(self.env['flf.performance.kpi'])
        start_dt = fields.Datetime.to_datetime(f"{today} 00:00:00")
        end_dt = start_dt + fields.Date.to_date('1970-01-02') - fields.Date.to_date('1970-01-01')  # +1 day
        rows = self.Blocks.build_partners(start_dt, start_dt + (end_dt - start_dt), company_ids=None)
        self.assertIsInstance(rows, list)
        # Expect keys present when rows exist
        if rows:
            r = rows[0]
            for k in ['company_name', 'unprinted', 'printed_not_picked', 'done', 'waiting_count', 'waiting_new_today']:
                self.assertIn(k, r)
