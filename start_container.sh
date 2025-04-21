#!/bin/bash
# Script to properly start the container with XRDP

# Check if port 3389 is already in use
if netstat -tln | grep -q ":3389"; then
  echo "WARNING: Port 3389 is already in use!"
  echo "Using alternative port 3390 for RDP connection."
  CONTAINER_PORT=3390
else
  CONTAINER_PORT=3389
fi

# Create or modify the .env file with the port
cat > .env << EOF
XRDP_PORT=$CONTAINER_PORT
CUSTOMIZE=true
EOF

echo "Starting container with RDP on port $CONTAINER_PORT..."
echo "You can connect to the container using: YOUR_IP:$CONTAINER_PORT"
echo "Username: rdpuser"
echo "Password: money4band"
echo ""

# Use the fixed Dockerfile
docker build -t rdp-onlyoffice:fixed -f fixed_debian.dockerfile .

# Run the container with proper port mapping and environment variables
docker run -d --name rdp-onlyoffice \
  -p $CONTAINER_PORT:$CONTAINER_PORT \
  --env-file .env \
  rdp-onlyoffice:fixed

echo "Container started. Check logs with: docker logs rdp-onlyoffice"
