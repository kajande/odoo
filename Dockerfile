FROM odoo:18.0

# Switch to root to install dependencies
USER root

# Build args for API key and DB credentials
ARG OPENAI_API_KEY
ARG DB_HOST
ARG DB_PORT
ARG DB_USER
ARG DB_PASSWORD
ARG DB_NAME
ARG PGPASSWORD
ARG ODOO_DB
ARG ODOO_USERNAME
ARG ODOO_PASSWORD
ARG PG_URI

# Environment variables for runtime
ENV OPENAI_API_KEY=${OPENAI_API_KEY}
ENV DB_HOST=${DB_HOST}
ENV DB_PORT=${DB_PORT}
ENV DB_USER=${DB_USER}
ENV DB_PASSWORD=${DB_PASSWORD}
ENV DB_NAME=${DB_NAME}
ENV PGPASSWORD=${PGPASSWORD}
ENV ODOO_DB=${ODOO_DB}
ENV ODOO_USERNAME=${ODOO_USERNAME}
ENV ODOO_PASSWORD=${ODOO_PASSWORD}
ENV PG_URI=${PG_URI}

# Cache busting: separate COPY for requirements
COPY ./requirements.txt /tmp/requirements.txt

# Install OS-level dependencies (including envsubst and gosu)
RUN apt-get update && \
    apt-get install -y \
    iputils-ping \
    postgresql-client \
    git \
    gettext-base \
    gosu \
    curl \
    locales && \
    rm -rf /var/lib/apt/lists/*

# Fix locale settings
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen en_US.UTF-8

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Install PDF utilities
RUN apt-get update && apt-get install -y \
    poppler-utils && \
    rm -rf /var/lib/apt/lists/*

# Create log directory with proper permissions BEFORE Python installation
RUN mkdir -p /var/log/odoo && \
    chown -R odoo:odoo /var/log/odoo && \
    chmod -R 755 /var/log/odoo

# Install Python dependencies
RUN --mount=type=cache,target=/root/.cache \
    set -x && \
    echo "Installing requirements from /tmp/requirements.txt:" && \
    cat /tmp/requirements.txt && \
    pip3 install \
        --verbose \
        --break-system-packages \
        --no-cache-dir \
        --ignore-installed \
        -r /tmp/requirements.txt

# Set permissions and prepare addons directory
RUN mkdir -p /mnt/extra-addons && \
    chown -R odoo:odoo /mnt/extra-addons && \
    chown -R odoo:odoo /var/lib/odoo && \
    chsh -s /bin/bash odoo || usermod -s /bin/bash odoo

RUN mkdir -p /mnt && \
    chown -R odoo:odoo /mnt

# Copy addons, scripts and entrypoint
COPY --chown=odoo:odoo ./addons /mnt/extra-addons
COPY ./setup_odoo_modules.sh /setup_odoo_modules.sh
COPY ./entrypoint.sh /entrypoint.sh

# Make scripts executable
RUN chmod +x /entrypoint.sh /setup_odoo_modules.sh

# Don't switch to odoo user yet - let entrypoint handle it
# USER odoo

# Set the entrypoint (runs as root, then switches to odoo user)
ENTRYPOINT ["/entrypoint.sh"]

# Default command - now simplified since setup happens in entrypoint
CMD ["odoo", "-c", "/etc/odoo/odoo.conf"]
