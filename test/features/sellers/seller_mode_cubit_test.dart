import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/core/errors/failures.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/sellers/domain/entities/my_seller_context.dart';
import 'package:carzon/features/sellers/domain/entities/seller_type.dart';
import 'package:carzon/features/sellers/domain/usecases/get_my_seller_context.dart';
import 'package:carzon/features/sellers/domain/usecases/set_my_seller_type.dart';
import 'package:carzon/features/sellers/presentation/bloc/seller_mode_cubit.dart';
import 'package:carzon/features/sellers/presentation/bloc/seller_mode_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockGet extends Mock implements GetMySellerContext {}

class _MockSet extends Mock implements SetMySellerType {}

void main() {
  late _MockGet getContext;
  late _MockSet setType;

  setUpAll(() {
    registerFallbackValue(SellerType.private);
  });

  setUp(() {
    getContext = _MockGet();
    setType = _MockSet();
  });

  SellerModeCubit cubit() =>
      SellerModeCubit(getMySellerContext: getContext, setMySellerType: setType);

  blocTest<SellerModeCubit, SellerModeState>(
    'load ready with private context',
    build: () {
      when(() => getContext()).thenAnswer(
        (_) async => const Success(
          MySellerContext(
            sellerType: SellerType.private,
            verifiedDealer: false,
          ),
        ),
      );
      return cubit();
    },
    act: (c) => c.load(),
    expect: () => [
      const SellerModeState(status: SellerModeStatus.loading),
      const SellerModeState(
        status: SellerModeStatus.ready,
        context: MySellerContext(
          sellerType: SellerType.private,
          verifiedDealer: false,
        ),
      ),
    ],
  );

  blocTest<SellerModeCubit, SellerModeState>(
    'unchanged save does not call RPC',
    build: () {
      when(() => getContext()).thenAnswer(
        (_) async => const Success(
          MySellerContext(sellerType: SellerType.dealer, verifiedDealer: true),
        ),
      );
      return cubit();
    },
    act: (c) async {
      await c.load();
      await c.save();
    },
    verify: (_) {
      verifyNever(() => setType(any()));
    },
  );

  blocTest<SellerModeCubit, SellerModeState>(
    'private to professional uses server result',
    build: () {
      when(() => getContext()).thenAnswer(
        (_) async => const Success(
          MySellerContext(
            sellerType: SellerType.private,
            verifiedDealer: false,
          ),
        ),
      );
      when(() => setType(SellerType.dealer)).thenAnswer(
        (_) async => const Success(
          MySellerContext(sellerType: SellerType.dealer, verifiedDealer: false),
        ),
      );
      return cubit();
    },
    act: (c) async {
      await c.load();
      c.select(SellerType.dealer);
      await c.save();
    },
    verify: (c) {
      expect(c.state.context?.sellerType, SellerType.dealer);
      expect(c.state.draftType, SellerType.dealer);
      verify(() => setType(SellerType.dealer)).called(1);
    },
  );

  blocTest<SellerModeCubit, SellerModeState>(
    'RPC failure keeps authoritative mode',
    build: () {
      when(() => getContext()).thenAnswer(
        (_) async => const Success(
          MySellerContext(
            sellerType: SellerType.private,
            verifiedDealer: false,
          ),
        ),
      );
      when(
        () => setType(any()),
      ).thenAnswer((_) async => const FailureResult(ServerFailure('nope')));
      return cubit();
    },
    act: (c) async {
      await c.load();
      c.select(SellerType.dealer);
      await c.save();
    },
    verify: (c) {
      expect(c.state.context?.sellerType, SellerType.private);
      expect(c.state.draftType, SellerType.dealer);
      expect(c.state.saveFailed, isTrue);
      expect(c.state.status, SellerModeStatus.ready);
    },
  );
}
