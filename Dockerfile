FROM odoo:18.0

# Install troubleshooting tools as root
USER root
RUN apt-get update && \
    apt-get install -y iputils-ping postgresql-client && \
    rm -rf /var/lib/apt/lists/*

# Set permissions for existing odoo user
RUN mkdir -p /mnt/extra-addons && \
    chown -R odoo:odoo /mnt/extra-addons && \
    chown -R odoo:odoo /var/lib/odoo

# Copy files with proper ownership
COPY --chown=odoo:odoo ./config/odoo.conf /etc/odoo/odoo.conf
COPY --chown=odoo:odoo ./addons /mnt/extra-addons

# Switch to existing odoo user
USER odoo

CMD ["odoo", "-c", "/etc/odoo/odoo.conf", "-i", "base"]
