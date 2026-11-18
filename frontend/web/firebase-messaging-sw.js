// Service worker nhận push FCM trên trình duyệt khi tab ReStore đóng / ở nền.
// firebase_messaging tự đăng ký file này (phải nằm ở gốc web/). Cấu hình dưới đây
// là cấu hình web công khai (giống lib/firebase_options.dart), không có khoá bí mật.

// Bấm thông báo: mở / chuyển tới tab ReStore ở đúng trang (data.link của thông báo).
// Đăng ký trước khi nạp Firebase để dùng cách mở trang của app thay cho mặc định.
self.addEventListener('notificationclick', (event) => {
  event.stopImmediatePropagation();
  event.notification.close();
  const message = event.notification.data && event.notification.data.FCM_MSG;
  const link = (message && message.data && message.data.link) || '/notifications';
  // App dùng URL dạng hash (/#/listings/...)
  const url = `${self.location.origin}/#${link.startsWith('/') ? link : '/notifications'}`;
  event.waitUntil((async () => {
    const tabs = await clients.matchAll({ type: 'window', includeUncontrolled: true });
    const tab = tabs.find((client) => client.url.startsWith(self.location.origin));
    if (tab) {
      await tab.focus();
      return tab.navigate(url);
    }
    return clients.openWindow(url);
  })());
});

importScripts('https://www.gstatic.com/firebasejs/12.19.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/12.19.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyAryMG9mf-zjMXEe1aFI5vgFH1VBrZ1Ilc',
  appId: '1:592018871802:web:7f8eeaa69e4b2dc6d4c043',
  messagingSenderId: '592018871802',
  projectId: 'restore-5cfcb',
  authDomain: 'restore-5cfcb.firebaseapp.com',
  storageBucket: 'restore-5cfcb.firebasestorage.app',
});

// Push có phần notification: Firebase tự hiện thông báo hệ thống khi tab không mở
firebase.messaging();
