# -*- coding: utf-8 -*-
from odoo import fields, models


class ResCompany(models.Model):
    _inherit = 'res.company'

    flf_use_draft_as_start = fields.Boolean(
        string='Use Draft as start event (else Ready)',
        help='If enabled, lead-time starts at Draft creation. If disabled, it starts when document becomes Ready (confirmed).',
        default=False,
    )

    # Synthetic data: weight for company volume (1=small, 2=medium, 3+=big)
    x_flf_synt_weight = fields.Integer(
        string='Synthetic Volume Weight',
        help='Relative weight used by synthetic data generator to create more or fewer orders per minute for this company.',
        default=1,
    )
