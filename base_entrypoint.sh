#!/usr/bin/env bash
set -e

# Store the password
if [ "$VNC_PASSWORD" ]; then
    sed -i "s/^\(command.*x11vnc.*\)$/\1 -passwd '$VNC_PASSWORD'/" /app/conf.d/x11vnc.conf
fi

# Set up agent if enabled
if [ "$RUN_AGENT" = "true" ] && [ -f /app/agent ]; then
    cp /app/agent /usr/local/bin/agent
    chmod +x /usr/local/bin/agent
    echo "Agent will be started with X session"
fi

echo "Current XRDP info:"
echo "-----------------"
echo "XRDP Port: ${XRDP_PORT}"
echo "Lang: ${LANG}"
echo "LC All: ${LC_ALL}"
echo "Customize active: ${CUSTOMIZE}"
echo "Custom entrypoints dir: ${CUSTOM_ENTRYPOINTS_DIR}"
echo "Autostart browser: ${AUTO_START_BROWSER}"
echo "Homepage website URL: ${STARTING_WEBSITE_URL}"
echo "Autostart xterm: ${AUTO_START_XTERM}"
echo "Run agent: ${RUN_AGENT}"
echo "-----------------"

# Start Supervisor
exec supervisord -c /etc/supervisor.d/supervisord.conf
