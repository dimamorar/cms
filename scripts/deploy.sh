#!/bin/bash

# Deploy CMS to Hetzner Server
# This script pulls latest changes, builds, and restarts the CMS service
#
# Usage: ./scripts/deploy.sh
# Or: ssh hetzner "bash -s" < scripts/deploy.sh

set -e  # Exit on error

echo "🚀 Starting CMS deployment to Hetzner..."

# Navigate to CMS directory
cd /var/www/payload/payload-cms || {
  echo "❌ Error: Could not find /var/www/payload/payload-cms"
  echo "   Make sure you're running this on the Hetzner server"
  exit 1
}

echo "📦 Pulling latest changes from Git..."
# Ensure git remote uses HTTPS (works without SSH keys)
git remote set-url origin https://github.com/dimamorar/cms.git 2>/dev/null || true
git pull

echo "📥 Checking if dependencies need updating..."
# Check if package.json or package-lock.json changed
if git diff HEAD~1 --name-only | grep -qE "(package\.json|package-lock\.json)"; then
  echo "   Dependencies changed, installing..."
  npm install
else
  echo "   No dependency changes, skipping npm install"
fi

echo "🔨 Building application..."
npm run build

echo "🔄 Restarting service..."
sudo systemctl restart payload-cms.service

echo "✅ Deployment complete!"
echo ""
echo "📊 Checking service status..."
sudo systemctl status payload-cms.service --no-pager -l

echo ""
echo "💡 To view logs: sudo journalctl -u payload-cms.service -f"
echo "💡 To verify revalidation env vars: cat .env | grep PORTFOLIO"

