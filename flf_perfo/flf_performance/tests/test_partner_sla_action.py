# -*- coding: utf-8 -*-
from odoo.tests.common import TransactionCase
from odoo.tools.safe_eval import safe_eval


class TestPartnerSlaAction(TransactionCase):
    def test_domain_res_company_only(self):
        action = self.env.ref('flf_performance.action_flf_partner_sla_registry')
        domain_str = action.domain or '[]'
        parsed = safe_eval(domain_str)
        self.assertIn(
            ('x_flf_is_res_company_partner', '=', True),
            parsed,
            msg='Action domain must restrict to res.company partners only.',
        )
