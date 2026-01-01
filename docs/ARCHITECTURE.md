# Payload CMS Architecture & Deployment

## Overview

This Payload CMS project uses the **Website Template** which integrates Next.js frontend with Payload CMS backend in a single application. It's deployed on Hetzner server and accessible at `https://cms.morar.dev`.

## Architecture

### System Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Hetzner Server                       │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Caddy Reverse Proxy (Port 80/443)              │  │
│  │  Domain: cms.morar.dev                          │  │
│  └──────────────┬───────────────────────────────────┘  │
│                 │                                       │
│  ┌──────────────▼───────────────────────────────────┐  │
│  │  Payload CMS (Next.js App)                      │  │
│  │  Port: 3000 (localhost only)                    │  │
│  │  Service: payload-cms.service (systemd)         │  │
│  └──────────────┬───────────────────────────────────┘  │
│                 │                                       │
│  ┌──────────────▼───────────────────────────────────┐  │
│  │  MongoDB 8.0                                    │  │
│  │  Port: 27017 (localhost only)                   │  │
│  │  Database: payload-cms                          │  │
│  └─────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│              Local Development Machine                  │
│  ┌──────────────────────────────────────────────────┐  │
│  │  SSH Tunnel                                      │  │
│  │  Local:27017 → Hetzner:27017                    │  │
│  └──────────────┬───────────────────────────────────┘  │
│                 │                                       │
│  ┌──────────────▼───────────────────────────────────┐  │
│  │  Payload CMS (Local Dev)                        │  │
│  │  Port: 3001                                      │  │
│  │  Path: /Users/apple/Projects/5.1_cms            │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

### Technology Stack

- **Payload CMS**: 3.69.0
- **Next.js**: 15.4.10
- **Node.js**: 22.21.0
- **MongoDB**: 8.0.17
- **Template**: Website Template (Next.js + Payload integrated)
- **Reverse Proxy**: Caddy (automatic SSL)

### Project Structure

```
5.1_cms/
├── src/
│   ├── app/
│   │   ├── (frontend)/      # Next.js frontend routes
│   │   │   ├── page.tsx     # Home page
│   │   │   ├── posts/       # Blog posts
│   │   │   └── [slug]/      # Dynamic pages
│   │   └── (payload)/       # Payload admin routes
│   │       ├── admin/        # Admin panel
│   │       └── api/          # REST & GraphQL API
│   ├── collections/         # Payload collections
│   │   ├── Posts.ts
│   │   ├── Pages.ts
│   │   ├── Media.ts
│   │   ├── Categories.ts
│   │   └── Users.ts
│   ├── globals/             # Global configurations
│   │   ├── Header/
│   │   └── Footer/
│   ├── components/          # React components
│   ├── blocks/              # Layout builder blocks
│   ├── hooks/               # Payload hooks
│   ├── access/              # Access control functions
│   └── payload.config.ts    # Main Payload config
├── scripts/
│   └── tunnel-mongodb.sh    # SSH tunnel script
├── public/                  # Static assets
├── .env.local              # Local environment variables
└── package.json
```

## Deployment

### Production Server

- **Server IP**: 77.42.17.21
- **Domain**: cms.morar.dev
- **Installation Path**: `/var/www/payload/payload-cms`
- **User**: morar
- **Port**: 3000 (localhost only, proxied via Caddy)

### Service Management

```bash
# Check status
sudo systemctl status payload-cms.service

# Start service
sudo systemctl start payload-cms.service

# Stop service
sudo systemctl stop payload-cms.service

# Restart service
sudo systemctl restart payload-cms.service

# View logs
sudo journalctl -u payload-cms.service -f
```

### Caddy Configuration

Location: `/etc/caddy/Caddyfile`

```caddy
cms.morar.dev {
    # Redirect root to admin panel
    redir / /admin/ permanent

    # Proxy all traffic to Payload CMS
    reverse_proxy localhost:3000
}
```

### Environment Variables (Production)

Location: `/var/www/payload/payload-cms/.env`

```env
DATABASE_URL=mongodb://127.0.0.1:27017/payload-cms
PAYLOAD_SECRET=<generated-secret>
NEXT_PUBLIC_SERVER_URL=https://cms.morar.dev
CRON_SECRET=<generated-secret>
PREVIEW_SECRET=<generated-secret>
NODE_ENV=production
```

### Deployment Workflow

```bash
# On Hetzner server
ssh hetzner
cd /var/www/payload/payload-cms
git pull
npm install  # if package.json changed
npm run build
sudo systemctl restart payload-cms.service
```

## Local Development

### Prerequisites

1. **SSH Tunnel** - Required to connect to MongoDB on Hetzner
2. **Node.js** - 18.20.2+ or 20.9.0+
3. **pnpm** - 9+ or 10+

### Setup

#### 1. Start SSH Tunnel

**Option A: Using script (recommended)**
```bash
npm run tunnel:mongodb
# or
./scripts/tunnel-mongodb.sh
```

**Option B: Manual**
```bash
ssh -N -L 27017:127.0.0.1:27017 hetzner
```

**SSH Config** (for convenience):
```ssh-config
Host hetzner
    HostName 77.42.17.21
    User morar
    IdentityFile ~/.ssh/id_rsa
```

#### 2. Environment Variables

Create `.env.local` in project root:

```env
# SSH tunnel required: ssh -N -L 27017:127.0.0.1:27017 hetzner
DATABASE_URL=mongodb://127.0.0.1:27017/payload-cms
PAYLOAD_SECRET=local-dev-secret-change-me
NEXT_PUBLIC_SERVER_URL=http://localhost:3001
NODE_ENV=development
CRON_SECRET=local-cron-secret
PREVIEW_SECRET=local-preview-secret
```

#### 3. Install Dependencies

```bash
npm install
```

#### 4. Start Development Server

```bash
npm run dev
# Visit http://localhost:3001/admin
```

**Note**: Local dev uses port 3001 to avoid conflicts with other Next.js apps.

### Development Workflow

```bash
# 1. Start SSH tunnel (keep running in separate terminal)
npm run tunnel:mongodb

# 2. Start local dev
npm run dev

# 3. Make changes
# - Edit collections, config, etc.
# - Changes affect shared database (be careful!)

# 4. Commit and push
git add .
git commit -m "Your changes"
git push

# 5. Deploy to production
ssh hetzner "cd /var/www/payload/payload-cms && git pull && npm run build && sudo systemctl restart payload-cms"
```

### Shared Database

⚠️ **Important**: Local development connects to the **production MongoDB** on Hetzner.

**Benefits:**
- ✅ Real production data for testing
- ✅ No data sync needed
- ✅ Immediate testing of changes

**Risks:**
- ⚠️ Changes affect production - be careful
- ⚠️ Use drafts for testing, not published content
- ⚠️ Test destructive operations carefully

## Collections

### Posts

Blog posts with:
- Layout builder support
- Draft/preview functionality
- Lexical rich text editor
- SEO plugin integration
- Categories relationship

### Pages

Static pages with:
- Layout builder support
- Draft/preview functionality
- Custom page templates

### Media

Upload collection for:
- Images (with automatic resizing)
- Videos
- Documents
- Focal point support

### Categories

Taxonomy for posts:
- Nested categories support
- Hierarchical structure

### Users

Authentication collection:
- Role-based access control
- Admin panel access

## Access Points

- **Admin Panel**: `https://cms.morar.dev/admin` (redirected from root)
- **Frontend**: `https://cms.morar.dev` (Next.js website)
- **API**: `https://cms.morar.dev/api` (REST and GraphQL)
- **Local Dev**: `http://localhost:3001/admin`

## API Usage

### REST API

```bash
# Get all posts
curl https://cms.morar.dev/api/posts

# Get specific post
curl https://cms.morar.dev/api/posts/{id}
```

### GraphQL API

```bash
# GraphQL endpoint
POST https://cms.morar.dev/api/graphql
```

## Troubleshooting

### MongoDB Connection Failed

```bash
# Check SSH tunnel
ps aux | grep "27017:127.0.0.1:27017"

# Restart tunnel
npm run tunnel:mongodb

# Test connection
mongosh mongodb://127.0.0.1:27017/payload-cms
```

### Service Not Starting

```bash
# Check service status
sudo systemctl status payload-cms.service

# View logs
sudo journalctl -u payload-cms.service -n 50 -f

# Check MongoDB
mongosh mongodb://127.0.0.1:27017/payload-cms

# Verify port
sudo netstat -tlnp | grep 3000
```

### Build Errors

```bash
# Clear build cache
rm -rf .next

# Reinstall dependencies
rm -rf node_modules package-lock.json
npm install

# Regenerate types
npm run generate:types
```

## Security

### Best Practices

1. **Secrets**: All secrets are generated securely (PAYLOAD_SECRET, CRON_SECRET, PREVIEW_SECRET)
2. **MongoDB**: Only accessible locally (127.0.0.1) on server
3. **HTTPS**: Enforced via Caddy (automatic SSL)
4. **Environment Variables**: Stored in `.env` (never commit to Git)
5. **SSH Tunnel**: Required for local MongoDB access (secure)
6. **Regular Updates**: Keep Payload and dependencies updated

### Access Control

- **Public**: Published posts and pages
- **Authenticated**: Admin panel access
- **Admin**: Full access to all collections

## Maintenance

### Updates

```bash
cd /var/www/payload/payload-cms
npm update payload @payloadcms/db-mongodb
npm run build
sudo systemctl restart payload-cms.service
```

### Backups

TODO: Set up automated MongoDB backups

### Logs

```bash
# View service logs
sudo journalctl -u payload-cms.service -f

# View Caddy logs
sudo journalctl -u caddy -f
```

## References

- **Infrastructure Docs**: `/Users/apple/Projects/98_infra/`
- **Payload CMS Docs**: https://payloadcms.com/docs
- **Template Docs**: https://github.com/payloadcms/payload/tree/main/templates/website
- **Caddy Docs**: https://caddyserver.com/docs

