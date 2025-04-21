#!/bin/bash
# Script to apply XRDP fixes

# Make all scripts executable
chmod +x /home/sanjay7178/rdp-onlyoffice/custom_entrypoints_scripts/xrdp_fix.sh
chmod +x /home/sanjay7178/rdp-onlyoffice/start_container.sh

# Display instructions
echo "XRDP fix scripts are now executable."
echo ""
echo "To rebuild and start the container properly, run:"
echo "  ./start_container.sh"
echo ""
echo "This will:"
echo "1. Check for port conflicts and use an alternative port if needed"
echo "2. Build the container with the fixed Dockerfile"
echo "3. Run the container with the XRDP fix script enabled"
