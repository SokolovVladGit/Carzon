import 'package:carzon/features/create_listing/presentation/widgets/create_listing_compose_layout.dart';
import 'package:carzon/features/create_listing/presentation/widgets/create_listing_picker_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveCreateListingFieldVisualState', () {
    test('null / unselected resolves to empty', () {
      expect(
        resolveCreateListingFieldVisualState(enabled: true, hasValue: false),
        CreateListingFieldVisualState.empty,
      );
    });

    test('selected value resolves to filled', () {
      expect(
        resolveCreateListingFieldVisualState(enabled: true, hasValue: true),
        CreateListingFieldVisualState.filled,
      );
    });

    test('disabled dependent control resolves to disabled, not empty', () {
      expect(
        resolveCreateListingFieldVisualState(enabled: false, hasValue: false),
        CreateListingFieldVisualState.disabled,
      );
    });

    test('focus overrides filled', () {
      expect(
        resolveCreateListingFieldVisualState(
          enabled: true,
          hasValue: true,
          focused: true,
        ),
        CreateListingFieldVisualState.focused,
      );
    });

    test('error overrides filled and disabled', () {
      expect(
        resolveCreateListingFieldVisualState(
          enabled: true,
          hasValue: true,
          error: true,
        ),
        CreateListingFieldVisualState.error,
      );
      expect(
        resolveCreateListingFieldVisualState(
          enabled: false,
          hasValue: false,
          error: true,
        ),
        CreateListingFieldVisualState.error,
      );
    });
  });

  group('createListingHasMeaningfulText', () {
    test('whitespace-only is not filled', () {
      expect(createListingHasMeaningfulText(null), isFalse);
      expect(createListingHasMeaningfulText(''), isFalse);
      expect(createListingHasMeaningfulText('   '), isFalse);
      expect(createListingHasMeaningfulText('\n\t'), isFalse);
    });

    test('populated text is filled', () {
      expect(createListingHasMeaningfulText('Diesel'), isTrue);
      expect(createListingHasMeaningfulText('  Arteon  '), isTrue);
    });
  });

  test('empty / filled / disabled surfaces stay distinct', () {
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B3A4B)),
    );
    final empty = createListingSoftSurfaceDecoration(
      theme,
      visualState: CreateListingFieldVisualState.empty,
      hasValue: false,
    );
    final filled = createListingSoftSurfaceDecoration(
      theme,
      visualState: CreateListingFieldVisualState.filled,
      hasValue: true,
    );
    final disabled = createListingSoftSurfaceDecoration(
      theme,
      visualState: CreateListingFieldVisualState.disabled,
      hasValue: false,
    );
    expect(empty, isNot(filled));
    expect(disabled, isNot(empty));
    expect(disabled, isNot(filled));
  });

  group('CreateListingPickerField surface', () {
    Widget wrap(Widget child, {ThemeData? theme}) {
      return MaterialApp(
        theme: theme ?? ThemeData.light(),
        home: Scaffold(body: child),
      );
    }

    Future<BoxDecoration> surfaceOf(WidgetTester tester) async {
      final container = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byType(CreateListingPickerField),
          matching: find.byType(AnimatedContainer),
        ),
      );
      return container.decoration! as BoxDecoration;
    }

    testWidgets('null picker uses empty surface tokens', (tester) async {
      await tester.pumpWidget(
        wrap(
          CreateListingPickerField(
            label: 'Топливо',
            value: '',
            empty: true,
            enabled: true,
            onTap: () {},
          ),
        ),
      );
      final theme = Theme.of(
        tester.element(find.byType(CreateListingPickerField)),
      );
      expect(
        await surfaceOf(tester),
        createListingSoftSurfaceDecoration(
          theme,
          visualState: CreateListingFieldVisualState.empty,
          hasValue: false,
        ),
      );
    });

    testWidgets('selected picker uses filled surface tokens', (tester) async {
      await tester.pumpWidget(
        wrap(
          CreateListingPickerField(
            label: 'Топливо',
            value: 'Дизель',
            empty: false,
            enabled: true,
            onTap: () {},
          ),
        ),
      );
      final theme = Theme.of(
        tester.element(find.byType(CreateListingPickerField)),
      );
      expect(
        await surfaceOf(tester),
        createListingSoftSurfaceDecoration(
          theme,
          visualState: CreateListingFieldVisualState.filled,
          hasValue: true,
        ),
      );
    });

    testWidgets('disabled dependent picker uses disabled surface tokens', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          CreateListingPickerField(
            label: 'Модель',
            value: '',
            empty: true,
            enabled: false,
            onTap: () {},
          ),
        ),
      );
      final theme = Theme.of(
        tester.element(find.byType(CreateListingPickerField)),
      );
      expect(
        await surfaceOf(tester),
        createListingSoftSurfaceDecoration(
          theme,
          visualState: CreateListingFieldVisualState.disabled,
          hasValue: false,
        ),
      );
    });

    testWidgets('error overrides filled picker surface', (tester) async {
      await tester.pumpWidget(
        wrap(
          CreateListingPickerField(
            label: 'Марка',
            value: 'Volkswagen',
            empty: false,
            enabled: true,
            errorText: 'required',
            onTap: () {},
          ),
        ),
      );
      final theme = Theme.of(
        tester.element(find.byType(CreateListingPickerField)),
      );
      expect(
        await surfaceOf(tester),
        createListingSoftSurfaceDecoration(
          theme,
          visualState: CreateListingFieldVisualState.error,
          hasValue: true,
        ),
      );
    });
  });

  group('CreateListingTextSurface', () {
    testWidgets('populated controller => filled state; whitespace => empty', (
      tester,
    ) async {
      final controller = TextEditingController(text: '   ');
      addTearDown(controller.dispose);
      late bool hasValue;

      await tester.pumpWidget(
        MaterialApp(
          home: CreateListingTextSurface(
            controller: controller,
            builder: (_, value) {
              hasValue = value;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(hasValue, isFalse);

      controller.text = 'Volkswagen';
      await tester.pump();
      expect(hasValue, isTrue);

      controller.text = '\t  ';
      await tester.pump();
      expect(hasValue, isFalse);
    });
  });
}
