# CMS Deployment Guide

## Quick Deploy

After pushing changes to GitHub, deploy to Hetzner server:

```bash
npm run deploy
```

This will:
1. SSH to Hetzner server
2. Pull latest changes from Git
3. Install dependencies (if needed)
4. Build the application
5. Restart the service
6. Show service status

## Manual Deployment Steps

### 1. SSH to Server

```bash
ssh hetzner
```

### 2. Navigate to CMS Directory

```bash
cd /var/www/payload/payload-cms
```

### 3. Pull Latest Changes

```bash
git pull
```

### 4. Install Dependencies (if needed)

Only required if `package.json` or `package-lock.json` changed:

```bash
npm install
```

Check if needed:
```bash
git diff HEAD~1 --name-only | grep -E "(package\.json|package-lock\.json)"
```

### 5. Update Environment Variables (if needed)

Edit `/var/www/payload/payload-cms/.env`:

```bash
nano .env
```

Add or update:
```env
# Portfolio site revalidation (required for revalidation feature)
PORTFOLIO_REVALIDATE_URL=https://morar.dev/api/revalidate
PORTFOLIO_REVALIDATE_SECRET=your-secret-token-here
```

**Important**: 
- Use the same secret token as portfolio site's `REVALIDATE_SECRET`
- Generate secure token: `openssl rand -base64 32`
- For production, use `https://morar.dev/api/revalidate`

### 6. Build Application

```bash
npm run build
```

This creates the production bundle in `.next` directory.

### 7. Restart Service

```bash
sudo systemctl restart payload-cms.service
```

### 8. Verify Deployment

```bash
# Check service status
sudo systemctl status payload-cms.service

# View logs
sudo journalctl -u payload-cms.service -f
```

## Verification Checklist

After deployment, verify:

- [ ] Service status shows `active (running)`
- [ ] No errors in service logs
- [ ] CMS admin panel accessible at `https://cms.morar.dev/admin`
- [ ] API endpoints working: `https://cms.morar.dev/api/posts`
- [ ] Test revalidation: Edit a post, save, check logs for "Portfolio revalidation successful"

## Troubleshooting

### Build Fails

```bash
# Clear build cache
rm -rf .next

# Reinstall dependencies
rm -rf node_modules package-lock.json
npm install

# Try build again
npm run build
```

### Service Won't Start

```bash
# Check service status
sudo systemctl status payload-cms.service

# View detailed logs
sudo journalctl -u payload-cms.service -n 50 -f

# Check MongoDB connection
mongosh mongodb://127.0.0.1:27017/payload-cms
```

### Revalidation Not Working

1. Verify environment variables:
   ```bash
   cat /var/www/payload/payload-cms/.env | grep PORTFOLIO
   ```

2. Check CMS logs:
   ```bash
   sudo journalctl -u payload-cms.service -f | grep revalidation
   ```

3. Verify portfolio site has matching `REVALIDATE_SECRET`

### Git Pull Fails

```bash
# Check for uncommitted changes
git status

# Stash changes if needed
git stash

# Pull again
git pull

# Restore stashed changes if needed
git stash pop
```

## Environment Variables Reference

### Required for Basic Operation

```env
DATABASE_URL=mongodb://127.0.0.1:27017/payload-cms
PAYLOAD_SECRET=<generated-secret>
NEXT_PUBLIC_SERVER_URL=https://cms.morar.dev
CRON_SECRET=<generated-secret>
PREVIEW_SECRET=<generated-secret>
NODE_ENV=production
```

### Required for Revalidation Feature

```env
PORTFOLIO_REVALIDATE_URL=https://morar.dev/api/revalidate
PORTFOLIO_REVALIDATE_SECRET=<shared-secret-token>
```

## Deployment Script

The deployment script (`scripts/deploy.sh`) automates the deployment process:

- Pulls latest Git changes
- Conditionally installs dependencies (only if package files changed)
- Builds the application
- Restarts the service
- Shows service status

Run it locally:
```bash
npm run deploy
```

Or manually on server:
```bash
cd /var/www/payload/payload-cms
./scripts/deploy.sh
```

## Related Documentation

- [ARCHITECTURE.md](./ARCHITECTURE.md) - System architecture and setup
- [REVALIDATION.md](./REVALIDATION.md) - Revalidation system details

