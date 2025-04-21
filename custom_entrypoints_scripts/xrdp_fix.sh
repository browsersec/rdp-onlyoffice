#!/bin/bash
# xrdp_fix.sh - Fix XRDP blank screen issues
set -e  # Exit on error

echo "Starting XRDP fix script..."

# 0. Kill any existing XRDP processes that might be blocking port 3389
echo "Killing any existing XRDP processes..."
pkill -9 xrdp || true
pkill -9 xrdp-sesman || true
pkill -9 Xvfb || true
sleep 2

# 1. Find the correct path for OnlyOffice executables
echo "Finding OnlyOffice executables..."
ONLYOFFICE_PATH=$(find /opt /usr -name "onlyoffice-desktopeditors" -o -name "DesktopEditors" 2>/dev/null | head -1)
if [ -n "$ONLYOFFICE_PATH" ]; then
  echo "Found OnlyOffice at: $ONLYOFFICE_PATH"
  ONLYOFFICE_DIR=$(dirname "$ONLYOFFICE_PATH")
  chmod +x "$ONLYOFFICE_PATH" || true
  echo "OnlyOffice directory: $ONLYOFFICE_DIR"
else
  echo "WARNING: OnlyOffice executable not found"
fi

# 2. Ensure proper permissions for executables (fix exit code 126)
echo "Fixing executable permissions..."
[ -f "$ONLYOFFICE_PATH" ] && chmod +x "$ONLYOFFICE_PATH" || true
[ -f "/usr/bin/xterm" ] && chmod +x /usr/bin/xterm || true
[ -f "/usr/bin/fluxbox" ] && chmod +x /usr/bin/fluxbox || true

# 3. Create needed directories that might be missing
echo "Creating necessary directories..."
mkdir -p /var/run/xrdp
mkdir -p /var/run/xrdp/sockdir
mkdir -p /tmp/.X11-unix
chmod 1777 /tmp/.X11-unix

# 4. Set proper environment variables for X server
echo "Setting up X server environment..."
export DISPLAY=:10
echo "DISPLAY=$DISPLAY" > /etc/environment
echo "export DISPLAY=$DISPLAY" >> /etc/profile
echo "export DISPLAY=$DISPLAY" >> /home/rdpuser/.bashrc
echo "export DISPLAY=$DISPLAY" >> /home/rdpuser/.profile

# 5. Fix the fluxbox window manager configuration
echo "Configuring fluxbox..."
mkdir -p /root/.fluxbox
cat > /root/.fluxbox/startup << EOF
#!/bin/sh
xsetroot -solid grey
xterm &
exec fluxbox
EOF
chmod +x /root/.fluxbox/startup

mkdir -p /home/rdpuser/.fluxbox
cat > /home/rdpuser/.fluxbox/startup << EOF
#!/bin/sh
xsetroot -solid grey
xterm &
exec fluxbox
EOF
chmod +x /home/rdpuser/.fluxbox/startup
chown -R rdpuser:rdpuser /home/rdpuser/.fluxbox

# 6. Create /etc/default/locale if missing
echo "Setting up locale..."
mkdir -p /etc/default
echo "LANG=C.UTF-8" > /etc/default/locale
echo "LC_ALL=C.UTF-8" >> /etc/default/locale

# 7. Modify XRDP configuration to use a different port if 3389 is in use
echo "Configuring XRDP to use alternate port if needed..."
if netstat -tln | grep -q ":3389"; then
  echo "Port 3389 is already in use, using alternative port 3390"
  sed -i 's/port=3389/port=3390/' /etc/xrdp/xrdp.ini
  echo "export XRDP_PORT=3390" >> /etc/profile
  export XRDP_PORT=3390
fi

# 8. Add fluxbox to xsession
echo "Setting up xsession..."
mkdir -p /etc/X11/xinit
cat > /etc/X11/xinit/xinitrc << EOF
#!/bin/sh
# /etc/X11/xinit/xinitrc
if [ -d /etc/X11/xinit/xinitrc.d ]; then
  for f in /etc/X11/xinit/xinitrc.d/*; do
    [ -x "\$f" ] && . "\$f"
  done
  unset f
fi

# Start fluxbox
exec fluxbox
EOF
chmod +x /etc/X11/xinit/xinitrc

# Update the startwm.sh script which is what XRDP actually uses
mkdir -p /etc/xrdp
cat > /etc/xrdp/startwm.sh << EOF
#!/bin/sh
# xrdp X session starter script
if [ -r /etc/default/locale ]; then
  . /etc/default/locale
  export LANG LANGUAGE LC_ALL
fi

# Start up the user's session
if [ -f ~/.xsession ]; then
  . ~/.xsession
else
  exec fluxbox
fi
EOF
chmod +x /etc/xrdp/startwm.sh

# 9. Fix the user's .xsession file with the correct OnlyOffice path
if [ -n "$ONLYOFFICE_PATH" ]; then
  echo "Creating xsession with correct OnlyOffice path: $ONLYOFFICE_PATH"
  cat > /home/rdpuser/.xsession << EOF
#!/bin/sh
# Start fluxbox
export DISPLAY=:10
xsetroot -solid grey
fluxbox &
sleep 2

# Start OnlyOffice with the correct path
exec "$ONLYOFFICE_PATH"
EOF
else
  echo "Creating xsession with fallback to xterm (OnlyOffice not found)"
  cat > /home/rdpuser/.xsession << EOF
#!/bin/sh
# Start fluxbox
export DISPLAY=:10
xsetroot -solid grey
fluxbox &
sleep 2

# Fallback to xterm (OnlyOffice not found)
exec xterm
EOF
fi

chmod +x /home/rdpuser/.xsession
chown rdpuser:rdpuser /home/rdpuser/.xsession

# 10. Fix xrdp.ini for improved reliability
cat > /etc/xrdp/xrdp.ini << EOF
[Globals]
ini_version=1
fork=true
port=${XRDP_PORT:-3389}
tcp_nodelay=true
tcp_keepalive=true
security_layer=negotiate
crypt_level=high
certificate=
key_file=
ssl_protocols=TLSv1.2, TLSv1.3
autorun=xrdp1

[Logging]
LogFile=xrdp.log
LogLevel=DEBUG
EnableSyslog=true
SyslogLevel=DEBUG

[Channels]
rdpdr=true
rdpsnd=true
drdynvc=true
cliprdr=true
rail=true
xrdpvr=true
tcutils=true

[xrdp1]
name=sesman-Xorg
lib=libxup.so
username=ask
password=ask
ip=127.0.0.1
port=-1
code=20
EOF

# 11. Start the xrdp services one by one, with error handling
echo "Starting XRDP services..."
/usr/sbin/xrdp-sesman &
SESMAN_PID=$!
sleep 2
if ! ps -p $SESMAN_PID > /dev/null; then
  echo "ERROR: xrdp-sesman failed to start, checking logs..."
  tail -n 20 /var/log/xrdp-sesman.log || true
fi

# Start xrdp in the background to avoid hanging the script
/usr/sbin/xrdp --nodaemon &
XRDP_PID=$!
sleep 2
if ! ps -p $XRDP_PID > /dev/null; then
  echo "ERROR: xrdp failed to start, checking logs..."
  tail -n 20 /var/log/xrdp.log || true
fi

# Return instead of hanging on xrdp
echo "XRDP fix script completed. RDP should be available on port ${XRDP_PORT:-3389}"
