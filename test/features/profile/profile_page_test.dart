import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/app/di/injection.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/auth/domain/entities/auth_user.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/profile/presentation/pages/profile_page.dart';
import 'package:carzon/features/sellers/data/models/my_seller_profile_model.dart';
import 'package:carzon/features/sellers/domain/repositories/sellers_repository.dart';
import 'package:carzon/features/sellers/domain/seller_display_name_constraints.dart';
import 'package:carzon/features/sellers/domain/usecases/clear_seller_avatar.dart';
import 'package:carzon/features/sellers/domain/usecases/get_my_seller_profile.dart';
import 'package:carzon/features/sellers/domain/usecases/update_my_seller_display_name.dart';
import 'package:carzon/features/sellers/domain/usecases/upload_seller_avatar.dart';
import 'package:carzon/features/sellers/presentation/bloc/public_seller_identity_cubit.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/l10n_test_helpers.dart';

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class _MockSellersRepository extends Mock implements SellersRepository {}

Widget _wrap(Widget child, AuthCubit cubit) {
  return MaterialApp(
    locale: const Locale('ru'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: BlocProvider<AuthCubit>.value(value: cubit, child: child),
  );
}

MySellerProfileModel _myProfile({
  String? displayName,
  String? avatarUrl,
  String? avatarPath,
}) => MySellerProfileModel(
  displayName: displayName,
  avatarUrl: avatarUrl,
  avatarPath: avatarPath,
  memberSince: DateTime.utc(2026, 4, 1),
  publicVisibility: true,
);

void main() {
  late _MockAuthCubit cubit;
  late _MockSellersRepository sellersRepo;
  final l10n = ruStrings();

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  setUp(() async {
    cubit = _MockAuthCubit();
    sellersRepo = _MockSellersRepository();
    await sl.reset();

    when(
      () => sellersRepo.getSellerPublicProfile(any()),
    ).thenAnswer((_) async => const Success(null));
    when(
      () => sellersRepo.getMySellerProfile(),
    ).thenAnswer((_) async => Success(_myProfile(displayName: 'Saved Shop')));
    when(() => sellersRepo.updateMySellerDisplayName(any())).thenAnswer(
      (inv) async => Success(
        _myProfile(displayName: inv.positionalArguments[0] as String?),
      ),
    );
    when(
      () => sellersRepo.uploadSellerAvatar(
        bytes: any(named: 'bytes'),
        contentType: any(named: 'contentType'),
        previousAvatarStoragePath: any(named: 'previousAvatarStoragePath'),
      ),
    ).thenAnswer((_) async => Success(_myProfile(displayName: 'Saved Shop')));
    when(
      () => sellersRepo.clearSellerAvatar(
        previousAvatarStoragePath: any(named: 'previousAvatarStoragePath'),
      ),
    ).thenAnswer((_) async => Success(_myProfile(displayName: 'Saved Shop')));

    sl.registerLazySingleton<SellersRepository>(() => sellersRepo);
    sl.registerFactory(() => GetMySellerProfile(sl<SellersRepository>()));
    sl.registerFactory(
      () => UpdateMySellerDisplayName(sl<SellersRepository>()),
    );
    sl.registerFactory(() => UploadSellerAvatar(sl<SellersRepository>()));
    sl.registerFactory(() => ClearSellerAvatar(sl<SellersRepository>()));
    sl.registerFactory(
      () => PublicSellerIdentityCubit(
        getMySellerProfile: sl<GetMySellerProfile>(),
        updateMySellerDisplayName: sl<UpdateMySellerDisplayName>(),
        uploadSellerAvatar: sl<UploadSellerAvatar>(),
        clearSellerAvatar: sl<ClearSellerAvatar>(),
      ),
    );
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets(
    'unauthenticated: shows the sign-in prompt and a Sign in button',
    (tester) async {
      when(() => cubit.state).thenReturn(const AuthState.unauthenticated());
      whenListen(
        cubit,
        const Stream<AuthState>.empty(),
        initialState: const AuthState.unauthenticated(),
      );

      await tester.pumpWidget(_wrap(const ProfilePage(), cubit));

      expect(find.text(l10n.profileSignInRequired), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, l10n.commonSignIn),
        findsOneWidget,
      );
      expect(find.text(l10n.profileSignOut), findsNothing);
      expect(find.text(l10n.profileMyListings), findsNothing);
    },
  );

  testWidgets('authenticated: shows identity, public seller section, actions', (
    tester,
  ) async {
    const user = AuthUser(
      id: 'u1',
      email: 'seller@example.com',
      fullName: 'Ana Popescu',
    );
    when(() => cubit.state).thenReturn(const AuthState.authenticated(user));
    whenListen(
      cubit,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.authenticated(user),
    );

    await tester.pumpWidget(_wrap(const ProfilePage(), cubit));
    await tester.pumpAndSettle();

    expect(find.text('Ana Popescu'), findsOneWidget);
    expect(find.text('seller@example.com'), findsOneWidget);
    expect(find.text(l10n.profilePublicSellerAvatarTitle), findsOneWidget);
    expect(find.text(l10n.profilePublicSellerNameTitle), findsOneWidget);
    expect(find.text('Saved Shop'), findsOneWidget);
    expect(
      find.text(l10n.profilePublicSellerAvatarChangePhoto),
      findsOneWidget,
    );

    await tester.drag(find.byType(ListView), const Offset(0, -900));
    await tester.pumpAndSettle();

    expect(find.byType(ListTile), findsNWidgets(4));
    expect(find.text(l10n.profileSignOut), findsOneWidget);
    expect(find.byKey(const ValueKey('profileSignOutButton')), findsOneWidget);
  });

  testWidgets('authenticated without full name: falls back to showing email', (
    tester,
  ) async {
    const user = AuthUser(id: 'u1', email: 'seller@example.com');
    when(() => cubit.state).thenReturn(const AuthState.authenticated(user));
    whenListen(
      cubit,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.authenticated(user),
    );

    await tester.pumpWidget(_wrap(const ProfilePage(), cubit));
    await tester.pumpAndSettle();

    expect(find.text('seller@example.com'), findsOneWidget);
  });

  testWidgets('save posts trimmed display name', (tester) async {
    const user = AuthUser(id: 'u1', email: 'a@b.com', fullName: 'T');
    when(() => cubit.state).thenReturn(const AuthState.authenticated(user));
    whenListen(
      cubit,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.authenticated(user),
    );

    await tester.pumpWidget(_wrap(const ProfilePage(), cubit));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '  New Name  ');
    await tester.tap(
      find.widgetWithText(FilledButton, l10n.profilePublicSellerNameSave),
    );
    await tester.pumpAndSettle();

    verify(() => sellersRepo.updateMySellerDisplayName('New Name')).called(1);
    expect(find.text(l10n.profilePublicSellerNameSaved), findsOneWidget);
  });

  testWidgets(
    'text field enforces max length (cannot exceed backend limit via UI)',
    (tester) async {
      const user = AuthUser(id: 'u1', email: 'a@b.com');
      when(() => cubit.state).thenReturn(const AuthState.authenticated(user));
      whenListen(
        cubit,
        const Stream<AuthState>.empty(),
        initialState: const AuthState.authenticated(user),
      );

      await tester.pumpWidget(_wrap(const ProfilePage(), cubit));
      await tester.pumpAndSettle();

      final maxPlusOne = List.filled(
        SellerDisplayNameConstraints.maxLength + 1,
        'z',
      ).join();
      await tester.enterText(find.byType(TextField), maxPlusOne);
      await tester.tap(
        find.widgetWithText(FilledButton, l10n.profilePublicSellerNameSave),
      );
      await tester.pumpAndSettle();

      final atMostMax = List.filled(
        SellerDisplayNameConstraints.maxLength,
        'z',
      ).join();
      verify(() => sellersRepo.updateMySellerDisplayName(atMostMax)).called(1);
      expect(find.text(l10n.profilePublicSellerNameSaved), findsOneWidget);
    },
  );

  testWidgets('validation blocks email-shaped name', (tester) async {
    const user = AuthUser(id: 'u1', email: 'a@b.com');
    when(() => cubit.state).thenReturn(const AuthState.authenticated(user));
    whenListen(
      cubit,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.authenticated(user),
    );

    await tester.pumpWidget(_wrap(const ProfilePage(), cubit));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'buyer@shop.md');
    await tester.tap(
      find.widgetWithText(FilledButton, l10n.profilePublicSellerNameSave),
    );
    await tester.pumpAndSettle();

    verifyNever(() => sellersRepo.updateMySellerDisplayName(any()));
    expect(
      find.text(l10n.profilePublicSellerNameLooksLikeEmail),
      findsOneWidget,
    );
  });

  testWidgets('clearing field saves null display name', (tester) async {
    const user = AuthUser(id: 'u1', email: 'a@b.com');
    when(() => cubit.state).thenReturn(const AuthState.authenticated(user));
    whenListen(
      cubit,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.authenticated(user),
    );

    await tester.pumpWidget(_wrap(const ProfilePage(), cubit));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '');
    await tester.tap(
      find.widgetWithText(FilledButton, l10n.profilePublicSellerNameSave),
    );
    await tester.pumpAndSettle();

    verify(() => sellersRepo.updateMySellerDisplayName(null)).called(1);
  });

  testWidgets('Sign out button calls AuthCubit.signOut', (tester) async {
    const user = AuthUser(id: 'u1', email: 'seller@example.com');
    when(() => cubit.state).thenReturn(const AuthState.authenticated(user));
    when(() => cubit.signOut()).thenAnswer((_) async {});
    whenListen(
      cubit,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.authenticated(user),
    );

    await tester.pumpWidget(_wrap(const ProfilePage(), cubit));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -800));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('profileSignOutButton')));
    await tester.pump();

    verify(() => cubit.signOut()).called(1);
  });

  testWidgets('without avatar: remove photo control is absent', (tester) async {
    const user = AuthUser(id: 'u1', email: 'a@b.com');
    when(
      () => sellersRepo.getMySellerProfile(),
    ).thenAnswer((_) async => Success(_myProfile(displayName: 'N')));
    when(() => cubit.state).thenReturn(const AuthState.authenticated(user));
    whenListen(
      cubit,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.authenticated(user),
    );

    await tester.pumpWidget(_wrap(const ProfilePage(), cubit));
    await tester.pumpAndSettle();

    expect(find.text(l10n.profilePublicSellerAvatarRemovePhoto), findsNothing);
  });

  testWidgets('with avatar URL: remove photo control is visible', (
    tester,
  ) async {
    const user = AuthUser(id: 'u1', email: 'a@b.com');
    when(() => sellersRepo.getMySellerProfile()).thenAnswer(
      (_) async => Success(
        _myProfile(
          displayName: 'N',
          avatarUrl: 'https://example.com/a.jpg',
          avatarPath: 'avatars/u1/a.jpg',
        ),
      ),
    );
    when(() => cubit.state).thenReturn(const AuthState.authenticated(user));
    whenListen(
      cubit,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.authenticated(user),
    );

    await tester.pumpWidget(_wrap(const ProfilePage(), cubit));
    await tester.pumpAndSettle();

    expect(
      find.text(l10n.profilePublicSellerAvatarRemovePhoto),
      findsOneWidget,
    );
  });
}
