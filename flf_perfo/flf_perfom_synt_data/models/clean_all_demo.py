# -*- coding: utf-8 -*-
from odoo import api, fields, models


class FlfPerfSyntCleaner(models.AbstractModel):
    _name = 'flf.perf.synt.cleaner'
    _description = 'Cleaner for FLF synthetic demo pickings'

    @api.model
    def _allowed_companies(self):
        ids = self.env.context.get('allowed_company_ids') or self.env.user.company_ids.ids
        try:
            if (self.env.user.id == 1) and (not ids or len(ids) <= 1):
                ids = self.env['res.company'].sudo().search([('name', 'ilike', 'FLF Test Co')]).ids or ids
        except Exception:
            pass
        return ids or [self.env.company.id]

    @api.model
    def delete_all_demo(self):
        Picking = self.env['stock.picking'].sudo()
        dom = [('origin', 'like', 'DEMO %')]
        picks = Picking.search(dom)
        deleted = 0
        archived = 0
        marked = 0
        for p in picks:
            try:
                p.unlink()
                deleted += 1
                continue
            except Exception:
                pass
            try:
                try:
                    p.action_cancel()
                except Exception:
                    pass
                if 'active' in p._fields:
                    try:
                        p.sudo().write({'active': False})
                        archived += 1
                    except Exception:
                        pass
                try:
                    p.sudo().write({'origin': 'REMOVED'})
                    marked += 1
                except Exception:
                    pass
            except Exception:
                try:
                    p.sudo().write({'origin': 'REMOVED'})
                    marked += 1
                except Exception:
                    pass
        return {'deleted': deleted, 'archived': archived, 'marked': marked}
