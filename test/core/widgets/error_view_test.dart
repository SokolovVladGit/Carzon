import 'package:carzon/core/widgets/error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n_test_helpers.dart';

void main() {
  final l10n = ruStrings();

  testWidgets(
    'ErrorView renders the localized retry label when onRetry is set',
    (tester) async {
      await pumpLocalizedWidget(
        tester,
        Scaffold(
          body: ErrorView(
            message: 'boom',
            onRetry: () {},
          ),
        ),
      );

      expect(find.text(l10n.commonRetry), findsOneWidget);
      expect(find.text('boom'), findsOneWidget);
    },
  );

  testWidgets(
    'ErrorView hides the retry button when onRetry is null',
    (tester) async {
      await pumpLocalizedWidget(
        tester,
        const Scaffold(
          body: ErrorView(message: 'boom'),
        ),
      );

      expect(find.text(l10n.commonRetry), findsNothing);
      expect(find.byType(FilledButton), findsNothing);
    },
  );

  testWidgets(
    'ErrorView falls back to a Russian retry label when '
    'AppLocalizations is not yet available',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorView(
              message: 'no delegates',
              onRetry: () {},
            ),
          ),
        ),
      );

      expect(find.text('Повторить'), findsOneWidget);
    },
  );
}
