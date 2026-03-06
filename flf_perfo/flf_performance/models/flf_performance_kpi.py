# -*- coding: utf-8 -*-
from datetime import datetime, timedelta
from odoo import api, fields, models


class FlfPerformanceKPI(models.Model):
    _name = 'flf.performance.kpi'
    _description = 'FLF Performance KPI (daily aggregates)'
    _order = 'date desc, flow'

    date = fields.Date(index=True, required=True)
    company_id = fields.Many2one('res.company', required=True, default=lambda self: self.env.company, index=True)
    partner_id = fields.Many2one('res.partner', index=True)
    user_id = fields.Many2one('res.users', index=True)
    flow = fields.Selection([('out', 'Outgoing'), ('in', 'Incoming')], required=True, index=True)

    pickings_done = fields.Integer(default=0)
    lines_done = fields.Integer(default=0)
    qty_done = fields.Float(default=0.0)
    pct_in_deadline = fields.Float(default=0.0)
    avg_sec_print_to_done = fields.Float(default=0.0)
    pickings_risk_count = fields.Integer(default=0)

    done_in_soft_window = fields.Integer(default=0)
    done_in_last_truck = fields.Integer(default=0)
    done_afterhours_transfer = fields.Integer(default=0)

    all_created_shipped_today = fields.Boolean(default=False)
    effort_consolidation_score = fields.Float(default=0.0)
    is_effort_consolidation_day = fields.Boolean(default=False)
    offday_shipments = fields.Integer(default=0)

    @api.model
    def _date_range_today(self):
        today = fields.Date.context_today(self)
        start_dt = fields.Datetime.to_datetime(f"{today} 00:00:00")
        end_dt = start_dt + timedelta(days=1)
        return today, start_dt, end_dt

    @api.model
    def _flow_domain(self, flow):
        code = 'outgoing' if flow == 'out' else 'incoming'
        return [('state', '=', 'done'), ('company_id', '=', self.env.company.id), ('picking_type_id.code', '=', code)]

    @api.model
    def cron_recompute_today(self):
        """Мінімальна інкрементальна агрегація за сьогодні по компанії (без розрізів partner/user)."""
        today, start_dt, end_dt = self._date_range_today()
        for flow in ['out', 'in']:
            domain = self._flow_domain(flow) + [('date_done', '>=', start_dt), ('date_done', '<', end_dt)]
            pickings = self.env['stock.picking'].search(domain)

            pickings_done = len(pickings)
            mls = pickings.mapped('move_line_ids')
            lines_done = len(mls)
            qty_done = sum(mls.mapped('qty_done')) if mls else 0.0

            # % in deadline
            in_deadline_count = len(pickings.filtered(lambda p: getattr(p, 'x_flf_in_deadline', False)))
            pct_in_deadline = (in_deadline_count * 100.0 / pickings_done) if pickings_done else 0.0

            # avg seconds print->done
            durations = []
            for p in pickings:
                ts = getattr(p, 'x_flf_print_ts', None)
                dd = p.date_done
                if ts and dd:
                    try:
                        durations.append((dd - ts).total_seconds())
                    except Exception:
                        pass
            avg_sec_print_to_done = (sum(durations) / len(durations)) if durations else 0.0

            # risk count (only for outgoing)
            if flow == 'out':
                risk_domain = [
                    ('company_id', '=', self.env.company.id),
                    ('picking_type_id.code', '=', 'outgoing'),
                    ('x_flf_risk_today', '=', True),
                ]
                pickings_risk_count = self.env['stock.picking'].search_count(risk_domain)
            else:
                pickings_risk_count = 0

            offday = 1 if today.weekday() == 6 else 0  # неділя
            offday_shipments = pickings_done if offday else 0

            vals = {
                'date': today,
                'company_id': self.env.company.id,
                'partner_id': False,
                'user_id': False,
                'flow': flow,
                'pickings_done': pickings_done,
                'lines_done': lines_done,
                'qty_done': qty_done,
                'pct_in_deadline': pct_in_deadline,
                'avg_sec_print_to_done': avg_sec_print_to_done,
                'pickings_risk_count': pickings_risk_count,
                'done_in_soft_window': 0,
                'done_in_last_truck': 0,
                'done_afterhours_transfer': 0,
                'all_created_shipped_today': False,
                'effort_consolidation_score': 0.0,
                'is_effort_consolidation_day': False,
                'offday_shipments': offday_shipments,
            }

            rec = self.search([
                ('date', '=', today),
                ('company_id', '=', self.env.company.id),
                ('partner_id', '=', False),
                ('user_id', '=', False),
                ('flow', '=', flow),
            ], limit=1)
            if rec:
                rec.write(vals)
            else:
                self.create(vals)
        return True

    @api.model
    def seed_demo_data(self):
        today, start_dt, end_dt = self._date_range_today()
        Company = self.env['res.company']
        Partner = self.env['res.partner']
        Product = self.env['product.product']
        Picking = self.env['stock.picking']
        Move = self.env['stock.move']
        MoveLine = self.env['stock.move.line']
        Warehouse = self.env['stock.warehouse']
        uom_unit = self.env.ref('uom.product_uom_unit')
        prod_categ = self.env.ref('product.product_category_all')

        def _get_or_create_product(name):
            prod = Product.search([('name', '=', name)], limit=1)
            if not prod:
                prod = Product.create({
                    'name': name,
                    'type': 'product',
                    'uom_id': uom_unit.id,
                    'uom_po_id': uom_unit.id,
                    'categ_id': prod_categ.id,
                })
            return prod

        p_widget = _get_or_create_product('FLF Widget A')
        p_gadget = _get_or_create_product('FLF Gadget B')

        companies = Company.search([('name', 'ilike', 'FLF Test Co')])
        admin = self.env.ref('base.user_admin', raise_if_not_found=False)
        for company in companies:
            wh = Warehouse.search([('company_id', '=', company.id)], limit=1)
            if not wh:
                continue
            # Resolve picking types robustly
            in_type = wh.in_type_id or self.env['stock.picking.type'].search([
                ('code', '=', 'incoming'), ('warehouse_id', '=', wh.id)
            ], limit=1)
            out_type = wh.out_type_id or self.env['stock.picking.type'].search([
                ('code', '=', 'outgoing'), ('warehouse_id', '=', wh.id)
            ], limit=1)

            cctx = dict(self.env.context, company_id=company.id, allowed_company_ids=[company.id])
            PartnerC = Partner.with_context(cctx)
            PickingC = Picking.with_context(cctx)
            MoveC = Move.with_context(cctx)
            MoveLineC = MoveLine.with_context(cctx)
            UserC = self.env['res.users'].with_context(cctx)
            UserConfigC = self.env['flf.user_config'].with_context(cctx)

            vendor = PartnerC.search([('name', '=', 'FLF Vendor'), ('company_id', '=', company.id)], limit=1)
            if not vendor:
                vendor = PartnerC.create({'name': 'FLF Vendor', 'supplier_rank': 1, 'company_id': company.id})

            early = PartnerC.search([('name', '=', 'EarlyBird LLC'), ('company_id', '=', company.id)], limit=1)
            if not early:
                early = PartnerC.create({
                    'name': 'EarlyBird LLC',
                    'company_id': company.id,
                    'x_flf_deadline_hour': 15.5,
                    'x_flf_last_shipment_hour': 19.0,
                    'x_flf_afterhours_credit': True,
                    'x_flf_big_order_line_count': 50,
                    'x_flf_big_order_qty': 150,
                    'x_flf_use_draft_trigger': True,
                })
            elect = PartnerC.search([('name', '=', 'Electrinics LTD'), ('company_id', '=', company.id)], limit=1)
            if not elect:
                elect = PartnerC.create({
                    'name': 'Electrinics LTD',
                    'company_id': company.id,
                    'x_flf_deadline_hour': 17.5,
                    'x_flf_last_shipment_hour': 19.0,
                    'x_flf_afterhours_credit': True,
                    'x_flf_big_order_line_count': 80,
                    'x_flf_big_order_qty': 300,
                    'x_flf_use_draft_trigger': True,
                })

            # Ensure user configs (primary partners) exist per company and assign responsibility
            try:
                digits = ''.join(ch for ch in (company.name or '') if ch.isdigit()) or '1'
                login1 = f"c{digits}_worker1@example.com"
                login2 = f"c{digits}_worker2@example.com"
                u1 = UserC.search([('login', '=', login1)], limit=1)
                u2 = UserC.search([('login', '=', login2)], limit=1)
                # Friendly names per company
                friendly = {
                    '1': ("Alice Carter", "Bob Smith"),
                    '2': ("Carol Diaz", "David Young"),
                    '3': ("Eve Martin", "Frank Moore"),
                    '4': ("Grace Lee", "Henry Clark"),
                    '5': ("Ivy Scott", "Jack Turner"),
                    '6': ("Nina Adams", "Oscar Hill"),
                }
                all_company_ids = companies.ids
                if u1:
                    try:
                        name1 = friendly.get(digits, (u1.name, u1.name))[0]
                        u1.sudo().write({'name': name1, 'company_ids': [(6, 0, all_company_ids)]})
                    except Exception:
                        pass
                if u2:
                    try:
                        name2 = friendly.get(digits, (u2.name, u2.name))[-1]
                        u2.sudo().write({'name': name2, 'company_ids': [(6, 0, all_company_ids)]})
                    except Exception:
                        pass
                if u1 and not UserConfigC.search([('company_id', '=', company.id), ('user_id', '=', u1.id)], limit=1):
                    UserConfigC.create({'company_id': company.id, 'user_id': u1.id, 'primary_partner_id': early.id})
                if u2 and not UserConfigC.search([('company_id', '=', company.id), ('user_id', '=', u2.id)], limit=1):
                    UserConfigC.create({'company_id': company.id, 'user_id': u2.id, 'primary_partner_id': elect.id})
                user_ids = [u.id for u in (u1 | u2) if u]
                if user_ids:
                    early.write({'x_flf_responsible_user_ids': [(6, 0, user_ids)]})
                    elect.write({'x_flf_responsible_user_ids': [(6, 0, user_ids)]})

                # Also include admin user for visibility in current company
                if admin:
                    # make sure admin allowed in this company
                    if company.id not in admin.company_ids.ids:
                        admin.sudo().write({'company_ids': [(4, company.id)]})
                    if not UserConfigC.search([('company_id', '=', company.id), ('user_id', '=', admin.id)], limit=1):
                        UserConfigC.create({'company_id': company.id, 'user_id': admin.id, 'primary_partner_id': early.id})
                    # add admin to responsible users
                    early.write({'x_flf_responsible_user_ids': [(4, admin.id)]})
                    elect.write({'x_flf_responsible_user_ids': [(4, admin.id)]})
            except Exception:
                pass

            # Skip creating pickings if already seeded, but keep assignments above
            existing_demo = PickingC.search([('origin', '=', 'FLF DEMO')], limit=1)
            if existing_demo:
                # ensure KPI recompute still runs
                self.cron_recompute_today()
                # still ensure there is a pending at-risk draft if not present
                loc_suppliers = self.env.ref('stock.stock_location_suppliers')
                loc_customers = self.env.ref('stock.stock_location_customers')
                loc_stock = wh.lot_stock_id
                pending = PickingC.search([('origin', '=', 'FLF DEMO PENDING'), ('company_id', '=', company.id)], limit=1)
                if not pending and out_type:
                    pending = PickingC.create({
                        'picking_type_id': out_type.id,
                        'company_id': company.id,
                        'partner_id': elect.id,
                        'origin': 'FLF DEMO PENDING',
                        'location_id': (out_type.default_location_src_id and out_type.default_location_src_id.id) or (loc_stock and loc_stock.id),
                        'location_dest_id': (out_type.default_location_dest_id and out_type.default_location_dest_id.id) or (loc_customers and loc_customers.id),
                        'scheduled_date': end_dt - timedelta(hours=1),
                    })
                    MoveC.create({
                        'name': 'OUT Pending Widget',
                        'picking_id': pending.id,
                        'product_id': p_widget.id,
                        'product_uom': uom_unit.id,
                        'product_uom_qty': 3.0,
                        'location_id': pending.location_id.id,
                        'location_dest_id': pending.location_dest_id.id,
                        'company_id': company.id,
                    })
                    pending.action_confirm()
                    # set partner deadline to ~now + 30 min to show at-risk
                    try:
                        now = datetime.now()
                        elect.write({'x_flf_deadline_hour': max(0.0, (now.hour + ((now.minute + 30) / 60.0)) % 24)})
                    except Exception:
                        pass
                continue

            # Stock core locations (fallbacks)
            loc_suppliers = self.env.ref('stock.stock_location_suppliers')
            loc_customers = self.env.ref('stock.stock_location_customers')
            loc_stock = wh.lot_stock_id

            # Incoming picking (receive stock)
            pin = PickingC.create({
                'picking_type_id': in_type.id,
                'company_id': company.id,
                'partner_id': vendor.id,
                'origin': 'FLF DEMO',
                'location_id': (in_type.default_location_src_id and in_type.default_location_src_id.id) or (loc_suppliers and loc_suppliers.id),
                'location_dest_id': (in_type.default_location_dest_id and in_type.default_location_dest_id.id) or (loc_stock and loc_stock.id),
                'scheduled_date': start_dt,
            })
            m1 = MoveC.create({
                'name': 'IN Widget',
                'picking_id': pin.id,
                'product_id': p_widget.id,
                'product_uom': uom_unit.id,
                'product_uom_qty': 40.0,
                'location_id': pin.location_id.id,
                'location_dest_id': pin.location_dest_id.id,
                'company_id': company.id,
            })
            m2 = MoveC.create({
                'name': 'IN Gadget',
                'picking_id': pin.id,
                'product_id': p_gadget.id,
                'product_uom': uom_unit.id,
                'product_uom_qty': 30.0,
                'location_id': pin.location_id.id,
                'location_dest_id': pin.location_dest_id.id,
                'company_id': company.id,
            })
            pin.action_confirm()
            for mv in pin.move_ids_without_package:
                MoveLineC.create({
                    'move_id': mv.id,
                    'picking_id': pin.id,
                    'product_id': mv.product_id.id,
                    'product_uom_id': mv.product_uom.id,
                    'qty_done': mv.product_uom_qty,
                    'location_id': pin.location_id.id,
                    'location_dest_id': pin.location_dest_id.id,
                    'company_id': company.id,
                })
            pin.button_validate()
            pin.write({'date_done': start_dt + timedelta(hours=9)})

            # Outgoing pickings (deliver to customers)
            for partner, qty1, qty2, ofs in [(early, 8.0, 5.0, 12), (elect, 6.0, 4.0, 15)]:
                pout = PickingC.create({
                    'picking_type_id': out_type.id,
                    'company_id': company.id,
                    'partner_id': partner.id,
                    'origin': 'FLF DEMO',
                    'location_id': (out_type.default_location_src_id and out_type.default_location_src_id.id) or (loc_stock and loc_stock.id),
                    'location_dest_id': (out_type.default_location_dest_id and out_type.default_location_dest_id.id) or (loc_customers and loc_customers.id),
                    'scheduled_date': start_dt + timedelta(hours=ofs),
                })
                mo1 = MoveC.create({
                    'name': 'OUT Widget',
                    'picking_id': pout.id,
                    'product_id': p_widget.id,
                    'product_uom': uom_unit.id,
                    'product_uom_qty': qty1,
                    'location_id': pout.location_id.id,
                    'location_dest_id': pout.location_dest_id.id,
                    'company_id': company.id,
                })
                mo2 = MoveC.create({
                    'name': 'OUT Gadget',
                    'picking_id': pout.id,
                    'product_id': p_gadget.id,
                    'product_uom': uom_unit.id,
                    'product_uom_qty': qty2,
                    'location_id': pout.location_id.id,
                    'location_dest_id': pout.location_dest_id.id,
                    'company_id': company.id,
                })
                pout.action_confirm()
                pout.action_assign()
                for mv in pout.move_ids_without_package:
                    MoveLineC.create({
                        'move_id': mv.id,
                        'picking_id': pout.id,
                        'product_id': mv.product_id.id,
                        'product_uom_id': mv.product_uom.id,
                        'qty_done': mv.product_uom_qty,
                        'location_id': pout.location_id.id,
                        'location_dest_id': pout.location_dest_id.id,
                        'company_id': company.id,
                    })
                pout.button_validate()
                pout.write({'date_done': start_dt + timedelta(hours=ofs)})

            # One pending outgoing to appear in at-risk if near deadline
            pending = PickingC.search([('origin', '=', 'FLF DEMO PENDING'), ('company_id', '=', company.id)], limit=1)
            if not pending:
                pending = PickingC.create({
                    'picking_type_id': out_type.id,
                    'company_id': company.id,
                    'partner_id': elect.id,
                    'origin': 'FLF DEMO PENDING',
                    'location_id': (out_type.default_location_src_id and out_type.default_location_src_id.id) or (loc_stock and loc_stock.id),
                    'location_dest_id': (out_type.default_location_dest_id and out_type.default_location_dest_id.id) or (loc_customers and loc_customers.id),
                    'scheduled_date': end_dt - timedelta(hours=1),
                })
                MoveC.create({
                    'name': 'OUT Pending Widget',
                    'picking_id': pending.id,
                    'product_id': p_widget.id,
                    'product_uom': uom_unit.id,
                    'product_uom_qty': 3.0,
                    'location_id': pending.location_id.id,
                    'location_dest_id': pending.location_dest_id.id,
                    'company_id': company.id,
                })
                pending.action_confirm()
                elect.write({'x_flf_deadline_hour': max(0.0, (datetime.now().hour + ((datetime.now().minute + 45) / 60.0)) % 24)})

        self.cron_recompute_today()
        return True
