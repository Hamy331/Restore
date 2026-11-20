import assert from 'node:assert/strict';
import { createVerify, generateKeyPairSync } from 'node:crypto';
import { test } from 'node:test';
import { buildFcmMessage, parseServiceAccount, signAssertion } from './push.service.js';

test('push: service-account JWT is RS256-signed with the right claims', () => {
  const { privateKey, publicKey } = generateKeyPairSync('rsa', { modulusLength: 2048 });
  const sa = { project_id: 'p', client_email: 'bot@p.iam.gserviceaccount.com', private_key: privateKey.export({ type: 'pkcs8', format: 'pem' }).toString() };
  const jwt = signAssertion(sa, 1_000);
  const [header, claims, signature] = jwt.split('.');
  assert.deepEqual(JSON.parse(Buffer.from(header, 'base64url').toString()), { alg: 'RS256', typ: 'JWT' });
  assert.deepEqual(JSON.parse(Buffer.from(claims, 'base64url').toString()), {
    iss: sa.client_email, scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token', iat: 1_000, exp: 4_600,
  });
  assert.ok(createVerify('RSA-SHA256').update(`${header}.${claims}`).verify(publicKey, Buffer.from(signature, 'base64url')));
});

test('push: FCM message keeps string data, https images only, and tags by notification', () => {
  const message = buildFcmMessage('tok', { title: 'T', body: 'B', data: { tag: 'n1', link: '/x' }, imageUrl: '/uploads/a.png' });
  assert.deepEqual(message.message.notification, { title: 'T', body: 'B' });
  assert.equal(message.message.android.notification.tag, 'n1');
  assert.equal(message.message.webpush.notification.tag, 'n1');
  const withImage = buildFcmMessage('tok', { title: 'T', body: 'B', data: {}, imageUrl: 'https://cdn/a.png' });
  assert.equal(withImage.message.notification.image, 'https://cdn/a.png');
});

test('push: service account from env accepts raw JSON or base64', () => {
  const raw = JSON.stringify({ project_id: 'p', client_email: 'c', private_key: 'k' });
  assert.equal(parseServiceAccount(raw).project_id, 'p');
  assert.equal(parseServiceAccount(Buffer.from(raw).toString('base64')).client_email, 'c');
});
