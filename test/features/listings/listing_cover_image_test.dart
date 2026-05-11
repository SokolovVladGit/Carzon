import 'package:carzon/features/listings/presentation/widgets/listing_cover_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Card (non-Hero) path still fades via AnimatedOpacity while the first frame
/// is pending; asserting it here is brittle (sync decode / errors skip it).
void main() {
  testWidgets(
    'Hero-bound ListingCoverImage has no AnimatedOpacity under Hero',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ListingCoverImage(
              imageUrl: 'https://example.com/listing.jpg',
              heroTag: 'listing-cover-test',
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(Hero), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(Hero),
          matching: find.byType(AnimatedOpacity),
        ),
        findsNothing,
      );
    },
  );

  testWidgets('Hero-bound Image.network enables gaplessPlayback', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ListingCoverImage(
            imageUrl: 'https://example.com/listing.jpg',
            heroTag: 'listing-cover-test',
          ),
        ),
      ),
    );
    await tester.pump();

    final image = tester.widget<Image>(
      find.descendant(
        of: find.byType(ListingCoverImage),
        matching: find.byType(Image),
      ),
    );
    expect(image.gaplessPlayback, isTrue);
  });

  testWidgets('non-Hero Image.network keeps gaplessPlayback false', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ListingCoverImage(imageUrl: 'https://example.com/listing.jpg'),
        ),
      ),
    );
    await tester.pump();

    final image = tester.widget<Image>(
      find.descendant(
        of: find.byType(ListingCoverImage),
        matching: find.byType(Image),
      ),
    );
    expect(image.gaplessPlayback, isFalse);
  });
}
