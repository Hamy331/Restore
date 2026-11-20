import 'package:flutter_test/flutter_test.dart';
import 'package:restore/core/network/media_url.dart';

void main() {
  test('relative media paths get the API origin, others stay as they are', () {
    const api = 'http://10.0.2.2:3000/api/v1';
    expect(
      resolveMediaUrl('/api/v1/media/feeds/a.jpg', apiBaseUrl: api),
      'http://10.0.2.2:3000/api/v1/media/feeds/a.jpg',
    );
    expect(
      resolveMediaUrl('https://cdn.example/a.jpg', apiBaseUrl: api),
      'https://cdn.example/a.jpg',
    );
    expect(resolveMediaUrl(null, apiBaseUrl: api), isNull);
  });

  test('server images get the smallest thumbnail that is wide enough', () {
    const api = 'http://10.0.2.2:3000/api/v1';
    const listing = 'http://10.0.2.2:3000/api/v1/listings/media/a.jpg';
    const feed = 'http://10.0.2.2:3000/api/v1/media/feeds/u_a.jpg';
    expect(thumbnailUrl(listing, 160, apiBaseUrl: api), '$listing?w=240');
    expect(thumbnailUrl(listing, 480, apiBaseUrl: api), '$listing?w=480');
    expect(thumbnailUrl(feed, 900, apiBaseUrl: api), '$feed?w=960');
    // Ảnh lớn, không giới hạn cỡ, ảnh ngoài hoặc ảnh nội dung: giữ nguyên
    expect(thumbnailUrl(listing, 1200, apiBaseUrl: api), listing);
    expect(thumbnailUrl(listing, null, apiBaseUrl: api), listing);
    expect(
      thumbnailUrl('https://cdn.example/a.jpg', 480, apiBaseUrl: api),
      'https://cdn.example/a.jpg',
    );
    const content = 'http://10.0.2.2:3000/api/v1/content/media/a.jpg';
    expect(thumbnailUrl(content, 480, apiBaseUrl: api), content);
  });
}
