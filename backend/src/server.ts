import 'dotenv/config';
import { createApp } from './app.js';
import { validateEnvironment } from './config/env.js';
import { startAccountStatusJob } from './jobs/account-status.job.js';
import { startListingExpiryJob } from './jobs/listing-expiry.job.js';
import { startNotificationPushJob } from './jobs/notification-push.job.js';

validateEnvironment();
startAccountStatusJob();
startListingExpiryJob();
startNotificationPushJob();

const PORT = process.env.PORT || 3000;
createApp().listen(PORT, () => {
  console.log(`🚀 Restore Backend đang chạy tại http://localhost:${PORT}`);
});
