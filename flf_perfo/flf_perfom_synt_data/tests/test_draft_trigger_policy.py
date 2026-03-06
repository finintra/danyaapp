# -*- coding: utf-8 -*-
from odoo.tests.common import TransactionCase
from odoo import fields


class TestDraftTriggerPolicy(TransactionCase):
    def setUp(self):
        super().setUp()
        self.Demo = self.env['flf.perf.synt.data'].sudo()
        self.Picking = self.env['stock.picking'].sudo()
        self.Partner = self.env['res.partner'].sudo()

    def test_draft_trigger_partners_not_assigned_on_create(self):
        today = fields.Date.today()
        origin = f"DEMO {today}"
        self.Demo.demo_daily_init(force=True)
        # partners with draft trigger
        draft_partners = self.Partner.search([('x_flf_use_draft_trigger', '=', True)])
        self.assertTrue(draft_partners, 'No partners with draft trigger in seed')
        pics = self.Picking.search([
            ('origin', '=', origin),
            ('picking_type_id.code', '=', 'outgoing'),
            ('partner_id', 'in', draft_partners.ids),
        ], limit=50)
        # none should be auto-assigned just because of printing policy
        self.assertTrue(pics, 'No pickings created for draft-trigger partners')
        self.assertFalse(any(p.state == 'assigned' for p in pics), 'Draft-trigger pickings should not auto-assign on create')
