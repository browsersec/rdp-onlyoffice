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

RUN groupadd fuse 

# Install necessary packages and setup noVNC
# Modify your .xsession setup in the RUN block
RUN set -e; \
    apt update && \
    apt full-upgrade -qqy && \
    apt install -qqy \
      tini \
      util-linux \
      supervisor \
      bash \
      xrdp \
      fluxbox \
      file-roller \
      xterm \
      shotwell \
      okular \
      vlc \
      mousepad \
      gedit \
      eog \
      wget \
      nano \
      fuse \
      libfuse2 \
      libxkbcommon-x11-0 \
      # start 
      libxcb-icccm4 \
      libxcb-image0 \
      libxcb-keysyms1 \
      libxcb-render-util0 \
      libxcb-xinerama0 \
      libxcb-xkb1 \
      libxcb-randr0 \
      libxcb-shape0 \
      libglib2.0-0 \
      libasound2 \ 
      ca-certificates && \
    # User setup remains the same
    useradd -m -s /bin/bash "${XRDP_USER}" && \
    echo "${XRDP_USER}:${XRDP_PASSWORD}" | chpasswd && \
    adduser ${XRDP_USER} fuse && \
    chmod u+s /bin/fusermount && \
    # IMPORTANT: Create a completely new .xsession file with NO exec commands for applications
    echo '#!/bin/sh' > /home/${XRDP_USER}/.xsession && \
    echo 'fluxbox &' >> /home/${XRDP_USER}/.xsession && \
    echo 'sleep 1' >> /home/${XRDP_USER}/.xsession && \
    echo 'sleep 2' >> /home/${XRDP_USER}/.xsession && \
    echo '/usr/local/bin/agent &' >> /home/${XRDP_USER}/.xsession && \
    echo 'wait' >> /home/${XRDP_USER}/.xsession && \
    chown ${XRDP_USER}:${XRDP_USER} /home/${XRDP_USER}/.xsession && \
    chmod +x /home/${XRDP_USER}/.xsession && \
    apt autoremove --purge -y && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

# Download sample .docx file to view in onlyoffice

RUN mkdir -p /home/${XRDP_USER}/Documents && \
    chown -R ${XRDP_USER}:${XRDP_USER} /home/${XRDP_USER}/Documents && \
    chmod -R 755 /home/${XRDP_USER}/Documents

RUN mkdir -p /etc/fuse.conf.d && \
    echo "user_allow_other" > /etc/fuse.conf && \
    chmod 644 /etc/fuse.conf

RUN apt update && apt install -qqy 7zip squashfs-tools wget && \
    wget -q https://github.com/ONLYOFFICE/appimage-desktopeditors/releases/download/v8.3.3/DesktopEditors-x86_64.AppImage -O /tmp/onlyoffice.AppImage && \
    mkdir -p /opt/onlyoffice && \
    cd /tmp && \
    7z x onlyoffice.AppImage -o/tmp/appimage-extracted -y && \
    if [ -f /tmp/appimage-extracted/*.squashfs ]; then \
        unsquashfs -f -d /opt/onlyoffice/squashfs-root /tmp/appimage-extracted/*.squashfs; \
    else \
        mv /tmp/appimage-extracted /opt/onlyoffice/squashfs-root; \
    fi && \
    chmod +x /opt/onlyoffice/squashfs-root/AppRun && \
    sed -i 's|exec /usr/bin/chromium|/usr/bin/chromium|' /home/${XRDP_USER}/.xsession && \
    echo '/opt/onlyoffice/squashfs-root/AppRun &' >> /home/${XRDP_USER}/.xsession && \
    rm -rf /tmp/onlyoffice.AppImage /tmp/appimage-extracted && \
    apt purge -y 7zip squashfs-tools wget && \
    apt autoremove --purge -y && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

    # No longer need tmux, removing that installationCUSTOM_ENTRYPOINTS_DIR}
# Create necessary directories for supervisor and custom entrypoints
RUN mkdir -p /etc/supervisor.d /app/conf.d ${DEF_CUSTOM_ENTRYPOINTS_DIR}
RUN mkdir -p /var/log/supervisor

# Copy configuration files
COPY supervisord.conf /etc/supervisor.d/supervisord.conf
# only bring in xrdp (and xterm) programs, drop VNC configs
COPY conf.d/xrdp.conf conf.d/xterm.conf /app/conf.d/
COPY base_entrypoint.sh customizable_entrypoint.sh /usr/local/bin/
# Copy agent binary into the image (adjust source path as needed)COPY agent /usr/local/bin/agent
COPY agent /usr/local/bin/agent
RUN chmod +x /usr/local/bin/agent

# Make the entrypoint scripts executableRUN chmod +x /usr/local/bin/base_entrypoint.sh /usr/local/bin/customizable_entrypoint.sh
RUN chmod +x /usr/local/bin/base_entrypoint.sh /usr/local/bin/customizable_entrypoint.sh


# Expose the XRDP port
EXPOSE ${XRDP_PORT}
# Set tini as the entrypoint and the custom script as the commandENTRYPOINT ["/usr/bin/tini", "--"]
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/usr/local/bin/customizable_entrypoint.sh"]
