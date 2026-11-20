// Dữ liệu + header/footer dùng chung cho các mockup desktop của Restore.
const A = '../../../frontend/assets/';

const ICONS = {
  search: '<circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/>',
  bell: '<path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9"/><path d="M10.3 21a1.94 1.94 0 0 0 3.4 0"/>',
  msg: '<path d="M7.9 20A9 9 0 1 0 4 16.1L2 22Z"/>',
  heart: '<path d="M19 14c1.49-1.46 3-3.21 3-5.5A5.5 5.5 0 0 0 16.5 3c-1.76 0-3 .5-4.5 2-1.5-1.5-2.74-2-4.5-2A5.5 5.5 0 0 0 2 8.5c0 2.3 1.5 4.05 3 5.5l7 7Z"/>',
  user: '<circle cx="12" cy="8" r="5"/><path d="M20 21a8 8 0 0 0-16 0"/>',
  plus: '<path d="M5 12h14"/><path d="M12 5v14"/>',
  pin: '<path d="M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 0 1 16 0Z"/><circle cx="12" cy="10" r="3"/>',
  down: '<path d="m6 9 6 6 6-6"/>',
  right: '<path d="m9 18 6-6-6-6"/>',
  left: '<path d="m15 18-6-6 6-6"/>',
  shield: '<path d="M20 13c0 5-3.5 7.5-7.66 8.95a1 1 0 0 1-.67-.01C7.5 20.5 4 18 4 13V6a1 1 0 0 1 1-1c2 0 4.5-1.2 6.24-2.72a1.17 1.17 0 0 1 1.52 0C14.51 3.81 17 5 19 5a1 1 0 0 1 1 1z"/><path d="m9 12 2 2 4-4"/>',
  clock: '<circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/>',
  tag: '<path d="M12.586 2.586A2 2 0 0 0 11.172 2H4a2 2 0 0 0-2 2v7.172a2 2 0 0 0 .586 1.414l8.704 8.704a2.426 2.426 0 0 0 3.42 0l6.58-6.58a2.426 2.426 0 0 0 0-3.42z"/><circle cx="7.5" cy="7.5" r=".5"/>',
  phone: '<path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z"/>',
  share: '<circle cx="18" cy="5" r="3"/><circle cx="6" cy="12" r="3"/><circle cx="18" cy="19" r="3"/><line x1="8.59" x2="15.42" y1="13.51" y2="17.49"/><line x1="15.41" x2="8.59" y1="6.51" y2="10.49"/>',
  flag: '<path d="M4 15s1-1 4-1 5 2 8 2 4-1 4-1V3s-1 1-4 1-5-2-8-2-4 1-4 1z"/><line x1="4" x2="4" y1="22" y2="15"/>',
  swap: '<path d="m17 2 4 4-4 4"/><path d="M3 11v-1a4 4 0 0 1 4-4h14"/><path d="m7 22-4-4 4-4"/><path d="M21 13v1a4 4 0 0 1-4 4H3"/>',
  send: '<path d="m22 2-7 20-4-9-9-4Z"/><path d="M22 2 11 13"/>',
  image: '<rect width="18" height="18" x="3" y="3" rx="2"/><circle cx="9" cy="9" r="2"/><path d="m21 15-3.086-3.086a2 2 0 0 0-2.828 0L6 21"/>',
  file: '<path d="M15 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7Z"/><path d="M14 2v4a2 2 0 0 0 2 2h4"/><path d="M16 13H8"/><path d="M16 17H8"/>',
  settings: '<line x1="21" x2="14" y1="4" y2="4"/><line x1="10" x2="3" y1="4" y2="4"/><line x1="21" x2="12" y1="12" y2="12"/><line x1="8" x2="3" y1="12" y2="12"/><line x1="21" x2="16" y1="20" y2="20"/><line x1="12" x2="3" y1="20" y2="20"/><line x1="14" x2="14" y1="2" y2="6"/><line x1="8" x2="8" y1="10" y2="14"/><line x1="16" x2="16" y1="18" y2="22"/>',
  logout: '<path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" x2="9" y1="12" y2="12"/>',
  store: '<path d="M2 7 6.41 2.59A2 2 0 0 1 7.83 2h8.34a2 2 0 0 1 1.42.59L22 7"/><path d="M4 12v8a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-8"/><path d="M15 22v-4a2 2 0 0 0-2-2h-2a2 2 0 0 0-2 2v4"/><path d="M2 7h20v3a2 2 0 0 1-2 2 2.7 2.7 0 0 1-2-1 2.7 2.7 0 0 1-2 1 2.7 2.7 0 0 1-2-1 2.7 2.7 0 0 1-2 1 2.7 2.7 0 0 1-2-1 2.7 2.7 0 0 1-2 1 2 2 0 0 1-2-2Z"/>',
  news: '<path d="M4 22h16a2 2 0 0 0 2-2V4a2 2 0 0 0-2-2H8a2 2 0 0 0-2 2v16a2 2 0 0 1-2 2Zm0 0a2 2 0 0 1-2-2v-9c0-1.1.9-2 2-2h2"/><path d="M18 14h-8"/><path d="M15 18h-5"/><path d="M10 6h8v4h-8V6Z"/>',
  help: '<circle cx="12" cy="12" r="10"/><path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3"/><path d="M12 17h.01"/>',
  globe: '<circle cx="12" cy="12" r="10"/><path d="M12 2a14.5 14.5 0 0 0 0 20 14.5 14.5 0 0 0 0-20"/><path d="M2 12h20"/>',
  fb: '<path d="M18 2h-3a5 5 0 0 0-5 5v3H7v4h3v8h4v-8h3l1-4h-4V7a1 1 0 0 1 1-1h3z"/>',
  ig: '<rect width="20" height="20" x="2" y="2" rx="5"/><path d="M16 11.37A4 4 0 1 1 12.63 8 4 4 0 0 1 16 11.37z"/><line x1="17.5" x2="17.51" y1="6.5" y2="6.5"/>',
  eye: '<path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7Z"/><circle cx="12" cy="12" r="3"/>',
  truck: '<path d="M14 18V6a2 2 0 0 0-2-2H4a2 2 0 0 0-2 2v11a1 1 0 0 0 1 1h2"/><path d="M15 18H9"/><path d="M19 18h2a1 1 0 0 0 1-1v-3.65a1 1 0 0 0-.22-.624l-3.48-4.35A1 1 0 0 0 17.52 8H14"/><circle cx="17" cy="18" r="2"/><circle cx="7" cy="18" r="2"/>',
  check: '<path d="M3.85 8.62a4 4 0 0 1 4.78-4.77 4 4 0 0 1 6.74 0 4 4 0 0 1 4.78 4.78 4 4 0 0 1 0 6.74 4 4 0 0 1-4.77 4.78 4 4 0 0 1-6.75 0 4 4 0 0 1-4.78-4.77 4 4 0 0 1 0-6.76Z"/><path d="m9 12 2 2 4-4"/>',
  tick: '<path d="M20 6 9 17l-5-5"/>',
  bag: '<path d="M6 2 3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4Z"/><path d="M3 6h18"/><path d="M16 10a4 4 0 0 1-8 0"/>',
  lock: '<rect width="18" height="11" x="3" y="11" rx="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/>',
  mail: '<rect width="20" height="16" x="2" y="4" rx="2"/><path d="m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7"/>',
  more: '<circle cx="12" cy="12" r="1"/><circle cx="12" cy="5" r="1"/><circle cx="12" cy="19" r="1"/>',
  star: '<polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/>',
  pkg: '<path d="m7.5 4.27 9 5.15"/><path d="M21 8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16Z"/><path d="m3.3 7 8.7 5 8.7-5"/><path d="M12 22V12"/>',
  users: '<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/>',
  crown: '<path d="M11.562 3.266a.5.5 0 0 1 .876 0L15.39 8.87a1 1 0 0 0 1.516.294L21.183 5.5a.5.5 0 0 1 .798.519l-2.834 10.246a1 1 0 0 1-.956.734H5.81a1 1 0 0 1-.957-.734L2.02 6.02a.5.5 0 0 1 .798-.519l4.276 3.664a1 1 0 0 0 1.516-.294z"/>',
  coin: '<circle cx="8" cy="8" r="6"/><path d="M18.09 10.37A6 6 0 1 1 10.34 18"/><path d="M7 6h1v4"/>',
  expand: '<path d="M15 3h6v6"/><path d="M9 21H3v-6"/><path d="M21 3l-7 7"/><path d="M3 21l7-7"/>',
  bell2:'<path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9"/>',
};
const ic = (n, extra = '') => `<svg class="i ${extra}" viewBox="0 0 24 24">${ICONS[n]}</svg>`;

document.head.insertAdjacentHTML('beforeend', `<style>
.ava.ini{display:grid;place-items:center;font-weight:800;color:var(--primary-dark);background:var(--primary-soft);font-size:18px}
.hd-top .me .ava{width:22px;height:22px;font-size:10px;border-width:0}
</style>`);

const MP = A + 'images/marketplace/';
const LISTINGS = [
  { t: 'Máy ảnh Canon EOS 700D kèm lens 18-55, đủ phụ kiện', img: 'detail-canon.jpg', p: '5.200.000 ₫', o: '6.500.000 ₫', d: 20, hot: 1, a: 'Quận 3, TP.HCM', time: '2 giờ' },
  { t: 'Fujifilm X-T20 body, ngoại hình 98%', img: 'detail-fujifilm.jpg', p: '9.800.000 ₫', a: 'Cầu Giấy, Hà Nội', time: '5 giờ', ex: 1 },
  { t: 'Tai nghe Sony WH-1000XM4 chống ồn, fullbox', img: 'detail-headphones.jpg', p: '3.900.000 ₫', o: '4.600.000 ₫', d: 15, a: 'Hải Châu, Đà Nẵng', time: '1 ngày', partner: 1 },
  { t: 'MacBook Air M1 2020 8GB/256GB, pin 92%', img: 'detail-macbook.jpg', p: '13.500.000 ₫', a: 'Quận 7, TP.HCM', time: '3 giờ', ex: 1, hot: 1 },
  { t: 'Kệ sách gỗ thông 5 tầng, tháo lắp dễ', img: 'detail-bookshelf.jpg', p: '850.000 ₫', a: 'Thủ Đức, TP.HCM', time: '20 phút' },
  { t: 'Đèn bàn vintage chân đồng thau', img: 'detail-lamp.jpg', p: '420.000 ₫', o: '600.000 ₫', d: 30, a: 'Hoàn Kiếm, Hà Nội', time: '6 giờ' },
  { t: 'Ghế gỗ cafe phong cách Bắc Âu (bộ 2 cái)', img: 'listing-chair.png', p: '700.000 ₫', a: 'Bình Thạnh, TP.HCM', time: '1 ngày', ex: 1 },
  { t: 'Máy ảnh film cổ, còn chụp tốt', img: 'listing-camera.png', p: '1.650.000 ₫', a: 'Ninh Kiều, Cần Thơ', time: '2 ngày', fav: 1 },
  { t: 'Đèn ngủ gốm men lam thủ công', img: 'listing-lamp.png', p: '280.000 ₫', a: 'Hội An, Quảng Nam', time: '4 giờ' },
  { t: 'Lens Canon EF 50mm f/1.8 STM như mới', img: 'detail-canon.jpg', p: '2.100.000 ₫', a: 'Đống Đa, Hà Nội', time: '8 giờ', partner: 1 },
  { t: 'MacBook Pro 13" 2019 i5, màn đẹp', img: 'detail-macbook.jpg', p: '11.200.000 ₫', o: '12.500.000 ₫', d: 10, a: 'Tân Bình, TP.HCM', time: '1 ngày' },
  { t: 'Tai nghe Bose QC35 II, đổi tai nghe khác', img: 'detail-headphones.jpg', p: null, a: 'Thanh Khê, Đà Nẵng', time: '3 ngày', ex: 1 },
  { t: 'Kệ trang trí 3 tầng gỗ sồi', img: 'detail-bookshelf.jpg', p: '560.000 ₫', a: 'Gò Vấp, TP.HCM', time: '12 giờ', fav: 1 },
  { t: 'Fujifilm XA-5 kèm lens kit, cho người mới', img: 'detail-fujifilm.jpg', p: '6.300.000 ₫', a: 'Hải An, Hải Phòng', time: '2 ngày' },
  { t: 'Ghế đọc sách gỗ tần bì', img: 'listing-chair.png', p: '450.000 ₫', o: '650.000 ₫', d: 31, a: 'Quận 1, TP.HCM', time: '7 giờ' },
  { t: 'Đèn cây đứng phòng khách', img: 'detail-lamp.jpg', p: '390.000 ₫', a: 'Long Biên, Hà Nội', time: '1 ngày' },
  { t: 'Máy ảnh compact du lịch, kèm thẻ 32GB', img: 'listing-camera.png', p: '1.200.000 ₫', a: 'Biên Hòa, Đồng Nai', time: '5 giờ', partner: 1 },
  { t: 'Đèn bàn gốm decor phòng ngủ', img: 'listing-lamp.png', p: '190.000 ₫', a: 'Quận 10, TP.HCM', time: '30 phút' },
];

function card(it, extra = '') {
  const tags = [
    it.d ? `<span class="tag red">-${it.d}%</span>` : '',
    it.hot ? `<span class="tag hot">Hot</span>` : '',
    it.ex ? `<span class="tag">Đổi được</span>` : '',
  ].join('');
  const price = it.p ? `<b class="${it.d ? 'red' : ''}">${it.p}</b>${it.o ? `<s>${it.o}</s>` : ''}` : `<b>Chỉ trao đổi</b>`;
  return `<a class="card ${extra}"><div class="ph"><img src="${MP}${it.img}"><div class="tags">${tags}</div>
    <span class="fav ${it.fav ? 'on' : ''}">${ic('heart')}</span></div>
    <div class="info"><div class="t">${it.partner ? '<span class="pt">Shop</span>' : ''}${it.t}</div>
    <div class="pr">${price}</div>
    <div class="meta">${ic('pin')}${it.a} · ${it.time}</div></div></a>`;
}

function header(active = '') {
  return `<header class="hd">
  <div class="wrap hd-top">
    <div class="grp"><a>Kênh người bán</a><i class="sep"></i><a>Tải ứng dụng</a><i class="sep"></i><span>Kết nối ${ic('fb')} ${ic('ig')}</span></div>
    <div class="grp"><a>${ic('bell')} Thông báo</a><a>${ic('help')} Trợ giúp</a><a>${ic('globe')} Tiếng Việt ${ic('down')}</a>
      <a class="me"><span class="ava ini">P</span><b>Phát</b></a></div>
  </div>
  <div class="wrap hd-main">
    <a class="logo"><img src="${A}logos/app-logo.png"><span>Restore</span></a>
    <div>
      <div class="search"><span class="area">${ic('pin')} TP. Hồ Chí Minh ${ic('down')}</span>
        <input value="Tìm đồ cũ, đồ trao đổi..."><button>${ic('search')} Tìm</button></div>
      <div class="kw"><span>MacBook cũ</span><span>Máy ảnh film</span><span>Kệ sách gỗ</span><span>Tai nghe Sony</span><span>Xe đạp thể thao</span><span>Đồ thú cưng</span><span>Đèn vintage</span></div>
    </div>
    <div class="hd-actions">
      <a class="icon-btn" title="Bảng tin">${ic('news')}</a>
      <a class="icon-btn" title="Tin nhắn">${ic('msg')}<span class="badge">3</span></a>
      <a class="icon-btn" title="Đã lưu">${ic('heart')}</a>
      <a class="btn btn-primary">${ic('plus')} Đăng tin</a>
    </div>
  </div>
</header>`;
}

function footer() {
  const col = (h, items) => `<div><h4>${h}</h4><ul>${items.map((x) => `<li>${x}</li>`).join('')}</ul></div>`;
  return `<footer class="ft"><div class="wrap">
  <div class="cols">
    ${col('CHĂM SÓC KHÁCH HÀNG', ['Trung tâm trợ giúp', 'Hướng dẫn mua bán', 'Hướng dẫn đăng tin', 'Mua bán an toàn', 'Báo cáo vi phạm', 'Liên hệ'])}
    ${col('VỀ RESTORE', ['Giới thiệu', 'Quy chế hoạt động', 'Chính sách bảo mật', 'Gói thành viên', 'Shop uy tín', 'Kênh người bán'])}
    <div><h4>THANH TOÁN</h4><div class="pay">
      <span><img src="${A}logos/vietqr.png"></span><span><img src="${A}logos/zalopay.png"></span><span class="t">COD</span><span class="t">Xu Restore</span></div></div>
    <div><h4>THEO DÕI</h4><ul><li class="ic">${ic('fb')} Facebook</li><li class="ic">${ic('ig')} Instagram</li><li class="ic">${ic('msg')} Zalo OA</li></ul></div>
    <div><h4>TẢI ỨNG DỤNG RESTORE</h4><div class="app"><div class="qr"></div><div class="stores"><span>App Store</span><span>Google Play</span></div></div></div>
  </div>
  <div class="bottom"><span>© 2026 Restore. Mua bán, trao đổi đồ cũ.</span><span>Tiếng Việt · English</span></div>
</div></footer>`;
}

function mount() {
  document.querySelectorAll('[data-header]').forEach((el) => (el.outerHTML = header()));
  document.querySelectorAll('[data-footer]').forEach((el) => (el.outerHTML = footer()));
  document.querySelectorAll('i[data-i]').forEach((el) => (el.outerHTML = ic(el.dataset.i)));
}
