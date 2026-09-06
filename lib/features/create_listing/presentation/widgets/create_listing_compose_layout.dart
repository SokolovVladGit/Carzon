import 'package:flutter/material.dart';

/// Horizontal page inset for the create-listing canvas.
const double kCreateListingPageHorizontalPadding = 20;

/// Gap before a new major heading.
const double kCreateListingInterSectionGap = 23;

/// Heading → first control.
const double kCreateListingHeadingToContentGap = 12;

/// Field-to-field rhythm.
const double kCreateListingFieldGap = 10;

/// Side gap inside a two-field row.
const double kCreateListingFieldRowGap = 10;

/// Stack price/mileage when the row is narrower than this.
const double kCreateListingTwoFieldMinWidth = 300;

/// Soft pill radius — fields, pickers, segments, photo, publish.
const double kCreateListingFieldRadius = 23;

/// Default single-line control height at text scale 1.0.
const double kCreateListingFieldMinHeight = 54;

/// Inner horizontal padding of fields and pickers.
const double kCreateListingFieldHPad = 18;

/// Shared size for Create-only contact leading icons.
const double kCreateListingContactIconSize = 18;

Color createListingCanvasColor(ThemeData theme) {
  final cs = theme.colorScheme;
  final light = theme.brightness == Brightness.light;
  if (light) {
    return Color.alphaBlend(cs.onSurface.withValues(alpha: 0.012), cs.surface);
  }
  return Color.alphaBlend(cs.onSurface.withValues(alpha: 0.045), cs.surface);
}

BoxDecoration createListingCanvasDecoration(ThemeData theme) {
  return BoxDecoration(color: createListingCanvasColor(theme));
}

/// Relative lift for Create Listing surfaces. Not full neumorphism.
enum CreateListingSurfaceLift { field, photo, thumb, publish }

/// Create-only occupancy/interaction state for soft field chrome.
enum CreateListingFieldVisualState { empty, filled, focused, disabled, error }

CreateListingFieldVisualState resolveCreateListingFieldVisualState({
  required bool enabled,
  required bool hasValue,
  bool focused = false,
  bool error = false,
}) {
  if (error) {
    return CreateListingFieldVisualState.error;
  }
  if (!enabled) {
    return CreateListingFieldVisualState.disabled;
  }
  if (focused) {
    return CreateListingFieldVisualState.focused;
  }
  if (hasValue) {
    return CreateListingFieldVisualState.filled;
  }
  return CreateListingFieldVisualState.empty;
}

bool createListingHasMeaningfulText(String? raw) {
  return (raw ?? '').trim().isNotEmpty;
}

Color createListingFieldFill(
  ThemeData theme, {
  CreateListingFieldVisualState state = CreateListingFieldVisualState.filled,
  bool hasValue = false,
}) {
  final cs = theme.colorScheme;
  final light = theme.brightness == Brightness.light;
  final canvas = createListingCanvasColor(theme);
  final occupancy =
      hasValue ||
          state == CreateListingFieldVisualState.filled ||
          state == CreateListingFieldVisualState.focused
      ? CreateListingFieldVisualState.filled
      : CreateListingFieldVisualState.empty;
  final effective = switch (state) {
    CreateListingFieldVisualState.disabled =>
      CreateListingFieldVisualState.disabled,
    CreateListingFieldVisualState.error => occupancy,
    CreateListingFieldVisualState.focused =>
      CreateListingFieldVisualState.focused,
    CreateListingFieldVisualState.filled =>
      CreateListingFieldVisualState.filled,
    CreateListingFieldVisualState.empty => CreateListingFieldVisualState.empty,
  };

  if (light) {
    return switch (effective) {
      CreateListingFieldVisualState.disabled => Color.alphaBlend(
        Colors.white.withValues(alpha: 0.10),
        canvas,
      ),
      CreateListingFieldVisualState.empty => Color.alphaBlend(
        Colors.white.withValues(alpha: 0.38),
        cs.surfaceContainerLowest,
      ),
      CreateListingFieldVisualState.filled => Color.alphaBlend(
        Colors.white.withValues(alpha: 0.94),
        cs.surfaceContainerLowest,
      ),
      CreateListingFieldVisualState.focused => Color.alphaBlend(
        Colors.white.withValues(alpha: 0.98),
        cs.surfaceContainerLowest,
      ),
      CreateListingFieldVisualState.error => Color.alphaBlend(
        Colors.white.withValues(alpha: hasValue ? 0.94 : 0.38),
        cs.surfaceContainerLowest,
      ),
    };
  }
  return switch (effective) {
    CreateListingFieldVisualState.disabled => Color.alphaBlend(
      cs.onSurface.withValues(alpha: 0.016),
      cs.surface,
    ),
    CreateListingFieldVisualState.empty => Color.alphaBlend(
      cs.onSurface.withValues(alpha: 0.028),
      cs.surfaceContainerHigh,
    ),
    CreateListingFieldVisualState.filled => Color.alphaBlend(
      cs.onSurface.withValues(alpha: 0.088),
      cs.surfaceContainerHigh,
    ),
    CreateListingFieldVisualState.focused => Color.alphaBlend(
      cs.onSurface.withValues(alpha: 0.110),
      cs.surfaceContainerHigh,
    ),
    CreateListingFieldVisualState.error => Color.alphaBlend(
      cs.onSurface.withValues(alpha: hasValue ? 0.088 : 0.028),
      cs.surfaceContainerHigh,
    ),
  };
}

Color createListingPlaceholderColor(ThemeData theme) {
  final cs = theme.colorScheme;
  final light = theme.brightness == Brightness.light;
  return cs.onSurface.withValues(alpha: light ? 0.58 : 0.70);
}

Color createListingPickerChevronColor(
  ThemeData theme, {
  required bool enabled,
  required bool empty,
}) {
  final cs = theme.colorScheme;
  if (!enabled) {
    return cs.onSurface.withValues(alpha: 0.24);
  }
  if (empty) {
    return cs.onSurface.withValues(alpha: 0.38);
  }
  return cs.onSurface.withValues(alpha: 0.56);
}

Color createListingContactIconColor(ThemeData theme) {
  final cs = theme.colorScheme;
  final light = theme.brightness == Brightness.light;
  return cs.onSurface.withValues(alpha: light ? 0.44 : 0.55);
}

Color createListingValueColor(ThemeData theme, {required bool enabled}) {
  final cs = theme.colorScheme;
  final light = theme.brightness == Brightness.light;
  if (!enabled) {
    return cs.onSurface.withValues(alpha: light ? 0.38 : 0.42);
  }
  return cs.onSurface.withValues(alpha: light ? 0.92 : 0.96);
}

Color createListingFieldBorder(
  ThemeData theme, {
  required bool focused,
  bool error = false,
}) {
  final cs = theme.colorScheme;
  final light = theme.brightness == Brightness.light;
  if (error) {
    return cs.error.withValues(alpha: light ? 0.78 : 0.86);
  }
  if (focused) {
    return light
        ? cs.primary.withValues(alpha: 0.36)
        : cs.primary.withValues(alpha: 0.50);
  }
  if (light) {
    return Color.alphaBlend(
      Colors.white.withValues(alpha: 0.42),
      cs.onSurface.withValues(alpha: 0.050),
    );
  }
  return cs.onSurface.withValues(alpha: 0.13);
}

List<Color> createListingRaisedGradient(
  ThemeData theme, {
  Color? fill,
  CreateListingSurfaceLift lift = CreateListingSurfaceLift.field,
  CreateListingFieldVisualState visualState =
      CreateListingFieldVisualState.filled,
  bool hasValue = false,
}) {
  final cs = theme.colorScheme;
  final light = theme.brightness == Brightness.light;
  final base =
      fill ??
      createListingFieldFill(theme, state: visualState, hasValue: hasValue);

  if (lift == CreateListingSurfaceLift.publish && fill != null) {
    return [
      Color.alphaBlend(
        Colors.white.withValues(alpha: light ? 0.10 : 0.12),
        base,
      ),
      base,
      Color.alphaBlend(
        Colors.black.withValues(alpha: light ? 0.12 : 0.20),
        base,
      ),
    ];
  }

  final highlightStrength = switch (visualState) {
    CreateListingFieldVisualState.disabled => light ? 0.12 : 0.020,
    CreateListingFieldVisualState.empty => light ? 0.28 : 0.032,
    CreateListingFieldVisualState.filled => light ? 0.84 : 0.088,
    CreateListingFieldVisualState.focused => light ? 0.92 : 0.12,
    CreateListingFieldVisualState.error =>
      hasValue ? (light ? 0.84 : 0.088) : (light ? 0.28 : 0.032),
  };
  final highlight = light
      ? Color.alphaBlend(
          Colors.white.withValues(alpha: highlightStrength),
          base,
        )
      : Color.alphaBlend(
          cs.onSurface.withValues(alpha: highlightStrength),
          base,
        );
  final shade = light
      ? Color.alphaBlend(
          cs.onSurface.withValues(
            alpha: visualState == CreateListingFieldVisualState.disabled
                ? 0.008
                : 0.016,
          ),
          base,
        )
      : Color.alphaBlend(
          Colors.black.withValues(
            alpha: visualState == CreateListingFieldVisualState.disabled
                ? 0.08
                : 0.16,
          ),
          base,
        );
  return [highlight, base, shade];
}

List<BoxShadow> createListingSoftShadows(
  ThemeData theme, {
  CreateListingSurfaceLift lift = CreateListingSurfaceLift.field,
  CreateListingFieldVisualState visualState =
      CreateListingFieldVisualState.filled,
  bool muted = false,
}) {
  final cs = theme.colorScheme;
  final light = theme.brightness == Brightness.light;
  if (muted || visualState == CreateListingFieldVisualState.disabled) {
    return [
      BoxShadow(
        color: (light ? cs.onSurface : Colors.black).withValues(
          alpha: light ? 0.012 : 0.06,
        ),
        blurRadius: 5,
        offset: const Offset(0, 0.8),
      ),
    ];
  }

  final (alpha, blur, dy) = switch (lift) {
    CreateListingSurfaceLift.thumb => (light ? 0.090 : 0.27, 10.0, 2.2),
    CreateListingSurfaceLift.publish => (light ? 0.155 : 0.34, 16.0, 5.0),
    CreateListingSurfaceLift.photo => switch (visualState) {
      CreateListingFieldVisualState.filled ||
      CreateListingFieldVisualState.focused => (
        light ? 0.068 : 0.26,
        14.0,
        3.5,
      ),
      _ => (light ? 0.046 : 0.18, 12.0, 2.8),
    },
    CreateListingSurfaceLift.field => switch (visualState) {
      CreateListingFieldVisualState.empty => (light ? 0.034 : 0.13, 8.0, 1.8),
      CreateListingFieldVisualState.filled ||
      CreateListingFieldVisualState.error => (light ? 0.054 : 0.20, 12.0, 2.7),
      CreateListingFieldVisualState.focused => (
        light ? 0.066 : 0.24,
        13.0,
        3.0,
      ),
      CreateListingFieldVisualState.disabled => (
        light ? 0.012 : 0.06,
        5.0,
        0.8,
      ),
    },
  };

  return [
    BoxShadow(
      color: (light ? cs.onSurface : Colors.black).withValues(alpha: alpha),
      blurRadius: blur,
      offset: Offset(0, dy),
    ),
  ];
}

BoxDecoration createListingSoftSurfaceDecoration(
  ThemeData theme, {
  CreateListingSurfaceLift lift = CreateListingSurfaceLift.field,
  CreateListingFieldVisualState? visualState,
  bool focused = false,
  bool error = false,
  bool enabled = true,
  bool hasValue = false,
  Color? fill,
}) {
  final usesOccupancy =
      lift == CreateListingSurfaceLift.field ||
      lift == CreateListingSurfaceLift.photo;
  final state = usesOccupancy
      ? (visualState ??
            resolveCreateListingFieldVisualState(
              enabled: enabled,
              hasValue: hasValue,
              focused: focused,
              error: error,
            ))
      : CreateListingFieldVisualState.filled;
  return BoxDecoration(
    borderRadius: BorderRadius.circular(kCreateListingFieldRadius),
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: createListingRaisedGradient(
        theme,
        fill: fill,
        lift: lift,
        visualState: state,
        hasValue: hasValue,
      ),
    ),
    border: Border.all(
      color: createListingFieldBorder(
        theme,
        focused: state == CreateListingFieldVisualState.focused,
        error: state == CreateListingFieldVisualState.error,
      ),
      width:
          state == CreateListingFieldVisualState.focused ||
              state == CreateListingFieldVisualState.error
          ? 1
          : 0.7,
    ),
    boxShadow: createListingSoftShadows(theme, lift: lift, visualState: state),
  );
}

/// Soft-raised field chrome. Name kept so existing Create-only call sites stay stable.
BoxDecoration createListingInsetDecoration(
  ThemeData theme, {
  bool focused = false,
  bool error = false,
  bool enabled = true,
  bool hasValue = false,
}) {
  return createListingSoftSurfaceDecoration(
    theme,
    focused: focused,
    error: error,
    enabled: enabled,
    hasValue: hasValue,
  );
}

/// Recessed track under segmented thumbs — quieter than field pills.
BoxDecoration createListingTrackDecoration(ThemeData theme) {
  final cs = theme.colorScheme;
  final light = theme.brightness == Brightness.light;
  final fill = light
      ? Color.alphaBlend(cs.onSurface.withValues(alpha: 0.034), cs.surface)
      : Color.alphaBlend(cs.onSurface.withValues(alpha: 0.06), cs.surface);
  final top = Color.alphaBlend(
    cs.onSurface.withValues(alpha: light ? 0.028 : 0.05),
    fill,
  );
  final bottom = Color.alphaBlend(
    (light ? cs.surface : cs.surfaceContainerHighest).withValues(
      alpha: light ? 0.55 : 0.18,
    ),
    fill,
  );
  return BoxDecoration(
    borderRadius: BorderRadius.circular(kCreateListingFieldRadius),
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [top, fill, bottom],
    ),
    border: Border.all(
      color: cs.onSurface.withValues(alpha: light ? 0.04 : 0.10),
      width: 0.7,
    ),
  );
}

BoxDecoration createListingRaisedDecoration(
  ThemeData theme, {
  Color? fill,
  bool prominent = false,
}) {
  final lift = prominent
      ? CreateListingSurfaceLift.publish
      : CreateListingSurfaceLift.thumb;
  return createListingSoftSurfaceDecoration(theme, lift: lift, fill: fill);
}

/// Soft drop shadow under a filled [InputDecorator] without wrapping helper/error.
class CreateListingSoftInputBorder extends OutlineInputBorder {
  const CreateListingSoftInputBorder({
    required this.shadows,
    super.borderSide,
    super.borderRadius,
  });

  final List<BoxShadow> shadows;

  @override
  CreateListingSoftInputBorder copyWith({
    BorderSide? borderSide,
    BorderRadius? borderRadius,
    double? gapPadding,
  }) {
    return CreateListingSoftInputBorder(
      shadows: shadows,
      borderSide: borderSide ?? this.borderSide,
      borderRadius: borderRadius ?? this.borderRadius,
    );
  }

  @override
  CreateListingSoftInputBorder scale(double t) {
    return CreateListingSoftInputBorder(
      shadows: shadows,
      borderSide: borderSide.scale(t),
      borderRadius: borderRadius * t,
    );
  }

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    double? gapStart,
    double gapExtent = 0.0,
    double gapPercentage = 0.0,
    TextDirection? textDirection,
  }) {
    final rrect = borderRadius.resolve(textDirection).toRRect(rect);
    for (final shadow in shadows) {
      final paint = Paint()
        ..color = shadow.color
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          shadow.blurRadius * 0.5,
        );
      canvas.drawRRect(
        rrect.shift(shadow.offset).inflate(shadow.spreadRadius),
        paint,
      );
    }
    super.paint(
      canvas,
      rect,
      gapStart: gapStart,
      gapExtent: gapExtent,
      gapPercentage: gapPercentage,
      textDirection: textDirection,
    );
  }
}

/// Create-only soft field chrome. Hint-only — no floating labels.
InputDecoration createListingFieldDecoration(
  ThemeData theme, {
  String? hintText,
  String? helperText,
  bool hasValue = false,
  Widget? prefixIcon,
}) {
  final cs = theme.colorScheme;
  final light = theme.brightness == Brightness.light;
  final radius = BorderRadius.circular(kCreateListingFieldRadius);
  final helperColor = cs.onSurface.withValues(alpha: light ? 0.48 : 0.58);
  final occupancy = hasValue
      ? CreateListingFieldVisualState.filled
      : CreateListingFieldVisualState.empty;
  final occupancyShadows = createListingSoftShadows(
    theme,
    visualState: occupancy,
  );
  final focusedShadows = createListingSoftShadows(
    theme,
    visualState: CreateListingFieldVisualState.focused,
  );
  final disabledShadows = createListingSoftShadows(
    theme,
    visualState: CreateListingFieldVisualState.disabled,
    muted: true,
  );
  final errorShadows = createListingSoftShadows(
    theme,
    visualState: CreateListingFieldVisualState.error,
  );

  CreateListingSoftInputBorder borderFor({
    required Color color,
    double width = 0.7,
    List<BoxShadow>? shadows,
  }) {
    return CreateListingSoftInputBorder(
      shadows: shadows ?? occupancyShadows,
      borderRadius: radius,
      borderSide: BorderSide(color: color, width: width),
    );
  }

  return InputDecoration(
    hintText: hintText,
    helperText: helperText,
    helperMaxLines: 3,
    floatingLabelBehavior: FloatingLabelBehavior.never,
    hintStyle: TextStyle(
      color: createListingPlaceholderColor(theme),
      fontWeight: FontWeight.w400,
      fontSize: 16,
      height: 1.25,
    ),
    helperStyle: TextStyle(
      color: helperColor,
      fontWeight: FontWeight.w400,
      fontSize: 12,
      height: 1.35,
    ),
    errorStyle: TextStyle(
      color: cs.error,
      fontWeight: FontWeight.w500,
      fontSize: 12,
      height: 1.3,
    ),
    counterStyle: TextStyle(
      color: helperColor,
      fontWeight: FontWeight.w400,
      fontSize: 11,
    ),
    border: borderFor(color: Colors.transparent, width: 0),
    enabledBorder: borderFor(
      color: createListingFieldBorder(theme, focused: false),
    ),
    focusedBorder: borderFor(
      color: createListingFieldBorder(theme, focused: true),
      width: 1,
      shadows: focusedShadows,
    ),
    errorBorder: borderFor(
      color: createListingFieldBorder(theme, focused: false, error: true),
      width: 1,
      shadows: errorShadows,
    ),
    focusedErrorBorder: borderFor(
      color: createListingFieldBorder(theme, focused: true, error: true),
      width: 1.1,
      shadows: errorShadows,
    ),
    disabledBorder: borderFor(
      color: cs.onSurface.withValues(alpha: light ? 0.03 : 0.07),
      shadows: disabledShadows,
    ),
    prefixIcon: prefixIcon == null
        ? null
        : Padding(
            padding: const EdgeInsets.only(left: 16, right: 8),
            child: prefixIcon,
          ),
    prefixIconConstraints: prefixIcon == null
        ? null
        : const BoxConstraints(minWidth: 42, minHeight: 18),
    filled: true,
    fillColor: WidgetStateColor.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return createListingFieldFill(
          theme,
          state: CreateListingFieldVisualState.disabled,
          hasValue: hasValue,
        );
      }
      if (states.contains(WidgetState.error)) {
        return createListingFieldFill(
          theme,
          state: CreateListingFieldVisualState.error,
          hasValue: hasValue,
        );
      }
      if (states.contains(WidgetState.focused)) {
        return createListingFieldFill(
          theme,
          state: CreateListingFieldVisualState.focused,
          hasValue: hasValue,
        );
      }
      return createListingFieldFill(
        theme,
        state: occupancy,
        hasValue: hasValue,
      );
    }),
    contentPadding: EdgeInsets.fromLTRB(
      prefixIcon == null ? kCreateListingFieldHPad : 0,
      16,
      kCreateListingFieldHPad,
      16,
    ),
  );
}

/// Rebuilds when [controller] gains or loses meaningful text.
class CreateListingTextSurface extends StatelessWidget {
  const CreateListingTextSurface({
    super.key,
    required this.controller,
    required this.builder,
  });

  final TextEditingController controller;
  final Widget Function(BuildContext context, bool hasValue) builder;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return builder(
          context,
          createListingHasMeaningfulText(controller.text),
        );
      },
    );
  }
}

/// Typography-only section heading on the continuous canvas.
class CreateListingFormSection extends StatelessWidget {
  const CreateListingFormSection({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final light = theme.brightness == Brightness.light;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
            height: 1.2,
            fontSize: 17,
            color: cs.onSurface.withValues(alpha: light ? 0.92 : 0.96),
          ),
        ),
        const SizedBox(height: kCreateListingHeadingToContentGap),
        child,
      ],
    );
  }
}

/// Kept for Edit Listing. Create Listing no longer uses this marker label.
class CreateListingFieldLabel extends StatelessWidget {
  const CreateListingFieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final light = theme.brightness == Brightness.light;
    return Padding(
      padding: const EdgeInsets.only(left: 1, bottom: 1),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 14,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: cs.primary.withValues(alpha: light ? 0.34 : 0.52),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.labelLarge?.copyWith(
                color: cs.onSurface.withValues(alpha: light ? 0.82 : 0.95),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.03,
                fontSize: 13.7,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Stacks [start]/[end] on narrow or large-text layouts.
class CreateListingResponsiveFieldRow extends StatelessWidget {
  const CreateListingResponsiveFieldRow({
    super.key,
    required this.start,
    required this.end,
  });

  final Widget start;
  final Widget end;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return LayoutBuilder(
      builder: (context, constraints) {
        final stack =
            constraints.maxWidth < kCreateListingTwoFieldMinWidth ||
            scale > 1.25;
        if (stack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              start,
              const SizedBox(height: kCreateListingFieldGap),
              end,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: start),
            const SizedBox(width: kCreateListingFieldRowGap),
            Expanded(child: end),
          ],
        );
      },
    );
  }
}
