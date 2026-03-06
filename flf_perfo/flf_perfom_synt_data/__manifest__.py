# -*- coding: utf-8 -*-
{
    'name': 'FLF Performance Synthetic Data',
    'version': '15.0.1.0.0',
    'summary': 'Synthetic data generators for FLF Performance (dev/demo)',
    'category': 'Tools',
    'author': 'FLF',
    'license': 'LGPL-3',
    'depends': ['base', 'stock', 'flf_performance'],
    'data': [
        'security/ir.model.access.csv',
        'data/ir_cron.xml',
        'data/server_actions.xml',
        'wizards/demo_wizard_views.xml',
        'wizards/synt_settings_views.xml',
        'views/menu.xml',
    ],
    'installable': True,
    'application': False,
}
