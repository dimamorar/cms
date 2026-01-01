#!/bin/bash

# SSH Tunnel to Hetzner MongoDB
# This script creates an SSH tunnel to forward local MongoDB port to remote Hetzner server
# Usage: ./scripts/tunnel-mongodb.sh
#
# Prerequisites:
# - SSH config with 'hetzner' host alias (recommended)
# - Or update HETZNER_HOST and HETZNER_USER below
#
# SSH Config example (~/.ssh/config):
#   Host hetzner
#       HostName 77.42.17.21
#       User morar
#       IdentityFile ~/.ssh/id_rsa

# Configuration
# Option 1: Use SSH config alias (recommended)
SSH_HOST="hetzner"

# Option 2: Use direct connection (uncomment and update if not using SSH config)
# HETZNER_USER="morar"
# HETZNER_HOST="77.42.17.21"
# HETZNER_SSH_PORT="22"
# SSH_KEY_PATH="~/.ssh/id_rsa"

REMOTE_MONGODB_PORT="27017"
LOCAL_MONGODB_PORT="27017"

# Check if tunnel already exists
if pgrep -f "27017:127.0.0.1:27017" > /dev/null; then
    echo "SSH tunnel already running. Kill existing tunnel first:"
    echo "  pkill -f '27017:127.0.0.1:27017'"
    exit 1
fi

# Create SSH tunnel
echo "Creating SSH tunnel to Hetzner MongoDB..."
echo "Local port: $LOCAL_MONGODB_PORT -> Remote: 127.0.0.1:$REMOTE_MONGODB_PORT"
echo "Press Ctrl+C to stop the tunnel"
echo ""

# Use SSH config alias if available, otherwise use direct connection
if [ -n "$SSH_HOST" ]; then
    ssh -N -L ${LOCAL_MONGODB_PORT}:127.0.0.1:${REMOTE_MONGODB_PORT} ${SSH_HOST}
else
    ssh -N -L ${LOCAL_MONGODB_PORT}:127.0.0.1:${REMOTE_MONGODB_PORT} \
        -p ${HETZNER_SSH_PORT} \
        -i ${SSH_KEY_PATH} \
        ${HETZNER_USER}@${HETZNER_HOST}
fi

echo ""
echo "SSH tunnel closed."

