import 'dart:async';

import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/sellers/domain/entities/seller_public_profile.dart';
import 'package:carzon/features/sellers/domain/usecases/get_seller_public_profile.dart';
import 'package:carzon/features/sellers/presentation/bloc/seller_trust_cubit.dart';
import 'package:carzon/features/sellers/presentation/bloc/seller_trust_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetSellerPublicProfile extends Mock
    implements GetSellerPublicProfile {}

void main() {
  test('load does not emit after the cubit is closed', () async {
    final useCase = _MockGetSellerPublicProfile();
    final pending = Completer<Result<SellerPublicProfile?>>();
    when(() => useCase(any())).thenAnswer((_) => pending.future);

    final cubit = SellerTrustCubit(useCase);
    final load = cubit.load('seller-1');
    await cubit.close();

    pending.complete(const Success<SellerPublicProfile?>(null));
    await load;

    expect(cubit.isClosed, isTrue);
    expect(cubit.state, const SellerTrustState.loading());
  });
}
