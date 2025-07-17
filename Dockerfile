FROM odoo:18.0

# Switch to root to install dependencies
USER root

# Set OpenAI API key environment variable
ARG OPENAI_API_KEY
ENV OPENAI_API_KEY=${OPENAI_API_KEY}

# Cache busting: separate COPY for requirements
COPY ./requirements.txt /tmp/requirements.txt

# Install OS-level dependencies
RUN apt-get update && \
    apt-get install -y iputils-ping postgresql-client && \
    rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y --no-install-recommends \
    texlive-latex-base \
    texlive-latex-extra \
    texlive-fonts-recommended \
    texlive-xetex \
    && rm -rf /var/lib/apt/lists/*

RUN  apt-get update && apt-get install poppler-utils -y # pdf2image

# Install Python dependencies with cache busting
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
