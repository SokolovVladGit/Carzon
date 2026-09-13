import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/app/di/injection.dart';
import 'package:carzon/features/create_listing/domain/entities/manual_smart_fill_refinement.dart';
import 'package:carzon/features/create_listing/presentation/bloc/create_listing_cubit.dart';
import 'package:carzon/features/create_listing/presentation/bloc/manual_smart_fill_cubit.dart';
import 'package:carzon/features/create_listing/presentation/bloc/manual_smart_fill_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockManualSmartFillCubit extends MockCubit<ManualSmartFillState>
    implements ManualSmartFillCubit {}

void stubCreateListingVinResolve(
  CreateListingCubit cubit, {
  bool registerSmartFill = true,
}) {
  when(() => cubit.onVinChanged(any())).thenReturn(null);
  when(cubit.enterManualMode).thenReturn(null);
  when(cubit.confirmSuggestion).thenReturn(null);
  when(cubit.retryResolve).thenAnswer((_) async {});
  stubCreateListingDefaults(cubit);
  if (registerSmartFill) {
    registerIdleManualSmartFillCubit();
  }
}

MockManualSmartFillCubit registerIdleManualSmartFillCubit() {
  registerFallbackValue(
    const ManualSmartFillRefinementOption(
      id: 'fallback',
      kind: ManualSmartFillRefinementKind.body,
      candidateCount: 0,
      bodyType: 'hatchback',
    ),
  );
  final cubit = MockManualSmartFillCubit();
  when(() => cubit.state).thenReturn(const ManualSmartFillState.idle());
  whenListen(
    cubit,
    const Stream<ManualSmartFillState>.empty(),
    initialState: const ManualSmartFillState.idle(),
  );
  when(
    () => cubit.lookup(
      make: any(named: 'make'),
      model: any(named: 'model'),
      year: any(named: 'year'),
    ),
  ).thenReturn(null);
  when(
    () => cubit.answer(
      attribute: any(named: 'attribute'),
      value: any(named: 'value'),
    ),
  ).thenAnswer((_) async {});
  when(() => cubit.selectOption(any())).thenAnswer((_) async {});
  when(cubit.skipCurrent).thenAnswer((_) async {});
  when(cubit.dismissClarification).thenReturn(null);
  when(cubit.restart).thenAnswer((_) async {});
  when(cubit.reset).thenReturn(null);
  when(cubit.cancelForVinAuthority).thenReturn(null);
  when(cubit.cancelForManualOverride).thenReturn(null);
  when(cubit.retry).thenAnswer((_) async {});
  sl.registerFactory<ManualSmartFillCubit>(() => cubit);
  return cubit;
}

void stubCreateListingDefaults(CreateListingCubit cubit) {
  when(
    () => cubit.loadListingDefaults(userId: any(named: 'userId')),
  ).thenAnswer((_) async {});
  when(cubit.markPhoneEdited).thenReturn(null);
  when(cubit.markTelegramEdited).thenReturn(null);
  when(cubit.markWhatsappEdited).thenReturn(null);
  when(cubit.markRegionEdited).thenReturn(null);
  when(cubit.markCityEdited).thenReturn(null);
}

Future<void> openCreateListingManualIdentity(WidgetTester tester) async {
  final brand = find.byKey(const ValueKey('create_listing_brand_field'));
  if (brand.evaluate().isNotEmpty) return;
  final action = find.byKey(const ValueKey('create_listing_enter_manually'));
  expect(action, findsOneWidget);
  await tester.scrollUntilVisible(
    action,
    120,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(action);
  await tester.pumpAndSettle();
}

Future<void> expandCreateListingAdditionalDetails(WidgetTester tester) async {
  final tile = find.byKey(const ValueKey('create_listing_additional_details'));
  await tester.scrollUntilVisible(
    tile,
    180,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(tile);
  await tester.pumpAndSettle();
}
