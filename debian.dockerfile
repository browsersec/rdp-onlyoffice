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
    lxde-core \
    lxsession \
    lxde-common \
    openbox \
    file-roller \
    xterm \
    shotwell \
    okular \
    vlc \
    mousepad \
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
    ca-certificates \
    dbus-x11 && \
    # User setup remains the same
    useradd -m -s /bin/bash "${XRDP_USER}" && \
    echo "${XRDP_USER}:${XRDP_PASSWORD}" | chpasswd && \
    adduser ${XRDP_USER} fuse && \
    chmod u+s /bin/fusermount && \
    # Create LXDE configuration to disable bottom panel
    mkdir -p /home/${XRDP_USER}/.config/lxpanel/LXDE/panels && \
    # Create a simple .xsession with proper LXDE startup
    echo '#!/bin/sh' > /home/${XRDP_USER}/.xsession && \
    echo '# Start D-Bus if not running' >> /home/${XRDP_USER}/.xsession && \
    echo 'if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then' >> /home/${XRDP_USER}/.xsession && \
    echo '  eval $(dbus-launch --sh-syntax --exit-with-session)' >> /home/${XRDP_USER}/.xsession && \
    echo 'fi' >> /home/${XRDP_USER}/.xsession && \
    echo 'exec startlxde' >> /home/${XRDP_USER}/.xsession && \
    echo '/usr/local/bin/agent &' >> /home/${XRDP_USER}/.xsession && \
    # Disable bottom panel by creating empty panel config
    echo "# Empty panel configuration" > /home/${XRDP_USER}/.config/lxpanel/LXDE/panels/panel && \
    # Ensure proper permissions
    chown -R ${XRDP_USER}:${XRDP_USER} /home/${XRDP_USER}/.config && \
    chown ${XRDP_USER}:${XRDP_USER} /home/${XRDP_USER}/.xsession && \
    chmod +x /home/${XRDP_USER}/.xsession && \
    # Only remove truly unnecessary LXDE components
    apt-get remove -y lxappearance lxinput lxrandr lxsession-edit && \
    # Disable the LXDE taskbar by modifying the autostart file
    mkdir -p /etc/xdg/lxsession/LXDE && \
    if [ -f /etc/xdg/lxsession/LXDE/autostart ]; then \
        sed -i 's/@lxpanel --profile LXDE/#@lxpanel --profile LXDE/' /etc/xdg/lxsession/LXDE/autostart; \
        sed -i 's/@pcmanfm --desktop --profile LXDE/#@pcmanfm --desktop --profile LXDE/' /etc/xdg/lxsession/LXDE/autostart; \
    else \
        echo "@lxsession" > /etc/xdg/lxsession/LXDE/autostart && \
        echo "#@lxpanel --profile LXDE" >> /etc/xdg/lxsession/LXDE/autostart && \
        echo "@pcmanfm --desktop --profile LXDE" >> /etc/xdg/lxsession/LXDE/autostart && \
        echo "@xscreensaver -no-splash" >> /etc/xdg/lxsession/LXDE/autostart; \
    fi && \
    apt autoremove --purge -y && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

RUN apt --purge remove pcmanfm xterm  && \
    apt --purge remove --auto-remove -y && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*


# Download sample .docx file to view in onlyoffice

RUN mkdir -p /home/${XRDP_USER}/Documents && \
    chown -R ${XRDP_USER}:${XRDP_USER} /home/${XRDP_USER}/Documents && \
    chmod -R 755 /home/${XRDP_USER}/Documents

RUN mkdir -p /etc/fuse.conf.d && \
    echo "user_allow_other" > /etc/fuse.conf && \
    chmod 644 /etc/fuse.conf

RUN wget https://github.com/ONLYOFFICE/appimage-desktopeditors/releases/download/v8.3.3/DesktopEditors-x86_64.AppImage -O /usr/local/bin/onlyoffice.AppImage && \ 
    chmod +x /usr/local/bin/onlyoffice.AppImage && \ 
    mkdir -p /opt/onlyoffice && \
    cd /opt/onlyoffice && \
    /usr/local/bin/onlyoffice.AppImage --appimage-extract && \
    chmod +x /opt/onlyoffice/squashfs-root/AppRun && \
    # Don't use exec for this command, so it won't terminate the session
    sed -i 's|exec /usr/bin/chromium|/usr/bin/chromium|' /home/${XRDP_USER}/.xsession && \
    # Add OnlyOffice to start after Chromium, but without exect as root separately
    echo '/opt/onlyoffice/squashfs-root/AppRun &' >> /home/${XRDP_USER}/.xsession && \
    # Remove the tmux-based agent execution line - we'll run it as root separately
    rm -rf /usr/local/bin/onlyoffice.AppImagetion

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