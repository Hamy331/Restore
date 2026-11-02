import { HomeBanner } from '@prisma/client';

/** JSON banner cho app: đúng với HomeBanner.fromJson ở Flutter */
export const toPublicBanner = (banner: HomeBanner) => ({
  id: banner.id,
  imageUrl: banner.imageUrl,
  route: banner.route,
});
