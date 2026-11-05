import { Router } from 'express';
import { adminRouter } from './modules/admin/index.js';
import { authRouter } from './modules/auth/index.js';
import { catalogRouter } from './modules/catalog/index.js';
import { homeRouter } from './modules/home/index.js';
import { promotionRouter, storeRouter } from './modules/commerce/index.js';
import { contentRouter } from './modules/content/index.js';
import { listingsRouter } from './modules/listings/index.js';
import { usersRouter } from './modules/users/index.js';
import { wantedAlertRouter } from './modules/wanted-alerts/index.js';
import chatRouter from './modules/chat/chat.route.js';
import { feedRouter } from './modules/feeds/feed.route.js';
import { mediaRouter } from './modules/media/media.route.js';

/** Toàn bộ API, gắn dưới tiền tố /api/v1 trong app.ts. */
export const apiRouter = Router();

apiRouter.use('/auth', authRouter);
apiRouter.use('/users', usersRouter);
apiRouter.use('/home', homeRouter);

apiRouter.use('/listings', listingsRouter);
apiRouter.use('/wanted-alerts', wantedAlertRouter);

apiRouter.use('/stores', storeRouter);
apiRouter.use('/promotions', promotionRouter);
apiRouter.use('/content', contentRouter);
apiRouter.use('/admin', adminRouter);
apiRouter.use('/catalog', catalogRouter);

// Chat, bảng tin và hồ sơ công khai (nhánh phat). Bảng tin gắn cuối cùng vì
// router của nó yêu cầu đăng nhập cho mọi đường dẫn đi qua.
apiRouter.use('/media', mediaRouter);
apiRouter.use('/conversations', chatRouter);
apiRouter.use(feedRouter);
