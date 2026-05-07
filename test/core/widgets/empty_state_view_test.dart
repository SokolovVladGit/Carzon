import 'package:carzon/core/widgets/empty_state_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n_test_helpers.dart';

void main() {
  group('EmptyStateView', () {
    testWidgets('renders the provided icon and title', (tester) async {
      await pumpLocalizedWidget(
        tester,
        const Scaffold(
          body: EmptyStateView(
            icon: Icons.favorite_border,
            title: 'Ничего нет',
          ),
        ),
      );

      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
      expect(find.text('Ничего нет'), findsOneWidget);
    });

    testWidgets('renders the optional body when provided', (tester) async {
      await pumpLocalizedWidget(
        tester,
        const Scaffold(
          body: EmptyStateView(
            icon: Icons.inbox_outlined,
            title: 'Пусто',
            body: 'Тут будет контент позже.',
          ),
        ),
      );

      expect(find.text('Тут будет контент позже.'), findsOneWidget);
    });

    testWidgets('omits the body paragraph when body is null', (tester) async {
      await pumpLocalizedWidget(
        tester,
        const Scaffold(
          body: EmptyStateView(icon: Icons.inbox_outlined, title: 'Пусто'),
        ),
      );

      // Title is the only Text. No other Text widgets should exist.
      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets(
      'renders a FilledButton primary action and fires its callback',
      (tester) async {
        var fired = 0;
        await pumpLocalizedWidget(
          tester,
          Scaffold(
            body: EmptyStateView(
              icon: Icons.add,
              title: 'Нет объявлений',
              primaryAction: EmptyStateAction(
                label: 'Подать',
                onPressed: () => fired += 1,
              ),
            ),
          ),
        );

        expect(find.widgetWithText(FilledButton, 'Подать'), findsOneWidget);

        await tester.tap(find.widgetWithText(FilledButton, 'Подать'));
        await tester.pump();

        expect(fired, 1);
      },
    );

    testWidgets(
      'renders an OutlinedButton secondary action and fires its callback',
      (tester) async {
        var fired = 0;
        await pumpLocalizedWidget(
          tester,
          Scaffold(
            body: EmptyStateView(
              icon: Icons.filter_alt_off,
              title: 'Ничего не найдено',
              secondaryAction: EmptyStateAction(
                label: 'Сбросить',
                onPressed: () => fired += 1,
              ),
            ),
          ),
        );

        expect(find.widgetWithText(OutlinedButton, 'Сбросить'), findsOneWidget);

        await tester.tap(find.widgetWithText(OutlinedButton, 'Сбросить'));
        await tester.pump();

        expect(fired, 1);
      },
    );
  });
}
