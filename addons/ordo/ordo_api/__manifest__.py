{
    'name': 'Ordo API',
    'version': '18.0.1.0.0',
    'summary': 'Main API system for Ordo',
    'category': 'Chatbots',
    'depends': ['base', 'fastapi'],
    'data': [
        'data/demo_fastapi_user.xml',
        'data/demo_fastapi_group.xml',
        'data/fastapi_endpoint.xml',
    ],
    'installable': True,
    'application': False,
    'license': 'LGPL-3',
} # type: ignore
