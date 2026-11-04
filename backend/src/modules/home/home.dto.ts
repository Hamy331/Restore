import { HomeBanner } from '@prisma/client';
import type { z } from 'zod';
import type { areaQuery, bannerBody } from './home.validator.js';

/* ---------- Vào (suy ra từ schema) ---------- */

export type AreaQuery = z.output<typeof areaQuery>;
export type BannerInput = z.output<ReturnType<typeof bannerBody>>;
export type BannerIdParams = { id: string };

/* ---------- Ra ---------- */

/** Khu vực ở đầu trang chủ; code = null nghĩa là "Toàn quốc" */
export type AreaDto = { code: string | null; name: string; shortName?: string };

/** Banner cho app: đúng với HomeBanner.fromJson ở Flutter */
export type HomeBannerDto = { id: string; imageUrl: string | null; route: string | null };

export const toHomeBannerDto = (banner: HomeBanner): HomeBannerDto => ({
  id: banner.id,
  imageUrl: banner.imageUrl,
  route: banner.route,
});
