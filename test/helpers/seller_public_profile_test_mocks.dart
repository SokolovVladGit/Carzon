import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/sellers/domain/entities/seller_public_profile.dart';
import 'package:carzon/features/sellers/domain/usecases/get_seller_public_profile.dart';
import 'package:mocktail/mocktail.dart';

/// Shared mock for listing-details tests — register with GetIt in `setUp`.
class MockGetSellerPublicProfile extends Mock
    implements GetSellerPublicProfile {}

/// Default: RPC yields no visible profile — seller trust section stays hidden.
void stubSellerPublicProfileHidden(MockGetSellerPublicProfile mock) {
  when(
    () => mock(any()),
  ).thenAnswer((_) async => const Success<SellerPublicProfile?>(null));
}
