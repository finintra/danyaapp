# -*- coding: utf-8 -*-
from odoo import fields
import random


def setup_outgoing(env, picking, partner, company, type_rec):
    """Create a stock.move for outgoing picking and adjust state according to
    partner.x_flf_use_draft_trigger. Ensures a move line exists. Uses available
    quants; 10% cases force waiting (insufficient stock)."""
    U = env['flf.perf.synt.util'].sudo()
    prod, avail, src_loc = U.available_product(company)
    if not prod:
        return False
    ICP = env['ir.config_parameter'].sudo()
    waiting_ratio = float(ICP.get_param('flf_perf_synt.waiting_ratio', 0.10))
    force_waiting = (random.random() < waiting_ratio)
    if not force_waiting and (avail or 0) < 1:
        return False
    qty = 1.0
    if prod:
        if force_waiting:
            base = max(0.0, avail)
            qty = max(1.0, (base + random.choice([1.0, 2.0, 3.0])))
        else:
            qty = float(min(int(avail), random.choice([1, 1, 2, 3])) or 1)
    Move = env['stock.move'].sudo()
    uom_unit = env.ref('uom.product_uom_unit')
    if src_loc and getattr(picking.location_id, 'id', False) != src_loc:
        try:
            picking.sudo().write({'location_id': src_loc})
        except Exception:
            pass
    mv = Move.create({
        'name': f'OUT {prod.display_name if prod else "Widget"}',
        'picking_id': picking.id,
        'product_id': prod.id,
        'product_uom': uom_unit.id,
        'product_uom_qty': qty,
        'location_id': picking.location_id.id,
        'location_dest_id': picking.location_dest_id.id,
        'company_id': company.id,
    })
    # Ready policy
    if not getattr(partner, 'x_flf_use_draft_trigger', False):
        try:
            picking.action_confirm()
            picking.action_assign()
        except Exception:
            pass
    if not mv.move_line_ids:
        env['stock.move.line'].sudo().create({
            'move_id': mv.id,
            'picking_id': picking.id,
            'product_id': mv.product_id.id if mv.product_id else False,
            'product_uom_id': mv.product_uom.id,
            'qty_done': 0.0,
            'location_id': picking.location_id.id,
            'location_dest_id': picking.location_dest_id.id,
            'company_id': company.id,
        })
    return mv


def resolve_locations(env, type_rec, company):
    """Return (src_id, dst_id) for given picking type and company, with robust fallbacks."""
    src = type_rec.default_location_src_id.id if getattr(type_rec, 'default_location_src_id', False) else False
    dst = type_rec.default_location_dest_id.id if getattr(type_rec, 'default_location_dest_id', False) else False
    if src and dst:
        return src, dst
    Loc = env['stock.location'].sudo()
    Wh = env['stock.warehouse'].sudo().search([('company_id', '=', company.id)], limit=1)
    wh_stock = Wh.lot_stock_id.id if Wh and Wh.lot_stock_id else False
    code = getattr(type_rec, 'code', '')
    if code == 'outgoing':
        src = src or wh_stock or Loc.search([('usage', '=', 'internal'), ('company_id', 'in', [company.id, False])], limit=1, order='company_id desc').id
        dst = dst or Loc.search([('usage', '=', 'customer'), ('company_id', 'in', [company.id, False])], limit=1, order='company_id desc').id
    elif code == 'incoming':
        src = src or Loc.search([('usage', '=', 'supplier'), ('company_id', 'in', [company.id, False])], limit=1, order='company_id desc').id
        dst = dst or wh_stock or Loc.search([('usage', '=', 'internal'), ('company_id', 'in', [company.id, False])], limit=1, order='company_id desc').id
    return src, dst
