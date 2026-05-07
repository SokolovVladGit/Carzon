import 'package:carzon/features/sellers/data/models/my_seller_profile_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses avatar_path from JSON', () {
    final m = MySellerProfileModel.fromJson({
      'display_name': 'Shop',
      'avatar_url': 'https://example.com/a.webp',
      'avatar_path': 'avatars/u1/20260101_abc.webp',
      'member_since': '2026-01-15T00:00:00Z',
      'public_visibility': true,
    });
    expect(m.displayName, 'Shop');
    expect(m.avatarUrl, 'https://example.com/a.webp');
    expect(m.avatarPath, 'avatars/u1/20260101_abc.webp');
    expect(m.publicVisibility, isTrue);
  });

  test('null avatar_path when absent', () {
    final m = MySellerProfileModel.fromJson({
      'display_name': null,
      'avatar_url': null,
      'member_since': '2026-01-15T00:00:00Z',
      'public_visibility': true,
    });
    expect(m.avatarPath, isNull);
  });
}
