# odoo
Kajande Odoo projects and modules

Fast odoo dev commands:

### install module
```bash
docker exec -it odoo-odoo-1 odoo -i odoo --stop-after-init
```

### update module
```bash
docker exec -it odoo-odoo-1 odoo -u odoo --stop-after-init
```

### update all modules
```bash
docker exec -it odoo-odoo-1 odoo -u all --stop-after-init
```

### connect to odoo postgres database
```bash
docker exec -it odoo-db-1 psql -U odoo -d odoo
```

### connect to odoo shell
```bash
docker exec -it odoo-odoo-1 odoo shell -d odoo
```

### clean assets

```bash
docker exec -it odoo_odoo_1 odoo shell
```

```python
domain = [('res_model','=','ir.ui.view'), ('name','like','assets_')]
env['ir.attachment'].search(domain).unlink()
env.cr.commit()
```
