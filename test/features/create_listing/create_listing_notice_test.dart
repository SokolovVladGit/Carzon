import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/app/di/injection.dart';
import 'package:carzon/features/auth/domain/entities/auth_user.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/create_listing/presentation/bloc/create_listing_cubit.dart';
import 'package:carzon/features/create_listing/presentation/bloc/create_listing_state.dart';
import 'package:carzon/features/create_listing/presentation/pages/create_listing_page.dart';
import 'package:carzon/features/create_listing/presentation/widgets/create_listing_contact_notice.dart';
import 'package:carzon/features/create_listing/presentation/widgets/premium_listing_controls.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:carzon/shared/ui/carzon_icons.dart';
import 'package:carzon/shared/ui/whatsapp_contact_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/l10n_test_helpers.dart';

class _MockCreateCubit extends MockCubit<CreateListingState>
    implements CreateListingCubit {}

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

void main() {
  late _MockCreateCubit createCubit;
  late _MockAuthCubit authCubit;
  final l10n = ruStrings();

  setUp(() async {
    await sl.reset();
    createCubit = _MockCreateCubit();
    authCubit = _MockAuthCubit();

    when(() => createCubit.state).thenReturn(const CreateListingState.idle());
    whenListen(
      createCubit,
      const Stream<CreateListingState>.empty(),
      initialState: const CreateListingState.idle(),
    );

    const user = AuthUser(id: 'u1', email: 'seller@example.com');
    when(() => authCubit.state).thenReturn(const AuthState.authenticated(user));
    whenListen(
      authCubit,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.authenticated(user),
    );

    sl.registerFactory<CreateListingCubit>(() => createCubit);
  });

  tearDown(() async {
    await sl.reset();
  });

  Widget wrap() => MaterialApp(
    locale: const Locale('ru'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: BlocProvider<AuthCubit>.value(
      value: authCubit,
      child: const CreateListingPage(),
    ),
  );

  testWidgets('renders the contact notice near the contact fields and keeps it '
      'above the phone input', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pump();

    expect(find.byType(CreateListingContactNotice), findsOneWidget);
    expect(find.text(l10n.createListingContactNotice), findsOneWidget);
    expect(find.text(l10n.createListingWhatsAppTitle), findsOneWidget);
    expect(find.text(l10n.createListingWhatsAppSubtitle), findsOneWidget);
    expect(find.text(l10n.createListingTelegramPlaceholder), findsOneWidget);
    expect(find.byIcon(CarzonIcons.phone), findsOneWidget);
    expect(find.byIcon(CarzonIcons.send), findsOneWidget);
    expect(find.byType(WhatsappContactIcon), findsOneWidget);
    expect(find.byType(PremiumWhatsAppToggleRow), findsOneWidget);

    // The notice must sit above the Phone field in the scroll order
    // so the seller reads the warning before entering a number.
    final noticeCenter = tester.getCenter(
      find.byType(CreateListingContactNotice),
    );
    final phoneCenter = tester.getCenter(
      find.widgetWithText(TextFormField, l10n.fieldPhone),
    );
    expect(noticeCenter.dy, lessThan(phoneCenter.dy));
  });

  testWidgets(
    'contact icons stay aligned and WhatsApp copy does not hit the switch',
    (tester) async {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      addTearDown(() async {
        await binding.setSurfaceSize(null);
      });
      await binding.setSurfaceSize(const Size(320, 800));
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 800),
            textScaler: TextScaler.linear(1.3),
          ),
          child: wrap(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(PremiumWhatsAppToggleRow));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final subtitle = tester.getRect(
        find.text(l10n.createListingWhatsAppSubtitle),
      );
      final toggle = tester.getRect(find.byType(Switch));
      expect(subtitle.right, lessThanOrEqualTo(toggle.left + 0.5));
    },
  );
}
