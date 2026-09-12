import 'package:flutter/material.dart';

/// Horizontal page inset for the create-listing canvas.
const double kCreateListingPageHorizontalPadding = 20;

/// Gap before a new major heading.
const double kCreateListingInterSectionGap = 28;

/// Heading → first control.
const double kCreateListingHeadingToContentGap = 8;

/// Field-to-field rhythm.
const double kCreateListingFieldGap = 10;

/// Side gap inside a two-field row.
const double kCreateListingFieldRowGap = 10;

/// Stack price/mileage when the row is narrower than this.
const double kCreateListingTwoFieldMinWidth = 300;

/// Rounded-rectangle radius for ordinary form fields.
const double kCreateListingFieldRadius = 15;

/// Larger radius for meaningful content cards (photos, resolved vehicle).
const double kCreateListingCardRadius = 20;

/// Flatter radius for segmented tracks and thumbs.
const double kCreateListingSegmentRadius = 12;

/// Publish CTA — aligned to the refined system, not a capsule.
const double kCreateListingPublishRadius = 16;

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
        ? cs.onSurface.withValues(alpha: 0.28)
        : cs.onSurface.withValues(alpha: 0.42);
  }
  if (light) {
    return Color.alphaBlend(
      Colors.white.withValues(alpha: 0.42),
      cs.onSurface.withValues(alpha: 0.050),
    );
  }
  return cs.onSurface.withValues(alpha: 0.13);
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
    CreateListingSurfaceLift.thumb => (light ? 0.020 : 0.10, 4.0, 0.6),
    CreateListingSurfaceLift.publish => (light ? 0.12 : 0.28, 12.0, 3.0),
    CreateListingSurfaceLift.photo => switch (visualState) {
      CreateListingFieldVisualState.filled ||
      CreateListingFieldVisualState.focused => (
        light ? 0.040 : 0.18,
        10.0,
        2.0,
      ),
      _ => (light ? 0.024 : 0.12, 8.0, 1.4),
    },
    CreateListingSurfaceLift.field => switch (visualState) {
      CreateListingFieldVisualState.empty => (light ? 0.012 : 0.06, 3.0, 0.4),
      CreateListingFieldVisualState.filled ||
      CreateListingFieldVisualState.error => (light ? 0.018 : 0.08, 4.0, 0.6),
      CreateListingFieldVisualState.focused => (light ? 0.026 : 0.10, 5.0, 0.8),
      CreateListingFieldVisualState.disabled => (
        light ? 0.008 : 0.04,
        2.0,
        0.3,
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
  double? radius,
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
  final resolvedRadius = radius ?? createListingRadiusForLift(lift);
  return BoxDecoration(
    color:
        fill ?? createListingFieldFill(theme, state: state, hasValue: hasValue),
    borderRadius: BorderRadius.circular(resolvedRadius),
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

double createListingRadiusForLift(CreateListingSurfaceLift lift) {
  return switch (lift) {
    CreateListingSurfaceLift.field => kCreateListingFieldRadius,
    CreateListingSurfaceLift.photo => kCreateListingCardRadius,
    CreateListingSurfaceLift.thumb => kCreateListingSegmentRadius,
    CreateListingSurfaceLift.publish => kCreateListingPublishRadius,
  };
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

/// Recessed track under segmented thumbs — quieter than field chrome.
BoxDecoration createListingTrackDecoration(ThemeData theme) {
  final cs = theme.colorScheme;
  final light = theme.brightness == Brightness.light;
  final fill = light
      ? Color.alphaBlend(cs.onSurface.withValues(alpha: 0.034), cs.surface)
      : Color.alphaBlend(cs.onSurface.withValues(alpha: 0.06), cs.surface);
  return BoxDecoration(
    color: fill,
    borderRadius: BorderRadius.circular(kCreateListingSegmentRadius),
    border: Border.all(
      color: cs.onSurface.withValues(alpha: light ? 0.05 : 0.10),
      width: 0.7,
    ),
  );
}

BoxDecoration createListingIdentityCardDecoration(ThemeData theme) {
  return BoxDecoration(
    color: createListingFieldFill(theme, hasValue: true),
    borderRadius: BorderRadius.circular(kCreateListingCardRadius),
    border: Border.all(
      color: createListingFieldBorder(theme, focused: false),
      width: 0.8,
    ),
  );
}

BoxDecoration createListingSegmentThumbDecoration(
  ThemeData theme, {
  required bool selected,
}) {
  if (!selected) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(kCreateListingSegmentRadius),
      color: Colors.transparent,
    );
  }
  return BoxDecoration(
    color: createListingFieldFill(theme, hasValue: true),
    borderRadius: BorderRadius.circular(kCreateListingSegmentRadius),
    border: Border.all(
      color: createListingFieldBorder(theme, focused: false),
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

ButtonStyle createListingConfirmButtonStyle(ThemeData theme) {
  final cs = theme.colorScheme;
  final light = theme.brightness == Brightness.light;
  return FilledButton.styleFrom(
    backgroundColor: cs.onSurface.withValues(alpha: light ? 0.92 : 0.94),
    foregroundColor: cs.surface,
    disabledBackgroundColor: cs.onSurface.withValues(alpha: 0.22),
    disabledForegroundColor: cs.surface.withValues(alpha: 0.70),
    elevation: 0,
    shadowColor: Colors.transparent,
    minimumSize: const Size(44, 44),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(kCreateListingFieldRadius),
    ),
    textStyle: theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: -0.1,
    ),
  );
}

ButtonStyle createListingSecondaryActionStyle(ThemeData theme) {
  final cs = theme.colorScheme;
  final light = theme.brightness == Brightness.light;
  return TextButton.styleFrom(
    foregroundColor: cs.onSurface.withValues(alpha: light ? 0.78 : 0.86),
    disabledForegroundColor: cs.onSurface.withValues(alpha: 0.32),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    minimumSize: const Size(44, 44),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    textStyle: theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w500,
      letterSpacing: -0.1,
    ),
  );
}

/// Graphite tertiary action — not a system-blue link.
class CreateListingSecondaryAction extends StatelessWidget {
  const CreateListingSecondaryAction({
    super.key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextButton(
      onPressed: enabled ? onPressed : null,
      style: createListingSecondaryActionStyle(theme),
      child: Text(label),
    );
  }
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
