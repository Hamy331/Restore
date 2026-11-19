import { Router } from 'express';
import { PERMISSION } from '../../../common/auth/permissions.js';
import { requirePermission } from '../../../middlewares/auth.middleware.js';
import { validate } from '../../../middlewares/validate.middleware.js';
import * as reviewController from '../controllers/review.controller.js';
import { reviewListingParams, userReviewBody } from '../review.validator.js';

const reviewRouter = Router();

/** Reviews của một giao dịch đã hoàn tất. */
reviewRouter.get('/:id/reviews', validate({ params: reviewListingParams }), reviewController.list);

/** Một trong hai bên đã ghi nhận hoàn tất giao dịch được đánh giá bên còn lại, mỗi bên một lần. */
reviewRouter.post('/:id/reviews', requirePermission(PERMISSION.LISTING_MANAGE_OWN),
  validate({ params: reviewListingParams, body: userReviewBody }), reviewController.create);

export default reviewRouter;
