FROM odoo:18.0

# Switch to root to install dependencies
USER root

# Copy requirements BEFORE trying to install them
COPY ./requirements.txt /tmp/requirements.txt

# Install troubleshooting tools and Python packages
RUN apt-get update && \
    apt-get install -y iputils-ping postgresql-client && \
    pip3 install --break-system-packages --no-cache-dir -r /tmp/requirements.txt && \
    rm -rf /var/lib/apt/lists/*

# Set permissions for Odoo data
RUN mkdir -p /mnt/extra-addons && \
    chown -R odoo:odoo /mnt/extra-addons && \
    chown -R odoo:odoo /var/lib/odoo

# Copy Odoo config and addons
COPY --chown=odoo:odoo ./config/odoo.conf /etc/odoo/odoo.conf
COPY --chown=odoo:odoo ./addons /mnt/extra-addons

# Switch to odoo user
USER odoo

# Run Odoo with module installation
CMD ["odoo", "-c", "/etc/odoo/odoo.conf", "-i", "base"]
