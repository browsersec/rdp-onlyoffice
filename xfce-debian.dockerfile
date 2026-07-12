FROM debian:stable-slim

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
ARG DEF_RUN_AGENT=true
ENV XRDP_USER=${DEF_XRDP_USER} XRDP_PASSWORD=${DEF_XRDP_PASSWORD}

ENV \
    STARTING_WEBSITE_URL=${DEF_STARTING_WEBSITE_URL} \
    LANG=${DEF_LANG} \
    LC_ALL=${DEF_LC_ALL} \
    CUSTOMIZE=${DEF_CUSTOMIZE} \
    CUSTOM_ENTRYPOINTS_DIR=${DEF_CUSTOM_ENTRYPOINTS_DIR} \
    AUTO_START_BROWSER=${DEF_AUTO_START_BROWSER} \
    AUTO_START_XTERM=${DEF_AUTO_START_XTERM} \
    DEBIAN_FRONTEND=${DEF_DEBIAN_FRONTEND} \
    XRDP_PORT=${DEF_XRDP_PORT} \
    RUN_AGENT=${DEF_RUN_AGENT}

RUN groupadd fuse

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
    xfce4-terminal \
    file-roller \
    okular \
    vlc \
    gedit \
    eog \
    wget \
    nano \
    fuse \
    libfuse2 \
    libxkbcommon-x11-0 \
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
    useradd -m -s /bin/bash "${XRDP_USER}" && \
    echo "${XRDP_USER}:${XRDP_PASSWORD}" | chpasswd && \
    adduser ${XRDP_USER} fuse && \
    chmod u+s /bin/fusermount && \
    echo '#!/bin/sh' > /home/${XRDP_USER}/.xsession && \
    echo 'if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then' >> /home/${XRDP_USER}/.xsession && \
    echo '  eval $(dbus-launch --sh-syntax --exit-with-session)' >> /home/${XRDP_USER}/.xsession && \
    echo 'fi' >> /home/${XRDP_USER}/.xsession && \
    echo '/usr/local/bin/agent &' >> /home/${XRDP_USER}/.xsession && \
    echo 'exec startxfce4' >> /home/${XRDP_USER}/.xsession && \
    chown ${XRDP_USER}:${XRDP_USER} /home/${XRDP_USER}/.xsession && \
    chmod +x /home/${XRDP_USER}/.xsession && \
    mkdir -p /home/${XRDP_USER}/.config/xfce4/xfconf/xfce-perchannel-xml && \
    echo '<?xml version="1.0" encoding="UTF-8"?>' > /home/${XRDP_USER}/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml && \
    echo '<channel name="xfce4-panel" version="1.0">' >> /home/${XRDP_USER}/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml && \
    echo '  <property name="panels" type="uint" value="0"/>' >> /home/${XRDP_USER}/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml && \
    echo '</channel>' >> /home/${XRDP_USER}/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml && \
    chown -R ${XRDP_USER}:${XRDP_USER} /home/${XRDP_USER}/.config && \
    apt-get remove -y xfce4-power-manager light-locker xfce4-screensaver || true && \
    apt autoremove --purge -y && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /home/${XRDP_USER}/Documents && \
    chown -R ${XRDP_USER}:${XRDP_USER} /home/${XRDP_USER}/Documents && \
    chmod -R 755 /home/${XRDP_USER}/Documents

RUN mkdir -p /etc/fuse.conf.d && \
    echo "user_allow_other" > /etc/fuse.conf && \
    chmod 644 /etc/fuse.conf

COPY agent /usr/local/bin/agent
RUN chmod +x /usr/local/bin/agent

RUN apt update && apt install -qqy squashfs-tools wget && \
    wget -q https://github.com/ONLYOFFICE/appimage-desktopeditors/releases/download/v8.3.3/DesktopEditors-x86_64.AppImage -O /tmp/onlyoffice.AppImage && \
    mkdir -p /opt/onlyoffice && \
    OFFSET=$(grep -oba 'hsqs' /tmp/onlyoffice.AppImage | head -1 | cut -d: -f1) && \
    unsquashfs -f -d /opt/onlyoffice/squashfs-root -o $OFFSET /tmp/onlyoffice.AppImage && \
    chmod +x /opt/onlyoffice/squashfs-root/AppRun && \
    echo '/opt/onlyoffice/squashfs-root/AppRun &' >> /home/${XRDP_USER}/.xsession && \
    rm -f /tmp/onlyoffice.AppImage && \
    apt purge -y squashfs-tools wget && \
    apt autoremove --purge -y && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/supervisor.d /app/conf.d ${DEF_CUSTOM_ENTRYPOINTS_DIR} && \
    mkdir -p /var/log/supervisor

COPY supervisord.conf /etc/supervisor.d/supervisord.conf
COPY conf.d/xrdp.conf /app/conf.d/
COPY base_entrypoint.sh customizable_entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/base_entrypoint.sh /usr/local/bin/customizable_entrypoint.sh

COPY wallpaper.jpg /home/${XRDP_USER}/Pictures/wallpaper.jpg

EXPOSE ${XRDP_PORT}
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/usr/local/bin/customizable_entrypoint.sh"]
