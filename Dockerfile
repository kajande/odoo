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

# Install OS-level dependencies
RUN apt-get update && \
    apt-get install -y \
    iputils-ping \
    postgresql-client \
    git && \
    rm -rf /var/lib/apt/lists/*

# Install LaTeX (for PDF generation)
RUN apt-get update && apt-get install -y --no-install-recommends \
    texlive-latex-base \
    texlive-latex-extra \
    texlive-fonts-recommended \
    texlive-xetex && \
    rm -rf /var/lib/apt/lists/*

# Install PDF utilities
RUN apt-get update && apt-get install -y \
    poppler-utils && \
    rm -rf /var/lib/apt/lists/*

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

# Copy Odoo config and addons
COPY --chown=odoo:odoo ./config/odoo.conf /etc/odoo/odoo.conf
COPY --chown=odoo:odoo ./addons /mnt/extra-addons

# Switch to odoo user
USER odoo

# Run Odoo
CMD ["odoo", "-c", "/etc/odoo/odoo.conf", "-i", "setup_odoo"]
