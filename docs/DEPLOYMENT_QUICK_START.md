# Quick Deployment Guide

## Deploy After Pushing to GitHub

```bash
npm run deploy
```

This single command will:
1. SSH to Hetzner server
2. Pull latest changes
3. Install dependencies (if needed)
4. Build the application
5. Restart the service

## First Time Setup: Environment Variables

After deploying the revalidation feature, you need to add environment variables on the server:

```bash
ssh hetzner
cd /var/www/payload/payload-cms
nano .env
```

Add these lines:
```env
PORTFOLIO_REVALIDATE_URL=https://morar.dev/api/revalidate
PORTFOLIO_REVALIDATE_SECRET=your-secret-token-here
```

Generate a secure token:
```bash
openssl rand -base64 32
```

**Important**: Use the same secret token in the portfolio site's `REVALIDATE_SECRET` environment variable.

## Verify Deployment

```bash
# Check service status
ssh hetzner "sudo systemctl status payload-cms.service"

# View logs
ssh hetzner "sudo journalctl -u payload-cms.service -f"
```

## Troubleshooting

If deployment fails, see [DEPLOYMENT.md](./DEPLOYMENT.md) for detailed troubleshooting steps.

