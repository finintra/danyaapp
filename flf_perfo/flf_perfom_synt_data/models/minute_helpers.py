# -*- coding: utf-8 -*-
import random


def pick_actor(env, partner, company):
    Users = partner.sudo().x_flf_responsible_user_ids
    if not Users:
        Users = env['res.users'].sudo().search([('company_ids', 'in', [company.id])], limit=5)
    return random.choice(Users) if Users else env.user


def force_validate(env, picking):
    res = picking.with_context(skip_immediate=True).button_validate()
    if isinstance(res, dict):
        model = res.get('res_model')
        if model == 'stock.immediate.transfer':
            wiz = env['stock.immediate.transfer'].create({'pick_ids': [(6, 0, [picking.id])]})
            wiz.process()
        elif model == 'stock.backorder.confirmation':
            wiz = env['stock.backorder.confirmation'].create({'pick_ids': [(6, 0, [picking.id])]})
            if hasattr(wiz, 'process_cancel'):
                wiz.process_cancel()
            else:
                wiz.process()
    return True
