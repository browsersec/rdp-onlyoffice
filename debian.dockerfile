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
      xfce4 \
      dbus-x11 \
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
      ca-certificates && \
    # User setup remains the same
    useradd -m -s /bin/bash "${XRDP_USER}" && \
    echo "${XRDP_USER}:${XRDP_PASSWORD}" | chpasswd && \
    adduser ${XRDP_USER} fuse && \
    chmod u+s /bin/fusermount && \
    # Setup XFCE in minimal headless mode (no panels, no UI elements)
    rm -f /home/${XRDP_USER}/.xsession && \
    echo '#!/bin/bash' > /home/${XRDP_USER}/.xsession && \
    echo 'export XDG_CURRENT_DESKTOP=XFCE' >> /home/${XRDP_USER}/.xsession && \
    echo 'dbus-launch xfwm4 &' >> /home/${XRDP_USER}/.xsession && \
    echo 'dbus-launch xfdesktop &' >> /home/${XRDP_USER}/.xsession && \
    echo '/usr/local/bin/agent &' >> /home/${XRDP_USER}/.xsession && \
    echo 'exec sleep infinity' >> /home/${XRDP_USER}/.xsession && \
    chmod +x /home/${XRDP_USER}/.xsession && \
    # Create XFCE minimal config
    mkdir -p /home/${XRDP_USER}/.config/xfce4/xfconf/xfce-perchannel-xml && \
    echo '<?xml version="1.0" encoding="UTF-8"?><channel name="xfce4-panel" version="1.0"><property name="panels" type="empty"/></channel>' > /home/${XRDP_USER}/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml && \
    echo '<?xml version="1.0" encoding="UTF-8"?><channel name="xfce4-desktop" version="1.0"><property name="backdrop" type="empty"><property name="screen0" type="empty"><property name="monitor0" type="empty"><property name="image-path" type="string" value="none"/><property name="last-image" type="string" value="none"/><property name="last-single-image" type="string" value="none"/></property></property></property></channel>' > /home/${XRDP_USER}/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml && \
    echo '<?xml version="1.0" encoding="UTF-8"?><channel name="xfwm4" version="1.0"><property name="general" type="empty"><property name="use_compositing" type="bool" value="false"/></property></channel>' > /home/${XRDP_USER}/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml && \
    chown -R ${XRDP_USER}:${XRDP_USER} /home/${XRDP_USER}/.config && \
    chown ${XRDP_USER}:${XRDP_USER} /home/${XRDP_USER}/.xsession && \
    chmod +x /home/${XRDP_USER}/.xsession && \
    apt autoremove --purge -y && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

RUN apt-get remove -y \
    thunar \
    xfce4-appfinder \
    xfce4-panel \
    xfce4-session \
    xfce4-settings \
    xfconf && 

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
    # Set OnlyOffice as the default application for office files
    # mkdir -p /home/${XRDP_USER}/.config && \
    # mkdir -p /home/${XRDP_USER}/.local/share/applications && \
    # echo '[Desktop Entry]' > /home/${XRDP_USER}/.local/share/applications/onlyoffice.desktop && \
    # echo 'Type=Application' >> /home/${XRDP_USER}/.local/share/applications/onlyoffice.desktop && \
    # echo 'Name=OnlyOffice' >> /home/${XRDP_USER}/.local/share/applications/onlyoffice.desktop && \
    # echo 'Exec=/opt/onlyoffice/squashfs-root/AppRun %f' >> /home/${XRDP_USER}/.local/share/applications/onlyoffice.desktop && \
    # echo 'Icon=/opt/onlyoffice/squashfs-root/usr/share/icons/hicolor/256x256/apps/asc-de.png' >> /home/${XRDP_USER}/.local/share/applications/onlyoffice.desktop && \
    # echo 'MimeType=application/vnd.openxmlformats-officedocument.wordprocessingml.document;application/vnd.openxmlformats-officedocument.spreadsheetml.sheet;application/vnd.openxmlformats-officedocument.presentationml.presentation;application/msword;application/vnd.ms-excel;application/vnd.ms-powerpoint;application/vnd.oasis.opendocument.text;application/vnd.oasis.opendocument.spreadsheet;application/vnd.oasis.opendocument.presentation;application/rtf;text/plain;application/pdf;' >> /home/${XRDP_USER}/.local/share/applications/onlyoffice.desktop && \
    # echo 'Categories=Office;' >> /home/${XRDP_USER}/.local/share/applications/onlyoffice.desktop && \
    # echo '[Added Associations]' > /home/${XRDP_USER}/.config/mimeapps.list && \
    # echo 'application/vnd.openxmlformats-officedocument.wordprocessingml.document=onlyoffice.desktop;' >> /home/${XRDP_USER}/.config/mimeapps.list && \
    # echo 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet=onlyoffice.desktop;' >> /home/${XRDP_USER}/.config/mimeapps.list && \
    # echo 'application/vnd.openxmlformats-officedocument.presentationml.presentation=onlyoffice.desktop;' >> /home/${XRDP_USER}/.config/mimeapps.list && \
    # echo 'application/msword=onlyoffice.desktop;' >> /home/${XRDP_USER}/.config/mimeapps.list && \
    # echo 'application/vnd.ms-excel=onlyoffice.desktop;' >> /home/${XRDP_USER}/.config/mimeapps.list && \
    # echo 'application/vnd.ms-powerpoint=onlyoffice.desktop;' >> /home/${XRDP_USER}/.config/mimeapps.list && \
    # echo 'application/vnd.oasis.opendocument.text=onlyoffice.desktop;' >> /home/${XRDP_USER}/.config/mimeapps.list && \
    # echo 'application/vnd.oasis.opendocument.spreadsheet=onlyoffice.desktop;' >> /home/${XRDP_USER}/.config/mimeapps.list && \
    # echo 'application/vnd.oasis.opendocument.presentation=onlyoffice.desktop;' >> /home/${XRDP_USER}/.config/mimeapps.list && \
    # echo 'application/rtf=onlyoffice.desktop;' >> /home/${XRDP_USER}/.config/mimeapps.list && \
    # echo 'text/plain=onlyoffice.desktop;' >> /home/${XRDP_USER}/.config/mimeapps.list && \
    # echo 'application/pdf=onlyoffice.desktop;' >> /home/${XRDP_USER}/.config/mimeapps.list && \
    # echo '[Default Applications]' >> /home/${XRDP_USER}/.config/mimeapps.list && \
    # echo 'application/vnd.openxmlformats-officedocument.wordprocessingml.document=onlyoffice.desktop' >> /home/${XRDP_USER}/.config/mimeapps.list && \
    # echo 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet=onlyoffice.desktop' >> /home/${XRDP_USER}/.config/mimeapps.list && \
    # echo 'application/vnd.openxmlformats-officedocument.presentationml.presentation=onlyoffice.desktop' >> /home/${XRDP_USER}/.config/mimeapps.list && \
    # echo 'application/msword=onlyoffice.desktop' >> /home/${XRDP_USER}/.config/mimeapps.list && \
    # echo 'application/vnd.ms-excel=onlyoffice.desktop' >> /home/${XRDP_USER}/.config/mimeapps.list && \
    # echo 'application/vnd.ms-powerpoint=onlyoffice.desktop' >> /home/${XRDP_USER}/.config/mimeapps.list && \
    # echo 'application/vnd.oasis.opendocument.text=onlyoffice.desktop' >> /home/${XRDP_USER}/.config/mimeapps.list && \
    # echo 'application/vnd.oasis.opendocument.spreadsheet=onlyoffice.desktop' >> /home/${XRDP_USER}/.config/mimeapps.list && \
    # echo 'application/vnd.oasis.opendocument.presentation=onlyoffice.desktop' >> /home/${XRDP_USER}/.config/mimeapps.list && \
    # echo 'application/rtf=onlyoffice.desktop' >> /home/${XRDP_USER}/.config/mimeapps.list && \
    # echo 'text/plain=onlyoffice.desktop' >> /home/${XRDP_USER}/.config/mimeapps.list && \
    # echo 'application/pdf=onlyoffice.desktop' >> /home/${XRDP_USER}/.config/mimeapps.list && \
    # chown -R ${XRDP_USER}:${XRDP_USER} /home/${XRDP_USER}/.config /home/${XRDP_USER}/.local && \
    # Remove the tmux-based agent execution line - we'll run it as root separately
    rm -rf /usr/local/bin/onlyoffice.AppImage

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