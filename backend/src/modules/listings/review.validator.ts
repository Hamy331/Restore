import { z } from 'zod';
import { idParam, int, optionalStr, parse, strictBody } from '../../common/validation/schemas.js';

export const reviewListingParams = idParam();
export const userReviewBody = strictBody({ rating: z.unknown().optional(), comment: z.unknown().optional() })
  .transform((body) => ({
    rating: parse(int('rating', { min: 1, max: 5 }), body.rating),
    comment: parse(optionalStr('comment', { max: 1000 }), body.comment) ?? null,
  }));
