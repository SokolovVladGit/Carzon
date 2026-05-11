import 'package:carzon/core/errors/failures.dart';
import 'package:carzon/core/presentation/localized_user_failure_message.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n_test_helpers.dart';

void main() {
  final l10n = ruStrings();

  group('localizedUserFailureMessage', () {
    test('network failure uses connectivity copy (not raw text)', () {
      const failure = NetworkFailure('Failed host lookup: xyz');
      final msg = localizedUserFailureMessage(l10n, failure);
      expect(msg, l10n.userErrorNetworkCheckConnection);
      expect(msg.contains('host'), isFalse);
    });

    test('PostgREST-like English payload is never shown verbatim', () {
      final failure = ServerFailure(
        '{"code":"PGRST301","details":"blah"}',
        postgrestCode: 'PGRST301',
      );
      final msg = localizedUserFailureMessage(l10n, failure);
      expect(msg.contains('PGRST'), isFalse);
      expect(msg.contains('json'), isFalse);
      expect(msg, l10n.userErrorGenericTryAgain);
    });

    test('relation/table wording maps to generic, not leaked', () {
      const failure = ServerFailure(
        'relation "public.secret_table" does not exist',
      );
      final msg = localizedUserFailureMessage(l10n, failure);
      expect(msg.toLowerCase().contains('relation'), isFalse);
      expect(msg.contains('public.'), isFalse);
    });

    test('listing details + not-found uses unavailable copy', () {
      final failure = ServerFailure('', postgrestCode: 'PGRST116');
      final msg = localizedUserFailureMessage(
        l10n,
        failure,
        surface: LocalizedFailureSurface.listingDetails,
      );
      expect(msg, l10n.listingUnavailableOrDeleted);
    });

    test(
      'listing feed surfaces feed load wording for opaque server errors',
      () {
        const failure = ServerFailure('internal error');
        final msg = localizedUserFailureMessage(
          l10n,
          failure,
          surface: LocalizedFailureSurface.listingsFeed,
        );
        expect(msg, l10n.listingsLoadFailed);
      },
    );

    test('permission-style server failures map to permission copy', () {
      const failure = ServerFailure('permission denied for table listings');
      final msg = localizedUserFailureMessage(l10n, failure);
      expect(msg, l10n.userErrorInsufficientPermission);
    });

    test('storage/mime-ish failures map to photo upload copy', () {
      const failure = ServerFailure('mime type application/foo not allowed');
      final msg = localizedUserFailureMessage(l10n, failure);
      expect(msg, l10n.userErrorUploadPhotoTryAgain);
    });

    test(
      'auth failure uses surface-appropriate wording on feed vs generic',
      () {
        expect(
          localizedUserFailureMessage(
            l10n,
            const AuthFailure('JWT expired'),
            surface: LocalizedFailureSurface.listingsFeed,
          ),
          l10n.listingsLoadFailed,
        );
        expect(
          localizedUserFailureMessage(
            l10n,
            const AuthFailure('JWT expired'),
            surface: LocalizedFailureSurface.generic,
          ),
          l10n.userErrorGenericTryAgain,
        );
      },
    );

    test('seller avatar unsupported format keeps product copy', () {
      expect(
        localizedUserFailureMessage(l10n, SellerAvatarUnsupportedFormat()),
        l10n.profilePublicSellerAvatarUnsupportedType,
      );
    });
  });
}
