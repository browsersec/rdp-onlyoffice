# Use a minimal base image
FROM debian:bookworm-slim

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
    apt install -qqy --no-install-recommends \
      tini \
      supervisor \
      bash \
      xrdp \
      fluxbox \
      xterm \
      nano \
      curl \
      wget \
      gnupg2 \
      ca-certificates \
      lsb-release \
      apt-transport-https \
      # Additional X11 packages for proper display
      xserver-xorg-core \
      xserver-xorg-input-all \
      xauth \
      x11-xserver-utils \
      # Additional window manager dependencies
      menu \
      # Desktop environment utilities
      dbus-x11 \
      # Font packages for proper display
      fonts-dejavu \
      # Locale support
      locales

# Configure locale
RUN set -e; \
    echo "${DEF_LANG} UTF-8" > /etc/locale.gen && \
    locale-gen && \
    mkdir -p /etc/default && \
    echo "LANG=${DEF_LANG}" > /etc/default/locale && \
    echo "LC_ALL=${DEF_LC_ALL}" >> /etc/default/locale

# Install OnlyOffice in a separate step with better error handling
RUN set -e; \
    apt update && \
    # Direct DEB installation instead of repository
    wget -O /tmp/onlyoffice-desktopeditors.deb https://download.onlyoffice.com/install/desktop/editors/linux/onlyoffice-desktopeditors_amd64.deb && \
    apt install -qqy --no-install-recommends /tmp/onlyoffice-desktopeditors.deb && \
    rm /tmp/onlyoffice-desktopeditors.deb && \
    # Setup user
    useradd -m -s /bin/bash "${XRDP_USER}" && \
    echo "${XRDP_USER}:${XRDP_PASSWORD}" | chpasswd && \
    # Add user to groups for X11 access
    usermod -a -G audio,video,tty "${XRDP_USER}" && \
    # create an .xsession so xrdp will launch OnlyOffice on session start
    echo '#!/bin/sh' > /home/${XRDP_USER}/.xsession && \
    echo 'export DISPLAY=:10' >> /home/${XRDP_USER}/.xsession && \
    echo 'exec fluxbox &' >> /home/${XRDP_USER}/.xsession && \
    echo 'sleep 1' >> /home/${XRDP_USER}/.xsession && \
    # Find correct binary path dynamically
    echo 'ONLYOFFICE_BIN=$(which onlyoffice-desktopeditors DesktopEditors 2>/dev/null | head -1)' >> /home/${XRDP_USER}/.xsession && \
    echo 'if [ -z "$ONLYOFFICE_BIN" ]; then' >> /home/${XRDP_USER}/.xsession && \
    echo '  ONLYOFFICE_BIN=$(find /opt /usr/bin -name "onlyoffice-desktopeditors" -o -name "DesktopEditors" 2>/dev/null | head -1)' >> /home/${XRDP_USER}/.xsession && \
    echo 'fi' >> /home/${XRDP_USER}/.xsession && \
    echo 'exec "$ONLYOFFICE_BIN"' >> /home/${XRDP_USER}/.xsession && \
    chown ${XRDP_USER}:${XRDP_USER} /home/${XRDP_USER}/.xsession && \
    chmod +x /home/${XRDP_USER}/.xsession

# Create necessary directories for supervisor and custom entrypoints
RUN mkdir -p /etc/supervisor.d /app/conf.d ${DEF_CUSTOM_ENTRYPOINTS_DIR}
RUN mkdir -p /var/log/supervisor

# Configure XRDP
RUN set -e; \
    # Configure XRDP for proper X sessions
    mkdir -p /etc/xrdp && \
    echo '#!/bin/sh' > /etc/xrdp/startwm.sh && \
    echo 'if [ -r /etc/default/locale ]; then' >> /etc/xrdp/startwm.sh && \
    echo '  . /etc/default/locale' >> /etc/xrdp/startwm.sh && \
    echo '  export LANG LANGUAGE LC_ALL' >> /etc/xrdp/startwm.sh && \
    echo 'fi' >> /etc/xrdp/startwm.sh && \
    echo 'if [ -f ~/.xsession ]; then' >> /etc/xrdp/startwm.sh && \
    echo '  . ~/.xsession' >> /etc/xrdp/startwm.sh && \
    echo 'else' >> /etc/xrdp/startwm.sh && \
    echo '  exec fluxbox' >> /etc/xrdp/startwm.sh && \
    echo 'fi' >> /etc/xrdp/startwm.sh && \
    chmod +x /etc/xrdp/startwm.sh && \
    # Configure fluxbox
    mkdir -p /home/${XRDP_USER}/.fluxbox && \
    echo '#!/bin/sh' > /home/${XRDP_USER}/.fluxbox/startup && \
    echo 'xsetroot -solid grey' >> /home/${XRDP_USER}/.fluxbox/startup && \
    echo 'xterm &' >> /home/${XRDP_USER}/.fluxbox/startup && \
    echo 'exec fluxbox' >> /home/${XRDP_USER}/.fluxbox/startup && \
    chmod +x /home/${XRDP_USER}/.fluxbox/startup && \
    chown -R ${XRDP_USER}:${XRDP_USER} /home/${XRDP_USER}/.fluxbox && \
    # Cleanup
    apt autoremove --purge -y && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

# Copy configuration files
COPY supervisord.conf /etc/supervisor.d/supervisord.conf
# only bring in xrdp (and xterm) programs, drop VNC configs
COPY conf.d/xrdp.conf conf.d/xterm.conf /app/conf.d/
COPY base_entrypoint.sh customizable_entrypoint.sh /usr/local/bin/
COPY browser_conf/onlyoffice.conf /app/conf.d/
COPY custom_entrypoints_scripts/xrdp_fix.sh ${DEF_CUSTOM_ENTRYPOINTS_DIR}/

# Make the entrypoint scripts executable
RUN chmod +x /usr/local/bin/base_entrypoint.sh /usr/local/bin/customizable_entrypoint.sh ${DEF_CUSTOM_ENTRYPOINTS_DIR}/xrdp_fix.sh

# Set CUSTOMIZE to true to run our fix script
ENV CUSTOMIZE=true

# Expose the XRDP port
EXPOSE ${XRDP_PORT}

# Set tini as the entrypoint and the custom script as the command
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/usr/local/bin/customizable_entrypoint.sh"]
