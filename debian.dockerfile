# Use a minimal base image
FROM debian:stable-slim

# Build arguments to set environment variables at build time
ARG DEF_XRDP_PORT=3389
ARG DEF_STARTING_WEBSITE_URL=https://www.google.com
ARG DEF_LANG=en_US.UTF-8
ARG DEF_LC_ALL=C.UTF-8
ARG DEF_CUSTOMIZE=false
ARG DEF_CUSTOM_ENTRYPOINTS_DIR=/app/custom_entrypoints_scripts
ARG DEF_AUTO_START_BROWSER=true
ARG DEF_AUTO_START_XTERM=true
ARG DEF_DEBIAN_FRONTEND=noninteractive
ARG DEF_XRDP_USER=rdpuser
ARG DEF_XRDP_PASSWORD=money4band
ENV XRDP_USER=${DEF_XRDP_USER} XRDP_PASSWORD=${DEF_XRDP_PASSWORD}

# Set environment variables with default values
ENV \
    STARTING_WEBSITE_URL=${DEF_STARTING_WEBSITE_URL} \
    LANG=${DEF_LANG} \
    LC_ALL=${DEF_LC_ALL} \
    CUSTOMIZE=${DEF_CUSTOMIZE} \
    CUSTOM_ENTRYPOINTS_DIR=${DEF_CUSTOM_ENTRYPOINTS_DIR} \
    AUTO_START_BROWSER=${DEF_AUTO_START_BROWSER} \
    AUTO_START_XTERM=${DEF_AUTO_START_XTERM} \
    DEBIAN_FRONTEND=${DEF_DEBIAN_FRONTEND} \
    XRDP_PORT=${DEF_XRDP_PORT}

# Install necessary packages and setup noVNC
RUN set -e; \
    apt update && \
    apt full-upgrade -qqy && \
    apt install -qqy \
      tini \
      supervisor \
      bash \
      xrdp \
      fluxbox \
      xterm \
      nano \
      chromium && \
    useradd -m -s /bin/bash "${XRDP_USER}" && \
    echo "${XRDP_USER}:${XRDP_PASSWORD}" | chpasswd && \
    # create an .xsession so xrdp will launch Chromium on session start
    echo '#!/bin/sh' > /home/${XRDP_USER}/.xsession && \
    echo 'exec fluxbox &' >> /home/${XRDP_USER}/.xsession && \
    echo 'sleep 1' >> /home/${XRDP_USER}/.xsession && \
    echo 'exec /usr/bin/chromium --no-sandbox --disable-dev-shm-usage "${STARTING_WEBSITE_URL}"' >> /home/${XRDP_USER}/.xsession && \
    chown ${XRDP_USER}:${XRDP_USER} /home/${XRDP_USER}/.xsession && \
    chmod +x /home/${XRDP_USER}/.xsession && \
    apt autoremove --purge -y && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

# Create necessary directories for supervisor and custom entrypoints
RUN mkdir -p /etc/supervisor.d /app/conf.d ${DEF_CUSTOM_ENTRYPOINTS_DIR}
RUN mkdir -p /var/log/supervisor

# Copy configuration files
COPY supervisord.conf /etc/supervisor.d/supervisord.conf
# only bring in xrdp (and xterm) programs, drop VNC configs
COPY conf.d/xrdp.conf conf.d/xterm.conf /app/conf.d/
COPY base_entrypoint.sh customizable_entrypoint.sh /usr/local/bin/
COPY browser_conf/chromium.conf /app/conf.d/

# Make the entrypoint scripts executable
RUN chmod +x /usr/local/bin/base_entrypoint.sh /usr/local/bin/customizable_entrypoint.sh

# Expose the XRDP port
EXPOSE ${XRDP_PORT}

# Set tini as the entrypoint and the custom script as the command
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/usr/local/bin/customizable_entrypoint.sh"]
