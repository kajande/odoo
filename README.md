# odoo
Kajande Odoo projects and modules

Fast odoo dev commands:

### install module
```bash
docker exec -it ordo-odoo-1 odoo -i ordo --stop-after-init
```

### update module
```bash
docker exec -it ordo-odoo-1 odoo -u ordo --stop-after-init
```

### update all modules
```bash
docker exec -it ordo-odoo-1 odoo -u all --stop-after-init
```

### connect to odoo postgres database
```bash
docker exec -it ordo-db-1 psql -U odoo -d odoo
```

### connect to odoo shell
```bash
docker exec -it ordo-odoo-1 odoo shell -d odoo
```
