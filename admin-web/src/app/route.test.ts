import { describe, expect, it } from 'vitest';
import { pickFilter, readRoute, routeHash } from './route';

describe('route', () => {
  it('đọc mục và bộ lọc từ hash', () => {
    expect(readRoute('#members/BANNED')).toEqual({ key: 'members', filter: 'BANNED' });
    expect(readRoute('#reports')).toEqual({ key: 'reports', filter: '' });
    expect(readRoute('')).toEqual({ key: '', filter: '' });
  });

  it('ghi rồi đọc lại bộ lọc có dấu và dấu gạch chéo', () => {
    const filter = 'Bản sửa/chờ duyệt';
    expect(readRoute('#' + routeHash('listings', filter))).toEqual({ key: 'listings', filter });
    expect(routeHash('dashboard')).toBe('dashboard');
  });

  it('hash hỏng không làm sập trang', () => {
    expect(readRoute('#listings/%E0')).toEqual({ key: 'listings', filter: '' });
  });

  it('bộ lọc gõ tay không hợp lệ thì về mặc định', () => {
    expect(pickFilter('BANNED', ['ACTIVE', 'BANNED'])).toBe('BANNED');
    expect(pickFilter('rac', ['ACTIVE', 'BANNED'])).toBe('');
    expect(pickFilter('rac', ['PENDING'], 'PENDING')).toBe('PENDING');
  });
});
