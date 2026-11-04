import { test } from 'node:test';
import { useApi } from './support/context.js';
import { lastOtp } from './support/email-outbox.js';
import { PASSWORD } from './support/database.js';

const { ctx, expect } = useApi('auth');
const email = 'new-user@restore.test';

test('auth: register, verify, login, refresh, logout', async () => {
  const { api } = ctx;
  expect('register', await api.post('/auth/register', { body: { email, password: PASSWORD, username: 'new_user', fullName: 'Người Dùng Mới' } }));
  expect('register duplicate', await api.post('/auth/register', { body: { email: 'user-buyer@restore.test', password: PASSWORD, username: 'other_name', fullName: 'Trùng Email' } }));
  expect('login before verify', await api.post('/auth/login', { body: { email, password: PASSWORD } }));
  expect('resend otp too soon', await api.post('/auth/resend-registration-otp', { body: { email } }));
  expect('verify wrong otp', await api.post('/auth/verify-registration-otp', { body: { email, otp: '000000' } }));
  expect('verify otp', await api.post('/auth/verify-registration-otp', { body: { email, otp: lastOtp(email) } }));

  const login = expect('login', await api.post('/auth/login', { body: { email, password: PASSWORD } }));
  expect('login wrong password', await api.post('/auth/login', { body: { email, password: 'Wrong@12345' } }));
  expect('login banned', await api.post('/auth/login', { body: { email: 'user-banned@restore.test', password: PASSWORD } }));
  expect('me', await api.get('/auth/me', { token: login.body.data.accessToken }));
  expect('me without token', await api.get('/auth/me'));

  const refreshed = expect('refresh', await api.post('/auth/refresh', { body: { refreshToken: login.body.data.refreshToken } }));
  expect('refresh reused token', await api.post('/auth/refresh', { body: { refreshToken: login.body.data.refreshToken } }));
  expect('logout', await api.post('/auth/logout', { body: { refreshToken: refreshed.body.data.refreshToken } }));
});

test('auth: forgot and reset password', async () => {
  const { api } = ctx;
  const target = 'user-buyer@restore.test';
  expect('forgot password', await api.post('/auth/forgot-password', { body: { email: target } }));
  expect('forgot password unknown email', await api.post('/auth/forgot-password', { body: { email: 'nobody@restore.test' } }));
  const verified = expect('verify reset otp', await api.post('/auth/verify-otp', { body: { email: target, otp: lastOtp(target) } }));
  expect('reset password', await api.post('/auth/reset-password', { body: { resetToken: verified.body.data?.resetToken, newPassword: 'NewPassword@123' } }));
  expect('login with new password', await api.post('/auth/login', { body: { email: target, password: 'NewPassword@123' } }));
});
