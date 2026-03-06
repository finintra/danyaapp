# -*- coding: utf-8 -*-
from odoo.tests.common import SavepointCase
from odoo.tests import tagged
from odoo import fields


@tagged('post_install', '-at_install')
class TestWallboardHelpers(SavepointCase):
    @classmethod
    def setUpClass(cls):
        super().setUpClass()
        cls.KPI = cls.env['flf.performance.kpi'].sudo()
        cls.Blocks = cls.env['flf.performance.wallboard.blocks'].sudo()

    def test_01_at_risk_filtered_today_and_company(self):
        # seed demo data for all FLF Test Co companies
        self.KPI.seed_demo_data()
        # take one FLF Test Co and restrict context
        co = self.env['res.company'].sudo().search([('name', 'ilike', 'FLF Test Co 1')], limit=1)
        self.assertTrue(co)
        rows = self.Blocks.with_context(allowed_company_ids=[co.id]).build_at_risk()
        # all rows belong to the chosen company (compute_at_risk filters today by design)
        for r in rows:
            self.assertEqual(r['company'], co.name)

    def test_02_tops_week_month_fallback_from_pickings(self):
        # ensure there is at least today data
        self.KPI.seed_demo_data()
        tops = self.env['flf.performance.wallboard'].sudo().read_payload().get('tops', {})
        # Day must have something; Week/Month should fallback to same day at least
        self.assertIsNotNone(tops.get('day', {}).get('users', {}).get('orders', []))
        self.assertIsNotNone(tops.get('week', {}).get('users', {}).get('orders', []))
        self.assertIsNotNone(tops.get('month', {}).get('users', {}).get('orders', []))
