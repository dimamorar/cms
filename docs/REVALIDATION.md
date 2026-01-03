# Content Revalidation System

## Overview

This document describes the on-demand revalidation system that ensures the portfolio site (`5_morar.dev`) immediately reflects content changes made in the CMS (`5.1_cms`).

## Problem Statement

Previously, when content was updated in the CMS:
- ✅ Changes were saved to MongoDB
- ✅ CMS app paths were revalidated (`cms.morar.dev/posts/slug`)
- ❌ Portfolio site was not notified (waited up to 1 hour for ISR cache to expire)

This caused a delay of up to 1 hour before changes appeared on the live portfolio site.

## Solution: On-Demand Revalidation

The system now uses **on-demand revalidation** via webhook calls from the CMS to the portfolio site.

### Architecture Flow

```
User saves post in CMS
    ↓
CMS saves to MongoDB
    ↓
CMS revalidates its own paths (cms.morar.dev/posts/slug)
    ↓
CMS calls portfolio revalidation API (morar.dev/api/revalidate)
    ↓
Portfolio revalidates paths (morar.dev/blog/slug)
    ↓
Portfolio invalidates fetch cache
    ↓
Next request shows latest content immediately
```

## Implementation Details

### 1. Portfolio Revalidation API Route

**File**: `/Users/apple/Projects/5_morar.dev/app/api/revalidate/route.ts`

- Accepts POST requests with secret token authentication
- Validates `REVALIDATE_SECRET` environment variable
- Revalidates specific paths using `revalidatePath()`
- Revalidates cache tags using `revalidateTag()`
- Handles collection-specific revalidation (e.g., posts collection also revalidates `/blog` list page)

**Security**: All requests must include a valid secret token matching `REVALIDATE_SECRET`.

### 2. CMS Revalidation Hook

**File**: `/Users/apple/Projects/5.1_cms/src/collections/Posts/hooks/revalidatePost.ts`

The `revalidatePost` hook now:
1. Revalidates CMS app paths (existing behavior)
2. Calls `revalidatePortfolioSite()` function to trigger portfolio revalidation
3. Maps CMS paths to portfolio paths:
   - `/posts/slug` → `/blog/slug`
4. Handles errors gracefully (logs but doesn't fail save operation)

**Helper Function**: `revalidatePortfolioSite()`
- Reads `PORTFOLIO_REVALIDATE_URL` and `PORTFOLIO_REVALIDATE_SECRET` from environment
- Makes HTTP POST request to portfolio revalidation API
- Logs success/failure for monitoring
- Skips silently if environment variables not set (for local development)

### 3. Path Mapping

| CMS Path | Portfolio Path | Notes |
|----------|---------------|-------|
| `/posts/{slug}` | `/blog/{slug}` | Individual blog post |
| `/posts` | `/blog` | Blog list page (revalidated automatically) |

## Environment Variables

### CMS App (`.env`)

```bash
# Portfolio site revalidation endpoint
PORTFOLIO_REVALIDATE_URL=http://localhost:3000/api/revalidate
# For production: https://morar.dev/api/revalidate

# Shared secret token (must match portfolio site)
PORTFOLIO_REVALIDATE_SECRET=your-secret-token-here
```

### Portfolio Site (`.env`)

```bash
# Secret token for revalidation API (must match CMS)
REVALIDATE_SECRET=your-secret-token-here
```

## How It Works

### When User Clicks "Save Changes" in CMS

1. **Save Operation**:
   - Post data is saved to MongoDB
   - `afterChange` hook is triggered

2. **CMS Revalidation**:
   - `revalidatePost` hook executes
   - Revalidates CMS paths: `/posts/{slug}`
   - Revalidates CMS tags: `posts-sitemap`

3. **Portfolio Revalidation** (New):
   - `revalidatePortfolioSite()` function is called
   - HTTP POST request sent to portfolio revalidation API
   - Portfolio revalidates: `/blog/{slug}` and `/blog`
   - Portfolio invalidates fetch cache for that content

4. **Result**:
   - Next request to portfolio site fetches fresh data from CMS API
   - Changes appear immediately (no 1-hour wait)

### Error Handling

- If portfolio revalidation fails, the CMS save operation still succeeds
- Errors are logged for monitoring but don't block content updates
- If environment variables are not set, revalidation is skipped (useful for local development)

## Testing

### Local Development

1. **Start both apps**:
   ```bash
   # Terminal 1: CMS
   cd /Users/apple/Projects/5.1_cms
   npm run dev

   # Terminal 2: Portfolio
   cd /Users/apple/Projects/5_morar.dev
   npm run dev
   ```

2. **Set environment variables**:
   - CMS `.env.local`: `PORTFOLIO_REVALIDATE_URL=http://localhost:3000/api/revalidate`
   - Portfolio `.env.local`: `REVALIDATE_SECRET=test-secret`
   - CMS `.env.local`: `PORTFOLIO_REVALIDATE_SECRET=test-secret`

3. **Test revalidation**:
   - Edit a post in CMS (localhost:3001)
   - Save changes
   - Check CMS logs for "Portfolio revalidation successful"
   - Refresh portfolio blog page (localhost:3000/blog/slug)
   - Changes should appear immediately

### Production

- Ensure environment variables are set in both production environments
- Monitor logs for revalidation success/failure
- Set up alerts for repeated revalidation failures

## Best Practices

### Static vs Incremental vs On-Demand Revalidation

**Hybrid Approach (Recommended)**:
- **Primary**: On-demand revalidation (immediate updates)
- **Fallback**: ISR with reasonable cache time (60-300 seconds)
- **Benefits**: Instant updates + resilience if webhook fails

**Current Configuration**:
- Portfolio site uses `revalidate = 3600` (1 hour) as fallback
- On-demand revalidation provides immediate updates
- If webhook fails, ISR ensures content updates within 1 hour

### Performance Considerations

- Revalidation webhook calls are **asynchronous** (don't block save operation)
- Portfolio revalidation is fast (just cache invalidation, not full rebuild)
- Failed webhooks don't prevent content from being saved

### Security

- Always use strong secret tokens
- Never commit secrets to version control
- Use different secrets for development and production
- Validate tokens on both ends (CMS and Portfolio)

## Related Files

- **CMS Hook**: `src/collections/Posts/hooks/revalidatePost.ts`
- **Portfolio API**: `5_morar.dev/app/api/revalidate/route.ts`
- **Portfolio Blog Fetch**: `5_morar.dev/lib/blog.ts`
- **Portfolio Blog Page**: `5_morar.dev/app/blog/[slug]/page.tsx`

## Future Enhancements

- [ ] Add revalidation for Pages collection
- [ ] Add revalidation for Media collection (when media is updated)
- [ ] Add retry logic for failed webhook calls
- [ ] Add monitoring dashboard for revalidation success rates
- [ ] Support batch revalidation for multiple paths

