FROM odoo:18.0

# Switch to root to install dependencies
USER root

# Set OpenAI API key environment variable
ARG OPENAI_API_KEY
ENV OPENAI_API_KEY=${OPENAI_API_KEY}

# Cache busting: separate COPY for requirements
COPY ./requirements.txt /tmp/requirements.txt

# Install OS-level dependencies (including git)
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

# Set permissions and prepare addons directory
RUN mkdir -p /mnt/extra-addons && \
    chown -R odoo:odoo /mnt/extra-addons && \
    chown -R odoo:odoo /var/lib/odoo && \
    chsh -s /bin/bash odoo || usermod -s /bin/bash odoo

# Fix permissions for all custom mounts (important for VS Code editing)
RUN mkdir -p /mnt && \
    chown -R odoo:odoo /mnt

# Copy Odoo config and addons
COPY --chown=odoo:odoo ./config/odoo.conf /etc/odoo/odoo.conf
COPY --chown=odoo:odoo ./addons /mnt/extra-addons

# Switch to odoo user (now has /bin/bash shell)
USER odoo

# Run Odoo with initial module install
CMD ["odoo", "-c", "/etc/odoo/odoo.conf", "-i", "setup_odoo"]
