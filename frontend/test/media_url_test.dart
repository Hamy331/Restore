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
}
