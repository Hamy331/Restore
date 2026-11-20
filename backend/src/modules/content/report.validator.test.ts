import assert from 'node:assert/strict';
import test from 'node:test';
import { reportBody } from './content.validator.js';
import { applyReportReason } from './services/report-policy.service.js';

const form = {
  targetType: 'LISTING', targetId: 'listing-1', reasonCode: 'CUSTOM_REASON',
  contactPhone: '+84 (912) 345-678', contactEmail: ' Buyer@example.com ',
};

test('listing report normalizes contacts and accepts a newly configured reason without a code allowlist', () => {
    const input = reportBody.parse({ ...form, reason: 'Untrusted label', evidence: 'Additional details' });
    const result = applyReportReason(input, { code: form.reasonCode, labelVi: 'Configured label', requiresDescription: false, active: true });
    assert.equal(result.reason, 'Configured label');
    assert.equal(result.contactPhone, '+84912345678');
    assert.equal(result.contactEmail, 'buyer@example.com');
});

test('the compact report form accepts an empty description for every configured reason', () => {
  const input = reportBody.parse(form);
  const config = { code: form.reasonCode, labelVi: 'Configured', requiresDescription: false, active: true };
  assert.equal(applyReportReason(input, config).evidence, '');
  assert.equal(applyReportReason(input, { ...config, requiresDescription: true }).evidence, '');
  assert.throws(() => applyReportReason(input, { ...config, active: false }));
  assert.throws(() => applyReportReason(input, null));
  assert.equal(applyReportReason(reportBody.parse({ ...form, evidence: 'Enough details' }), { ...config, requiresDescription: true }).evidence, 'Enough details');
});

test('listing report rejects missing/invalid contacts and oversized evidence', () => {
  for (const changes of [
    { contactPhone: '' }, { contactPhone: '123' }, { contactPhone: '+84912abc678' },
    { contactPhone: '1'.repeat(16) }, { contactEmail: '' }, { contactEmail: 'wrong@' },
    { reasonCode: '' }, { evidence: 'x'.repeat(4001) },
    { targetType: 'USER' }, { targetType: 'FEED_POST' },
  ]) assert.throws(() => reportBody.parse({ ...form, ...changes }));
});

test('legacy clients keep their existing report validation and payload shape', () => {
  const legacy = { targetType: 'FEED_POST', targetId: 'post-1', reason: 'Nội dung giả mạo', evidence: 'Mô tả bằng chứng.' };
  assert.deepEqual(reportBody.parse(legacy), legacy);
  assert.throws(() => reportBody.parse({ ...legacy, evidence: '' }));
  assert.throws(() => reportBody.parse({ ...legacy, contactEmail: 'buyer@example.com' }));
});
