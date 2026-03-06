# -*- coding: utf-8 -*-
from datetime import timedelta
from odoo import api, fields, models
import logging

_logger = logging.getLogger(__name__)


class FlfPerfSyntData(models.AbstractModel):
    _inherit = 'flf.perf.synt.data'

    @api.model
    def demo_cleanup(self, keep_days=45):
        """Очистити DEMO. Якщо keep_days <= 0 — видалити/позначити всі DEMO без обмежень дати.
        DONE не видаляємо жорстко: переносимо у REMOVED (origin) як джерело та архівуємо при потребі.
        """
        ICP = self.env['ir.config_parameter'].sudo()
        keep_days = int(ICP.get_param('flf_perf_synt.keep_days', keep_days))
        Picking = self.env['stock.picking'].sudo()
        if keep_days <= 0:
            dom = [('origin', 'like', 'DEMO %')]
        else:
            cutoff = fields.Datetime.now() - timedelta(days=keep_days)
            dom = [('origin', 'like', 'DEMO %'), ('create_date', '<', cutoff)]
        recs = Picking.search(dom)
        total = len(recs)
        removed = 0
        if recs:
            done = recs.filtered(lambda p: p.state == 'done')
            other = recs - done
            if done:
                try:
                    vals = {'origin': 'REMOVED'}
                    if 'active' in done._fields:
                        vals['active'] = False
                    done.sudo().write(vals)
                except Exception:
                    pass
            if other:
                try:
                    other.sudo().action_cancel()
                except Exception:
                    pass
                try:
                    removed = len(other)
                    other.unlink()
                except Exception:
                    try:
                        other.sudo().write({'origin': 'REMOVED'})
                    except Exception:
                        pass
        _logger.info("[flf_perf_synt] demo_cleanup processed=%s, keep_days=%s", total, keep_days)
        return {'removed': removed, 'keep_days': keep_days}
