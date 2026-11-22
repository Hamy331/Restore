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
