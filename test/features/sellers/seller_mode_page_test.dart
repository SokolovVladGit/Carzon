import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/core/errors/failures.dart';
import 'package:carzon/core/theme/app_theme.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/core/widgets/auth_required_prompt.dart';
import 'package:carzon/core/widgets/error_view.dart';
import 'package:carzon/core/widgets/loading_view.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/sellers/domain/entities/my_seller_context.dart';
import 'package:carzon/features/sellers/domain/entities/seller_type.dart';
import 'package:carzon/features/sellers/domain/usecases/get_my_seller_context.dart';
import 'package:carzon/features/sellers/domain/usecases/set_my_seller_type.dart';
import 'package:carzon/features/sellers/presentation/bloc/seller_mode_cubit.dart';
import 'package:carzon/features/sellers/presentation/pages/seller_mode_page.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/l10n_test_helpers.dart';

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class _MockGet extends Mock implements GetMySellerContext {}

class _MockSet extends Mock implements SetMySellerType {}

Widget _wrapChrome(SellerModeCubit cubit) {
  return MaterialApp(
    locale: const Locale('ru'),
    theme: AppTheme.light(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: sellerModeTestHarness(cubit: cubit, child: const SellerModeChrome()),
  );
}

void main() {
  late _MockGet getContext;
  late _MockSet setType;
  final l10n = ruStrings();

  setUpAll(() {
    registerFallbackValue(SellerType.private);
  });

  setUp(() {
    getContext = _MockGet();
    setType = _MockSet();
  });

  SellerModeCubit readyCubit({
    SellerType type = SellerType.private,
    bool verified = false,
  }) {
    when(() => getContext()).thenAnswer(
      (_) async =>
          Success(MySellerContext(sellerType: type, verifiedDealer: verified)),
    );
    return SellerModeCubit(
      getMySellerContext: getContext,
      setMySellerType: setType,
    )..load();
  }

  testWidgets('logged out uses AuthRequiredPrompt', (tester) async {
    final auth = _MockAuthCubit();
    when(() => auth.state).thenReturn(const AuthState.unauthenticated());
    whenListen(
      auth,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.unauthenticated(),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<AuthCubit>.value(
          value: auth,
          child: const SellerModePage(),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(AuthRequiredPrompt), findsOneWidget);
    expect(find.text(l10n.profileSignInRequired), findsOneWidget);
  });

  testWidgets('loading state', (tester) async {
    when(
      () => getContext(),
    ).thenAnswer((_) => Completer<Result<MySellerContext>>().future);
    final cubit = SellerModeCubit(
      getMySellerContext: getContext,
      setMySellerType: setType,
    )..load();
    await tester.pumpWidget(_wrapChrome(cubit));
    await tester.pump();
    expect(find.byType(LoadingView), findsOneWidget);
    await cubit.close();
  });

  testWidgets('current private and professional render', (tester) async {
    final privateCubit = readyCubit();
    await tester.pumpWidget(_wrapChrome(privateCubit));
    await tester.pumpAndSettle();
    expect(find.text(l10n.sellerModePrivateTitle), findsOneWidget);
    expect(find.byKey(const ValueKey('seller_mode_verified')), findsNothing);
    await privateCubit.close();

    final proCubit = readyCubit(type: SellerType.dealer, verified: true);
    await tester.pumpWidget(_wrapChrome(proCubit));
    await tester.pumpAndSettle();
    expect(find.text(l10n.sellerModeProfessionalTitle), findsOneWidget);
    expect(find.text(l10n.sellerModeVerified), findsOneWidget);
    await proCubit.close();
  });

  testWidgets('select without save does not mutate', (tester) async {
    final cubit = readyCubit();
    await tester.pumpWidget(_wrapChrome(cubit));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('seller_mode_option_professional')),
    );
    await tester.pump();
    verifyNever(() => setType(any()));
    expect(cubit.state.context?.sellerType, SellerType.private);
    expect(cubit.state.draftType, SellerType.dealer);
    await cubit.close();
  });

  testWidgets('unchanged save does not call RPC', (tester) async {
    final cubit = readyCubit();
    await tester.pumpWidget(_wrapChrome(cubit));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('seller_mode_save')));
    await tester.pump();
    verifyNever(() => setType(any()));
    await cubit.close();
  });

  testWidgets('save private to professional', (tester) async {
    when(() => setType(SellerType.dealer)).thenAnswer(
      (_) async => const Success(
        MySellerContext(sellerType: SellerType.dealer, verifiedDealer: false),
      ),
    );
    final cubit = readyCubit();
    await tester.pumpWidget(_wrapChrome(cubit));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('seller_mode_option_professional')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('seller_mode_save')));
    await tester.pumpAndSettle();
    verify(() => setType(SellerType.dealer)).called(1);
    expect(cubit.state.context?.sellerType, SellerType.dealer);
    await cubit.close();
  });

  testWidgets('save professional to private', (tester) async {
    when(() => setType(SellerType.private)).thenAnswer(
      (_) async => const Success(
        MySellerContext(sellerType: SellerType.private, verifiedDealer: false),
      ),
    );
    final cubit = readyCubit(type: SellerType.dealer);
    await tester.pumpWidget(_wrapChrome(cubit));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('seller_mode_option_private')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('seller_mode_save')));
    await tester.pumpAndSettle();
    expect(cubit.state.context?.sellerType, SellerType.private);
    await cubit.close();
  });

  testWidgets('RPC failure keeps authoritative mode', (tester) async {
    when(
      () => setType(any()),
    ).thenAnswer((_) async => const FailureResult(ServerFailure('nope')));
    final cubit = readyCubit();
    await tester.pumpWidget(_wrapChrome(cubit));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('seller_mode_option_professional')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('seller_mode_save')));
    await tester.pumpAndSettle();
    expect(cubit.state.context?.sellerType, SellerType.private);
    expect(find.text(l10n.sellerModeSaveFailed), findsOneWidget);
    await cubit.close();
  });

  testWidgets('load error can retry', (tester) async {
    when(
      () => getContext(),
    ).thenAnswer((_) async => const FailureResult(ServerFailure('x')));
    final cubit = SellerModeCubit(
      getMySellerContext: getContext,
      setMySellerType: setType,
    )..load();
    await tester.pumpWidget(_wrapChrome(cubit));
    await tester.pumpAndSettle();
    expect(find.byType(ErrorView), findsOneWidget);
    when(() => getContext()).thenAnswer(
      (_) async => const Success(
        MySellerContext(sellerType: SellerType.private, verifiedDealer: false),
      ),
    );
    await tester.tap(find.text(l10n.commonRetry));
    await tester.pumpAndSettle();
    expect(find.text(l10n.sellerModePrivateTitle), findsOneWidget);
    await cubit.close();
  });
}
