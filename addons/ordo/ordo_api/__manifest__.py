{
    'name': 'Ordo API',
    'version': '18.0.1.0.0',
    'summary': 'Main API system for Ordo',
    'category': 'Chatbots',
    'depends': ['base', 'fastapi'],
    'data': [
        'data/res_users.xml',
        'security/res_groups.xml',
        'security/ir.model.access.csv',
        'security/ir_rule.xml',
        'data/fastapi_endpoint.xml',
    ],
    'installable': True,
    'application': False,
    'license': 'LGPL-3',
} # type: ignore
