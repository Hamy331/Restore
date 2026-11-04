/** Ảnh PNG 1×1 hợp lệ để thử upload */
export const PNG = Buffer.from(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg==',
  'base64',
);

/** Body hợp lệ để tạo tin trong danh mục "other" (không có thuộc tính bắt buộc) */
export const listingBody = (title = 'Tin tạo qua API thử') => ({
  title,
  description: 'Mô tả đủ dài cho tin đăng thử nghiệm.',
  price: '250000',
  condition: 'USED_GOOD',
  categoryId: 'other',
  location: { provinceCode: '79', wardCode: '26740', streetAddress: '1 Đường Thử' },
});
