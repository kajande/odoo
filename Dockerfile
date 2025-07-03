FROM odoo:18.0

# Switch to root to install dependencies
USER root

# Cache busting: separate COPY for requirements
COPY ./requirements.txt /tmp/requirements.txt

# Install OS-level dependencies
RUN apt-get update && \
    apt-get install -y iputils-ping postgresql-client && \
    rm -rf /var/lib/apt/lists/*

# Install Python dependencies with cache busting
RUN --mount=type=cache,target=/root/.cache \
    pip3 install --break-system-packages --no-cache-dir --ignore-installed -r /tmp/requirements.txt

# Set permissions for custom addons and Odoo data
RUN mkdir -p /mnt/extra-addons && \
    chown -R odoo:odoo /mnt/extra-addons && \
    chown -R odoo:odoo /var/lib/odoo

# Copy Odoo config and addons
COPY --chown=odoo:odoo ./config/odoo.conf /etc/odoo/odoo.conf
COPY --chown=odoo:odoo ./addons /mnt/extra-addons

# Switch to odoo user
USER odoo

# Run Odoo with initial module install
CMD ["odoo", "-c", "/etc/odoo/odoo.conf", "-i", "setup_odoo"]
