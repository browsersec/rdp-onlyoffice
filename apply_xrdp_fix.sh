#!/bin/bash
# Script to apply XRDP fixes

# Make the fix script executable
chmod +x /home/sanjay7178/rdp-onlyoffice/custom_entrypoints_scripts/xrdp_fix.sh

# Enable customization in the environment to ensure the fix script is run
export CUSTOMIZE=true

# Set the proper environment variables for XRDP
echo "Setting environment variables..."
export DISPLAY=:10
export XRDP_PORT=3389
export LANG=en_US.UTF-8
export LC_ALL=C.UTF-8

# Apply the fix directly
echo "Running XRDP fix script..."
bash /home/sanjay7178/rdp-onlyoffice/custom_entrypoints_scripts/xrdp_fix.sh

echo "XRDP fix script has been applied successfully."
echo "Please rebuild your Docker container with the updated configuration."
echo ""
echo "To rebuild, run:"
echo "  docker build -t rdp-onlyoffice:fixed -f fixed_debian.dockerfile ."
echo "  docker run -p 3389:3389 -e CUSTOMIZE=true rdp-onlyoffice:fixed"
