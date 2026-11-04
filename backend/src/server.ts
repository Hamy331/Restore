import 'dotenv/config';
import { createApp } from './app.js';
import { validateEnvironment } from './config/env.js';
import { startAccountStatusJob } from './jobs/account-status.job.js';

validateEnvironment();
startAccountStatusJob();

const PORT = process.env.PORT || 3000;
createApp().listen(PORT, () => {
  console.log(`🚀 Restore Backend đang chạy tại http://localhost:${PORT}`);
});
