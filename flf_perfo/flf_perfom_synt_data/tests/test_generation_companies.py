# -*- coding: utf-8 -*-
from odoo.tests.common import TransactionCase
from odoo import fields


class TestGenerationCompanies(TransactionCase):
    def setUp(self):
        super().setUp()
        self.Demo = self.env['flf.perf.synt.data'].sudo()
        self.Picking = self.env['stock.picking'].sudo()
        self.Company = self.env['res.company'].sudo()

    def test_daily_init_creates_for_all_test_companies(self):
        today = fields.Date.today()
        origin = f"DEMO {today}"
        self.Demo.demo_daily_init(force=True)
        test_companies = self.Company.search([('name', 'ilike', 'FLF Test Co')])
        self.assertTrue(test_companies, 'No FLF Test Co companies found')
        for c in test_companies:
            cnt = self.Picking.search_count([
                ('company_id', '=', c.id),
                ('origin', '=', origin),
                ('picking_type_id.code', '=', 'outgoing'),
            ])
            self.assertGreater(cnt, 0, f'No outgoings created for company {c.name}')
