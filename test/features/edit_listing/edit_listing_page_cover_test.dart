import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/app/di/injection.dart';
import 'package:carzon/features/create_listing/domain/entities/cover_image_upload.dart';
import 'package:carzon/features/edit_listing/domain/entities/edit_listing_input.dart';
import 'package:carzon/features/edit_listing/presentation/bloc/edit_listing_cubit.dart';
import 'package:carzon/features/edit_listing/presentation/bloc/edit_listing_state.dart';
import 'package:carzon/features/edit_listing/presentation/pages/edit_listing_page.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/l10n_test_helpers.dart';

class _MockEditCubit extends MockCubit<EditListingState>
    implements EditListingCubit {}

Listing _seed({String? coverImageUrl}) => Listing(
      id: 'l1',
      title: 'VW Golf',
      make: 'Volkswagen',
      model: 'Golf',
      year: 2016,
      priceEur: 8900,
      mileageKm: 120000,
      type: ListingType.sale,
      city: 'Chișinău',
      marketRegion: MarketRegion.moldova,
      createdAt: DateTime.utc(2026, 4, 1),
      status: ListingStatus.active,
      sellerId: 's1',
      contactPhone: '+373 690 00001',
      coverImageUrl: coverImageUrl,
    );

// Minimal valid 1x1 transparent PNG so `Image.memory` can decode the bytes
// without throwing inside widget tests.
final Uint8List _validPngBytes = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x00, 0x00,
  0x00, 0x0d, 0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01,
  0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1f,
  0x15, 0xc4, 0x89, 0x00, 0x00, 0x00, 0x0d, 0x49, 0x44, 0x41,
  0x54, 0x78, 0x9c, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00,
  0x01, 0x0d, 0x0a, 0x2d, 0xb4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4e, 0x44, 0xae, 0x42, 0x60, 0x82,
]);

CoverImageUpload _upload() => CoverImageUpload(
      sellerId: 's1',
      bytes: _validPngBytes,
      contentType: 'image/png',
    );

void main() {
  late _MockEditCubit cubit;
  final l10n = ruStrings();

  setUpAll(() {
    registerFallbackValue(_upload());
    registerFallbackValue(
      EditListingInput(
        listingId: 'x',
        title: 'x',
        make: 'x',
        model: 'x',
        year: 2020,
        priceEur: 1,
        mileageKm: 1,
        type: ListingType.sale,
        city: 'x',
        marketRegion: MarketRegion.moldova,
        contactPhone: '+373 000 00000',
      ),
    );
  });

  setUp(() async {
    await sl.reset();
    cubit = _MockEditCubit();
    // `EditListingPage.build` triggers `load(listingId)` on the cubit;
    // stub it out so the mock can respond.
    when(() => cubit.load(any())).thenAnswer((_) async {});
    sl.registerFactory<EditListingCubit>(() => cubit);
  });

  tearDown(() async {
    await sl.reset();
  });

  void stubState(EditListingState initial, {EditListingState? emit}) {
    when(() => cubit.state).thenReturn(emit ?? initial);
    whenListen(
      cubit,
      emit == null
          ? const Stream<EditListingState>.empty()
          : Stream<EditListingState>.value(emit),
      initialState: initial,
    );
  }

  Widget wrap({EditListingImagePicker? picker}) => MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: EditListingPage(
          listingId: 'l1',
          imagePicker: picker,
        ),
      );

  testWidgets(
    'shows current cover network preview, Replace photo, and Remove photo '
    'when the listing has a cover URL',
    (tester) async {
      stubState(EditListingState.ready(
        _seed(coverImageUrl: 'https://cdn.example.com/cover.jpg'),
      ));

      await tester.pumpWidget(wrap());
      await tester.pump();

      expect(find.byType(Image), findsWidgets);
      expect(find.text(l10n.coverReplacePhoto), findsOneWidget);
      expect(find.text(l10n.coverRemovePhoto), findsOneWidget);
      expect(find.text(l10n.coverAddPhoto), findsNothing);
    },
  );

  testWidgets(
    'shows Add photo action when no cover URL is present',
    (tester) async {
      stubState(EditListingState.ready(_seed()));

      await tester.pumpWidget(wrap());
      await tester.pump();

      expect(find.text(l10n.coverAddPhoto), findsWidgets);
      expect(find.text(l10n.coverReplacePhoto), findsNothing);
      expect(find.text(l10n.coverRemovePhoto), findsNothing);
    },
  );

  testWidgets(
    'tapping Remove photo stages a cover removal via the cubit',
    (tester) async {
      stubState(EditListingState.ready(
        _seed(coverImageUrl: 'https://cdn.example.com/cover.jpg'),
      ));
      when(() => cubit.stageCoverRemoval()).thenReturn(null);

      await tester.pumpWidget(wrap());
      await tester.pump();

      final removeFinder = find.text(l10n.coverRemovePhoto);
      await tester.ensureVisible(removeFinder);
      await tester.pumpAndSettle();
      await tester.tap(removeFinder);
      await tester.pump();

      verify(() => cubit.stageCoverRemoval()).called(1);
    },
  );

  testWidgets(
    'pending removal state shows the "will be removed" notice and '
    'a Cancel removal action',
    (tester) async {
      stubState(EditListingState.ready(
        _seed(coverImageUrl: 'https://cdn.example.com/cover.jpg'),
      ).copyWith(pendingCoverRemoval: true));

      await tester.pumpWidget(wrap());
      await tester.pump();

      expect(
        find.text(l10n.coverWillBeRemovedNotice),
        findsOneWidget,
      );
      expect(find.text(l10n.coverCancelRemoval), findsOneWidget);
    },
  );

  testWidgets(
    'pending replacement state shows the "new photo" notice and a '
    'Cancel change action',
    (tester) async {
      stubState(EditListingState.ready(
        _seed(coverImageUrl: 'https://cdn.example.com/cover.jpg'),
      ).copyWith(pendingCoverReplacement: _upload()));

      await tester.pumpWidget(wrap());
      await tester.pump();

      expect(
        find.text(l10n.coverWillBeReplacedNotice),
        findsOneWidget,
      );
      expect(find.text(l10n.coverChangePhoto), findsOneWidget);
      expect(find.text(l10n.coverCancelChange), findsOneWidget);
    },
  );

  testWidgets(
    'tapping Replace photo invokes the injected image picker and '
    'stages the result on the cubit',
    (tester) async {
      stubState(EditListingState.ready(
        _seed(coverImageUrl: 'https://cdn.example.com/cover.jpg'),
      ));
      when(() => cubit.stageCoverReplacement(any())).thenReturn(null);

      Future<XFile?> fakePicker({
        required ImageSource source,
        required double maxWidth,
        required int imageQuality,
      }) async {
        return XFile.fromData(
          _validPngBytes,
          name: 'new.png',
          mimeType: 'image/png',
        );
      }

      await tester.pumpWidget(wrap(picker: fakePicker));
      await tester.pump();

      final replaceFinder = find.text(l10n.coverReplacePhoto);
      await tester.ensureVisible(replaceFinder);
      await tester.pumpAndSettle();
      await tester.tap(replaceFinder);
      await tester.pumpAndSettle();

      final captured =
          verify(() => cubit.stageCoverReplacement(captureAny())).captured;
      expect(captured, hasLength(1));
      final CoverImageUpload upload = captured.single as CoverImageUpload;
      expect(upload.sellerId, 's1');
      expect(upload.bytes, _validPngBytes);
      expect(upload.contentType, 'image/png');
    },
  );

  testWidgets(
    'tapping Save submits the form through the cubit',
    (tester) async {
      stubState(EditListingState.ready(
        _seed(coverImageUrl: 'https://cdn.example.com/cover.jpg'),
      ));
      when(() => cubit.save(any())).thenAnswer((_) async {});

      await tester.pumpWidget(wrap());
      await tester.pump();

      final saveFinder = find.text(l10n.saveChanges);
      await tester.ensureVisible(saveFinder);
      await tester.pumpAndSettle();
      await tester.tap(saveFinder);
      await tester.pump();

      verify(() => cubit.save(any())).called(1);
    },
  );
}
