#!/usr/bin/env bash
set -e

# Store the password
if [ "$VNC_PASSWORD" ]; then
    sed -i "s/^\(command.*x11vnc.*\)$/\1 -passwd '$VNC_PASSWORD'/" /app/conf.d/x11vnc.conf
fi


# Set up agent if enabled
if [ "$RUN_AGENT" = "true" ]; then
    if [ -f /app/agent ]; then
        cp /app/agent /usr/local/bin/agent
        chmod +x /usr/local/bin/agent
        echo "Agent will be started with X session (from /app/agent)"
    elif [ -x /usr/local/bin/agent ]; then
        echo "Agent will be started with X session (using existing /usr/local/bin/agent)"
    else
        echo "Warning: RUN_AGENT is set to true but no agent was found"
    fi
fi

echo "Current XRDP info:"
echo "-----------------"
echo "XRDP Port: ${XRDP_PORT}"
echo "Lang: ${LANG}"
echo "LC All: ${LC_ALL}"
echo "Customize active: ${CUSTOMIZE}"
echo "Custom entrypoints dir: ${CUSTOM_ENTRYPOINTS_DIR}"
echo "Autostart xterm: ${AUTO_START_XTERM}"
echo "Run agent: ${RUN_AGENT}"
echo "-----------------"

# Ensure agent is running if enabled
if [ "$RUN_AGENT" = "true" ] && [ -x /usr/local/bin/agent ]; then
    echo "Starting agent service..."
    # Create a supervisor config for the agent
    cat > /etc/supervisor.d/agent.conf <<EOF
[program:agent]
command=/usr/local/bin/agent
autostart=true
autorestart=true
user=${XRDP_USER}
environment=HOME="/home/${XRDP_USER}",USER="${XRDP_USER}"
EOF
    echo "Agent service configured to start automatically"
fi

# Start Supervisor
exec supervisord -c /etc/supervisor.d/supervisord.conf
