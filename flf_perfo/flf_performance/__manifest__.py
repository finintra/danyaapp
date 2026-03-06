# -*- coding: utf-8 -*-
{
    'name': 'FLF Performance',
    'version': '15.0.1.0.0',
    'summary': 'KPIs and dashboards for fulfillment performance',
    'category': 'Inventory/Operations',
    'author': 'FLF',
    'license': 'LGPL-3',
    'depends': ['base', 'stock', 'mail', 'mrp', 'sale_stock'],
    'data': [
        'security/security.xml',
        'security/ir.model.access.csv',
        'security/rules.xml',
        'views/menuitems.xml',
        'views/config_menu.xml',
        'views/settings_views.xml',
        'views/kpi_views.xml',
        'views/res_partner_views.xml',
        'views/partner_sla_views.xml',
        'views/res_users_views.xml',
        'views/user_config_views.xml',
        'views/truck_schedule_views.xml',
        'views/truck_slot_views.xml',
        'views/at_risk_views.xml',
        'data/ir_cron.xml',
        'data/seed_test_data.xml',
        'data/seed_test_warehouses.xml',
        'data/company_policies.xml',
        'data/seed_generated_kpis.xml',
    ],
    'installable': True,
    'application': False,
    'assets': {
        'web.assets_backend': [
            'flf_performance/static/src/js/wallboard_utils.js',
            'flf_performance/static/src/js/wallboard.js',
            'flf_performance/static/src/css/wallboard.css',
        ],
        'web.assets_qweb': [
            'flf_performance/static/src/xml/wallboard.xml',
        ],
    },
}

