import type { CollectionAfterChangeHook, CollectionAfterDeleteHook, Payload } from 'payload'

import { revalidatePath, revalidateTag } from 'next/cache'

import type { Post } from '../../../payload-types'

/**
 * Triggers on-demand revalidation on the portfolio site
 * Maps CMS paths to portfolio paths and calls the revalidation API
 */
async function revalidatePortfolioSite({
  path,
  tag,
  collection,
  payload,
}: {
  path: string
  tag: string
  collection: string
  payload: Payload
}): Promise<void> {
  const portfolioUrl = process.env.PORTFOLIO_REVALIDATE_URL
  const secret = process.env.PORTFOLIO_REVALIDATE_SECRET

  // Skip if not configured (e.g., local development without portfolio running)
  if (!portfolioUrl || !secret) {
    payload.logger.debug(
      'Portfolio revalidation skipped: PORTFOLIO_REVALIDATE_URL or PORTFOLIO_REVALIDATE_SECRET not set',
    )
    return
  }

  try {
    const response = await fetch(portfolioUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        secret,
        path,
        tag,
        collection,
      }),
    })

    if (!response.ok) {
      const errorText = await response.text()
      payload.logger.error(`Portfolio revalidation failed: ${response.status} ${errorText}`)
      return
    }

    const result = await response.json()
    payload.logger.info(`Portfolio revalidation successful: ${path} (${result.now})`)
  } catch (error) {
    // Don't fail the save operation if revalidation fails
    payload.logger.error(
      `Portfolio revalidation error: ${error instanceof Error ? error.message : String(error)}`,
    )
  }
}

export const revalidatePost: CollectionAfterChangeHook<Post> = async ({
  doc,
  previousDoc,
  req: { payload, context },
}) => {
  if (!context.disableRevalidate) {
    if (doc._status === 'published') {
      const path = `/posts/${doc.slug}`

      payload.logger.info(`Revalidating post at path: ${path}`)

      revalidatePath(path)
      revalidateTag('posts-sitemap')

      // Trigger portfolio site revalidation
      await revalidatePortfolioSite({
        path: `/blog/${doc.slug}`,
        tag: 'posts',
        collection: 'posts',
        payload,
      })
    }

    // If the post was previously published, we need to revalidate the old path
    if (previousDoc._status === 'published' && doc._status !== 'published') {
      const oldPath = `/posts/${previousDoc.slug}`

      payload.logger.info(`Revalidating old post at path: ${oldPath}`)

      revalidatePath(oldPath)
      revalidateTag('posts-sitemap')

      // Trigger portfolio site revalidation for old path
      await revalidatePortfolioSite({
        path: `/blog/${previousDoc.slug}`,
        tag: 'posts',
        collection: 'posts',
        payload,
      })
    }
  }
  return doc
}

export const revalidateDelete: CollectionAfterDeleteHook<Post> = async ({
  doc,
  req: { context, payload },
}) => {
  if (!context.disableRevalidate) {
    const path = `/posts/${doc?.slug}`

    revalidatePath(path)
    revalidateTag('posts-sitemap')

    // Trigger portfolio site revalidation
    await revalidatePortfolioSite({
      path: `/blog/${doc?.slug}`,
      tag: 'posts',
      collection: 'posts',
      payload,
    })
  }

  return doc
}
