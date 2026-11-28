import 'dotenv/config';
import { createServer } from 'node:http';
import { attachChat } from './modules/chat/services/chat.events.js';
import { createApp } from './app.js';
import { validateEnvironment } from './config/env.js';
import { startAccountStatusJob } from './jobs/account-status.job.js';
import { startListingExpiryJob } from './jobs/listing-expiry.job.js';
import { startNotificationPushJob } from './jobs/notification-push.job.js';
import { startWalletReminderJob } from './jobs/wallet-reminder.job.js';
import { startTradeJob } from './jobs/trade.job.js';

import { startRagCleanupJob } from './jobs/rag-cleanup.job.js';
import { startListingAiIndexJob } from './jobs/listing-ai-index.job.js';
import { startListingAiReviewJob } from './jobs/listing-ai-review.job.js';
import { startBannedTermsJob } from './modules/listings/index.js';

validateEnvironment();
startAccountStatusJob();
startListingExpiryJob();
startNotificationPushJob();
startWalletReminderJob();
startTradeJob();
startRagCleanupJob();
startListingAiIndexJob();
startListingAiReviewJob();
startBannedTermsJob();

const PORT = process.env.PORT || 3000;
const server = createServer(createApp());
attachChat(server);
server.listen(PORT, () => {
  console.log(`🚀 Restore Backend đang chạy tại http://localhost:${PORT}`);
});
