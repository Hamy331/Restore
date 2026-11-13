import assert from 'node:assert/strict';
import { test } from 'node:test';
import { useApi } from './support/context.js';
import { listingBody } from './support/fixtures.js';

const { ctx } = useApi('category-condition');

/** Thú cưng không hỏi tình trạng (bỏ nếu app gửi), danh mục khác vẫn bắt buộc; tuổi lưu theo tháng */
test('pets skip item condition, other categories still require it', async () => {
  const { api, tokens } = ctx;
  const token = tokens.buyer;

  const pets = await api.get('/catalog/categories?include=attributes');
  const pet = pets.body.data.find((item: { id: string }) => item.id === 'pets');
  assert.equal(pet.hasCondition, false);
  const age = pet.attributes.find((item: { key: string }) => item.key === 'age_months');
  assert.deepEqual(age.unitOptions.map((unit: { value: string; factor: number }) => [unit.value, unit.factor]), [['month', 1], ['year', 12]]);

  const petBody = { ...listingBody('Mèo Anh lông ngắn 2 tuổi'), categoryId: 'pets', attributes: { pet_type: 'cat', age_months: 24 } };
  const { condition: _ignored, ...withoutCondition } = petBody;
  const created = await api.post('/listings', { token, body: withoutCondition });
  assert.equal(created.status, 201, JSON.stringify(created.body));
  assert.equal(created.body.data.condition, null);

  const sent = await api.post('/listings', { token: tokens.seller, body: { ...petBody, title: 'Chó Poodle 6 tháng tuổi', attributes: { pet_type: 'dog', age_months: 6 } } });
  assert.equal(sent.status, 201, JSON.stringify(sent.body));
  assert.equal(sent.body.data.condition, null, 'tình trạng gửi kèm bị bỏ');

  const { condition: _dropped, ...otherWithout } = listingBody('Đèn bàn học cũ');
  const missing = await api.post('/listings', { token, body: otherWithout });
  assert.equal(missing.status, 400);
  assert.equal(missing.body.field, 'condition');
});
