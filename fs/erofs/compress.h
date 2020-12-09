/* SPDX-License-Identifier: GPL-2.0-only */
/*
 * Copyright (C) 2019 HUAWEI, Inc.
 *             https://www.huawei.com/
 */
#ifndef __EROFS_FS_COMPRESS_H
#define __EROFS_FS_COMPRESS_H

#include "internal.h"

enum {
	Z_EROFS_COMPRESSION_SHIFTED = Z_EROFS_COMPRESSION_MAX,
	Z_EROFS_COMPRESSION_RUNTIME_MAX
};

struct z_erofs_decompress_req {
	struct super_block *sb;
	struct page **in, **out;

	unsigned short pageofs_out;
	unsigned int inputsize, outputsize;

	/* indicate the algorithm will be used for decompression */
	unsigned int alg;
	bool inplace_io, partial_decoding;
};

/* some special page->private (unsigned long, see below) */
#define Z_EROFS_SHORTLIVED_PAGE		(-1UL << 2)
#define Z_EROFS_PREALLOCATED_PAGE	(-2UL << 2)

/*
 * For all pages in a pcluster, page->private should be one of
 * Type                         Last 2bits      page->private
 * short-lived page             00              Z_EROFS_SHORTLIVED_PAGE
 * preallocated page (tryalloc) 00              Z_EROFS_PREALLOCATED_PAGE
 * cached/managed page          00              pointer to z_erofs_pcluster
 * online page (file-backed,    01/10/11        sub-index << 2 | count
 *              some pages can be used for inplace I/O)
 *
 * page->mapping should be one of
 * Type                 page->mapping
 * short-lived page     NULL
 * preallocated page    NULL
 * cached/managed page  non-NULL or NULL (invalidated/truncated page)
 * online page          non-NULL
 *
 * For all managed pages, PG_private should be set with 1 extra refcount,
 * which is used for page reclaim / migration.
 */
#define Z_EROFS_MAPPING_STAGING         ((void *)0x5A110C8D)

/* check if a page is marked as staging */
static inline bool z_erofs_page_is_staging(struct page *page)
{
	return page->mapping == Z_EROFS_MAPPING_STAGING;
}

static inline bool z_erofs_put_stagingpage(struct list_head *pagepool,
					   struct page *page)
{
	if (!z_erofs_page_is_staging(page))
		return false;

	/* staging pages should not be used by others at the same time */
	if (page_ref_count(page) > 1)
		put_page(page);
	else
		list_add(&page->lru, pagepool);
	return true;
}

int z_erofs_decompress(struct z_erofs_decompress_req *rq,
		       struct list_head *pagepool);

#endif
