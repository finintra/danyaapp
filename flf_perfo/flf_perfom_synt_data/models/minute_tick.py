# -*- coding: utf-8 -*-
from datetime import timedelta
import random
from odoo import api, fields, models
from .minute_helpers import pick_actor, force_validate


class FlfPerfSyntMinute(models.AbstractModel):
    _name = 'flf.perf.synt.minute'
    _description = 'Synthetic minute-by-minute engine for FLF Performance'

    def _u(self):
        return self.env['flf.perf.synt.util'].sudo()


    @api.model
    def minute_tick(self):
        ICP = self.env['ir.config_parameter'].sudo()
        base_new = int(ICP.get_param('flf_perf_synt.minute_new_per_company', 2))
        print_ratio = float(ICP.get_param('flf_perf_synt.minute_print_ratio', 0.35))
        done_ratio = float(ICP.get_param('flf_perf_synt.minute_done_ratio', 0.25))

        Picking = self.env['stock.picking'].sudo()
        Move = self.env['stock.move'].sudo()
        MoveLine = self.env['stock.move.line'].sudo()
        Product = self.env['product.product'].sudo()
        uom_unit = self.env.ref('uom.product_uom_unit')

        U = self._u()
        origin = U.today_origin()
        now = fields.Datetime.now()
        companies = self.env['res.company'].sudo().browse(U.allowed_companies())

        Ops = self.env['flf.perf.synt.ops'].sudo()

        for c in companies:
            out_type, in_type = U.pick_types(c)
            if not out_type:
                continue
            weight = max(1, U.company_weight(c))

            # 1) NEW OUTGOINGS (делегуємо в окремий сервіс)
            n_new = max(1, base_new * weight)
            Ops.new_outgoings(c, out_type, origin, now, n_new)

            # 2) MARK PART AS PRINTED with actor attribution (today + small backlog)
            pool_today = Picking.search([
                ('company_id', '=', c.id), ('origin', '=', origin),
                ('picking_type_id.code', '=', 'outgoing'), ('state', '!=', 'done')
            ], limit=120)
            # include backlog from last 2 days (DEMO only, без сьогоднішнього origin)
            backlog = Picking.search([
                ('company_id', '=', c.id), ('origin', 'like', 'DEMO %'), ('origin', '!=', origin),
                ('picking_type_id.code', '=', 'outgoing'), ('state', '!=', 'done'),
                ('create_date', '>=', now - timedelta(days=2))
            ], limit=80)
            pool = (pool_today | backlog)
            unprinted = [p for p in pool if not getattr(p, 'x_flf_print_ts', False)]
            if unprinted:
                m_print = max(1, int(len(unprinted) * print_ratio))
                k_print = min(len(unprinted), m_print)
            else:
                k_print = 0
            for p in (random.sample(unprinted, k_print) if k_print > 0 else []):
                try:
                    if p.state == 'draft' and not getattr(p.partner_id, 'x_flf_use_draft_trigger', False):
                        p.action_confirm(); p.action_assign()
                    if p.state != 'assigned':
                        continue
                    actor = pick_actor(self.env, p.partner_id, c)
                    p.with_user(actor).sudo().write({'printed': True})
                except Exception:
                    pass

            # 3) COMPLETE SOME AS DONE with actor attribution (today + backlog), only if printed >= 3 min ago
            printed_today = Picking.search([
                ('company_id', '=', c.id), ('origin', '=', origin),
                ('picking_type_id.code', '=', 'outgoing'), ('state', '!=', 'done'),
                ('x_flf_print_ts', '!=', False)
            ], limit=200)
            printed_backlog = Picking.search([
                ('company_id', '=', c.id), ('origin', 'like', 'DEMO %'), ('origin', '!=', origin),
                ('picking_type_id.code', '=', 'outgoing'), ('state', '!=', 'done'),
                ('x_flf_print_ts', '!=', False), ('create_date', '>=', now - timedelta(days=2))
            ], limit=120)
            printed_pool_rs = printed_today | printed_backlog
            printed_pool = list(printed_pool_rs)
            # enforce minimal delay
            eligible = [p for p in printed_pool if getattr(p, 'x_flf_print_ts', False) and ((now - p.x_flf_print_ts).total_seconds() >= 180)]
            # обчислити розмір вибірки без перевищення популяції
            if eligible:
                m = max(1, int(len(eligible) * done_ratio))
                k = min(len(eligible), m)
            else:
                k = 0
            for p in (random.sample(eligible, k) if k > 0 else []):
                try:
                    if p.state != 'assigned':
                        continue
                    for mv in p.move_ids_without_package:
                        if mv.move_line_ids:
                            for ml in mv.move_line_ids:
                                if (ml.qty_done or 0.0) <= 0.0:
                                    ml.qty_done = mv.product_uom_qty
                        else:
                            MoveLine.create({'move_id': mv.id, 'picking_id': p.id,
                                             'product_id': mv.product_id.id, 'product_uom_id': mv.product_uom.id,
                                             'qty_done': mv.product_uom_qty, 'location_id': p.location_id.id,
                                             'location_dest_id': p.location_dest_id.id, 'company_id': c.id})
                    force_validate(self.env, p)
                    actor = pick_actor(self.env, p.partner_id, c)
                    p.write({'date_done': fields.Datetime.now(), 'x_flf_done_user_id': actor.id})
                except Exception:
                    continue
            # 4) SOMETIMES CREATE AN INCOMING AND VALIDATE (REPLENISH)
            if in_type and random.random() < 0.25:
                vendor = self.env['res.partner'].sudo().search([('supplier_rank', '>', 0), ('company_id', 'in', [c.id, False])], limit=1)
                if not vendor:
                    vendor = U.choose_partner(c)
                if not vendor:
                    continue
                # resolve locations robustly for IN
                Wh = self.env['stock.warehouse'].sudo().search([('company_id', '=', c.id)], limit=1)
                loc_stock = Wh.lot_stock_id if Wh else False
                src_in = in_type.default_location_src_id.id if in_type.default_location_src_id else False
                dst_in = in_type.default_location_dest_id.id if in_type.default_location_dest_id else False
                if not src_in:
                    src_in = self.env['stock.location'].sudo().search([
                        ('usage', '=', 'supplier'), ('company_id', 'in', [c.id, False])
                    ], limit=1, order='company_id desc').id
                if not dst_in:
                    dst_in = (loc_stock and loc_stock.id) or self.env['stock.location'].sudo().search([
                        ('usage', '=', 'internal'), ('company_id', 'in', [c.id, False])
                    ], limit=1, order='company_id desc').id
                if not (src_in and dst_in):
                    continue
                p_in = Picking.with_company(c).create({
                    'picking_type_id': in_type.id, 'company_id': c.id,
                    'partner_id': vendor.id if vendor else False, 'origin': origin,
                    'location_id': src_in,
                    'location_dest_id': dst_in,
                    'scheduled_date': now - timedelta(hours=random.randint(0, max(1, int(getattr(vendor, 'x_flf_inbound_max_days', 2) or 2) * 24))),
                })
                prods = Product.search([], limit=10)
                for prod in random.sample(prods, min(random.choice([1, 1, 2]), len(prods))):
                    qty = random.choice([3.0, 5.0, 8.0, 10.0])
                    mv = Move.create({'name': f'IN {prod.display_name}', 'picking_id': p_in.id,
                                      'product_id': prod.id, 'product_uom': uom_unit.id, 'product_uom_qty': qty,
                                      'location_id': p_in.location_id.id, 'location_dest_id': p_in.location_dest_id.id,
                                      'company_id': c.id})
                    MoveLine.create({'move_id': mv.id, 'picking_id': p_in.id, 'product_id': prod.id,
                                     'product_uom_id': uom_unit.id, 'qty_done': qty,
                                     'location_id': p_in.location_id.id, 'location_dest_id': p_in.location_dest_id.id,
                                     'company_id': c.id})
                p_in.action_confirm(); force_validate(self.env, p_in)
                max_days = int(getattr(vendor, 'x_flf_inbound_max_days', 2) or 2)
                done_dt = p_in.scheduled_date + timedelta(hours=random.randint(1, max(1, max_days * 24)))
                if done_dt > now:
                    done_dt = now
                p_in.write({'date_done': done_dt})
        return True
