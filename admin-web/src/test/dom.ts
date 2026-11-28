import { afterAll } from 'vitest';

// React chạy nốt effect sau commit bằng setImmediate của Node. Cập nhật xảy ra ngay trước khi file test kết thúc
// (VD promise của component resolve sau assert cuối) để lại việc đó; nếu vitest gỡ jsdom trước khi nó chạy thì
// React đọc window và báo "window is not defined" (lỗi ngẫu nhiên trên CI). Đợi chút cho nó chạy xong trước khi gỡ.
afterAll(() => new Promise<void>((resolve) => setTimeout(resolve, 50)));

// jsdom chưa có matchMedia mà antd (Grid, Form) cần: coi như màn hình không khớp breakpoint nào
window.matchMedia ??= (query: string) =>
  ({
    matches: false,
    media: query,
    onchange: null,
    addListener() {},
    removeListener() {},
    addEventListener() {},
    removeEventListener() {},
    dispatchEvent: () => false,
  }) as MediaQueryList;
// jsdom không cuộn trang; AdminApp gọi scrollTo khi đổi mục
window.scrollTo = () => {};
// Segmented, Table của antd theo dõi kích thước phần tử
globalThis.ResizeObserver ??= class {
  observe() {}
  unobserve() {}
  disconnect() {}
};
