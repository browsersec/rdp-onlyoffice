#!/bin/bash
# xrdp_fix.sh - Fix XRDP blank screen issues
set -e  # Exit on error

echo "Starting XRDP fix script..."

# 1. Ensure proper permissions for executables (fix exit code 126)
echo "Fixing executable permissions..."
chmod +x /usr/bin/onlyoffice-desktopeditors || true
chmod +x /usr/bin/DesktopEditors || true
chmod +x /usr/bin/xterm || true
chmod +x /usr/bin/fluxbox || true

# 2. Create needed directories that might be missing
echo "Creating necessary directories..."
mkdir -p /var/run/xrdp
mkdir -p /var/run/xrdp/sockdir
mkdir -p /tmp/.X11-unix
chmod 1777 /tmp/.X11-unix

# 3. Set proper environment variables for X server
echo "Setting up X server environment..."
export DISPLAY=:10
echo "DISPLAY=$DISPLAY" > /etc/environment
echo "export DISPLAY=$DISPLAY" >> /etc/profile
echo "export DISPLAY=$DISPLAY" >> /home/rdpuser/.bashrc
echo "export DISPLAY=$DISPLAY" >> /home/rdpuser/.profile

# 4. Fix the fluxbox window manager configuration
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

# 5. Create /etc/default/locale if missing
echo "Setting up locale..."
mkdir -p /etc/default
echo "LANG=C.UTF-8" > /etc/default/locale
echo "LC_ALL=C.UTF-8" >> /etc/default/locale

# 6. Add fluxbox to xsession
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

# 7. Fix the user's .xsession file
cat > /home/rdpuser/.xsession << EOF
#!/bin/sh
# Start fluxbox
export DISPLAY=:10
xsetroot -solid grey
fluxbox &
sleep 2

# Start OnlyOffice
ONLYOFFICE_BIN=\$(which onlyoffice-desktopeditors DesktopEditors 2>/dev/null | head -1)
if [ -z "\$ONLYOFFICE_BIN" ]; then
  ONLYOFFICE_BIN=\$(find /opt /usr/bin -name "onlyoffice-desktopeditors" -o -name "DesktopEditors" 2>/dev/null | head -1)
fi

if [ -n "\$ONLYOFFICE_BIN" ]; then
  exec "\$ONLYOFFICE_BIN"
else
  # Fallback to xterm if OnlyOffice not found
  exec xterm
fi
EOF
chmod +x /home/rdpuser/.xsession
chown rdpuser:rdpuser /home/rdpuser/.xsession

# 8. Fix xrdp.ini if needed
cat > /etc/xrdp/xrdp.ini << EOF
[Globals]
ini_version=1
fork=true
port=3389
tcp_nodelay=true
tcp_keepalive=true
security_layer=negotiate
crypt_level=high
certificate=
key_file=
ssl_protocols=TLSv1.2, TLSv1.3
autorun=

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

[Xorg]
name=Xorg
lib=libxup.so
username=ask
password=ask
ip=127.0.0.1
port=-1
code=20

[Xvnc]
name=Xvnc
lib=libvnc.so
username=ask
password=ask
ip=127.0.0.1
port=-1
xserverbpp=24
EOF

# 9. Restart the xrdp services
echo "Restarting XRDP services..."
pkill -9 xrdp || true
pkill -9 xrdp-sesman || true
pkill -9 Xvfb || true

sleep 2

# Start the services again
echo "Starting XRDP services..."
/usr/sbin/xrdp-sesman &
sleep 1
/usr/sbin/xrdp --nodaemon &

echo "XRDP fix script completed."
