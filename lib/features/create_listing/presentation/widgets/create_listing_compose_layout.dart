import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../shared/ui/carzon_icons.dart';

/// Horizontal page inset for the create-listing canvas.
const double kCreateListingPageHorizontalPadding = 16;

/// Gap before a new major heading.
const double kCreateListingInterSectionGap = 12;

/// Heading → first control.
const double kCreateListingHeadingToContentGap = 8;

/// Inner padding of grouped modules (Smart Fill, Characteristics).
const double kCreateListingModulePad = 14;

/// Preview → Publish breathing room.
const double kCreateListingFinishingGap = 14;

/// Field-to-field rhythm.
const double kCreateListingFieldGap = 8;

/// Side gap inside a two-field row.
const double kCreateListingFieldRowGap = 8;

/// Stack price/mileage when the row is narrower than this.
const double kCreateListingTwoFieldMinWidth = 300;

/// Rounded-rectangle radius for ordinary form fields.
const double kCreateListingFieldRadius = 14;

/// Larger radius for meaningful content cards (photos, resolved vehicle).
const double kCreateListingCardRadius = 16;

/// Flatter radius for segmented tracks and thumbs.
const double kCreateListingSegmentRadius = 12;

/// Scan VIN graphite. Shared selected fill for Create Listing selectors.
const Color kCreateListingActiveFill = Color(0xFF3A424C);

/// Foreground on [kCreateListingActiveFill]. Same in light and dark.
const Color kCreateListingActiveForeground = Color(0xFFFFFFFF);

/// Publish CTA — aligned to the refined system, not a capsule.
const double kCreateListingPublishRadius = 16;

/// Default single-line control height at text scale 1.0.
const double kCreateListingFieldMinHeight = 50;

/// Inner horizontal padding of fields and pickers.
const double kCreateListingFieldHPad = 14;

/// Compose card corner radius (reference-aligned).
const double kCreateListingComposeRadius = 16;

/// Shared size for Create-only contact leading icons.
const double kCreateListingContactIconSize = 18;

/// Vehicle-data fact glyphs. Same optical box.
const double kCreateListingFactIconSize = 20;

/// Phone, price, and other interactive row glyphs.
const double kCreateListingRowIconSize = 22;

/// Edit pencil. Same glyph for manual entry and characteristics.
const double kCreateListingEditIconSize = 18;

/// Right and down chevrons on Create Listing rows and pickers.
const double kCreateListingChevronSize = 18;

const IconData kCreateListingIconBody = CarzonIcons.coverCarPlaceholder;
const IconData kCreateListingIconEngine = LucideIcons.gauge;
const IconData kCreateListingIconDrivetrain = LucideIcons.gitFork;
const IconData kCreateListingIconTransmission = CarzonIcons.settings;
const IconData kCreateListingIconPower = LucideIcons.zap;
const IconData kCreateListingIconFuel = CarzonIcons.fuel;
const IconData kCreateListingIconYear = CarzonIcons.calendar;
const IconData kCreateListingIconRegistration = LucideIcons.clipboardList;
const IconData kCreateListingIconMileage = CarzonIcons.gauge;
const IconData kCreateListingIconLocation = LucideIcons.navigation;

/// Shared soft surface for vehicle-data fact cells and the location row.
const double kCreateListingFactRadius = 12;

/// Raised frosted chip around a fact/location/phone glyph.
const double kCreateListingFactIconChipExtent = 28;

/// Frosted Light summary tile. Fill carries the surface; no border, so it
/// stays quieter than the section card around it.
BoxDecoration createListingFactSurfaceDecoration(ThemeData theme) {
  final cs = theme.colorScheme;
  final light = theme.brightness == Brightness.light;
  final radius = BorderRadius.circular(kCreateListingFactRadius);
  if (light) {
    return BoxDecoration(
      color: const Color(0xFFF6F5F3),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFDFEFE), Color(0xFFF2F4F6), Color(0xFFF7F6F4)],
        stops: [0.0, 0.55, 1.0],
      ),
      borderRadius: radius,
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF2C3338).withValues(alpha: 0.045),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
  final base = Color.alphaBlend(
    cs.onSurface.withValues(alpha: 0.07),
    cs.surface,
  );
  return BoxDecoration(
    color: base,
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.alphaBlend(cs.onSurface.withValues(alpha: 0.12), cs.surface),
        Color.alphaBlend(cs.onSurface.withValues(alpha: 0.05), cs.surface),
      ],
    ),
    borderRadius: radius,
  );
}

/// Small raised frosted well for a leading glyph. Same family as the tiles.
BoxDecoration createListingFactIconChipDecoration(ThemeData theme) {
  final cs = theme.colorScheme;
  final light = theme.brightness == Brightness.light;
  return BoxDecoration(
    borderRadius: BorderRadius.circular(8),
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: light
          ? const [Color(0xFFFFFFFF), Color(0xFFE8EEF3)]
          : [
              Color.alphaBlend(
                cs.onSurface.withValues(alpha: 0.18),
                cs.surface,
              ),
              Color.alphaBlend(
                cs.onSurface.withValues(alpha: 0.07),
                cs.surface,
              ),
            ],
    ),
    border: Border.all(
      color: light
          ? const Color(0xFFFFFFFF)
          : cs.onSurface.withValues(alpha: 0.14),
      width: 0.8,
    ),
    boxShadow: [
      BoxShadow(
        color: (light ? const Color(0xFF2C3338) : Colors.black).withValues(
          alpha: light ? 0.10 : 0.32,
        ),
        blurRadius: 3,
        offset: const Offset(0, 1),
      ),
    ],
  );
}

/// Glossy ceramic empty-photo glaze. [prominent] is the main slot.
BoxDecoration createListingCeramicPlaceholderDecoration(
  ThemeData theme, {
  required bool prominent,
  required double radius,
}) {
  final cs = theme.colorScheme;
  final light = theme.brightness == Brightness.light;
  final shape = BorderRadius.circular(radius);
  if (light) {
    return BoxDecoration(
      borderRadius: shape,
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: prominent
            ? const [Color(0xFFFFFCFA), Color(0xFFF7F2EB), Color(0xFFF3EBE0)]
            : const [Color(0xFFFDFCFA), Color(0xFFF6F2EC), Color(0xFFF3EEE6)],
        stops: const [0.0, 0.42, 1.0],
      ),
      border: Border.all(
        color: prominent ? const Color(0xFFE4D8C8) : const Color(0xFFEADFD4),
      ),
    );
  }
  return BoxDecoration(
    borderRadius: shape,
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: prominent
          ? [
              Color.alphaBlend(
                cs.onSurface.withValues(alpha: 0.14),
                cs.surfaceContainerHigh,
              ),
              Color.alphaBlend(
                cs.onSurface.withValues(alpha: 0.06),
                cs.surface,
              ),
            ]
          : [
              Color.alphaBlend(
                cs.onSurface.withValues(alpha: 0.08),
                cs.surfaceContainerHigh,
              ),
              Color.alphaBlend(
                cs.onSurface.withValues(alpha: 0.03),
                cs.surface,
              ),
            ],
    ),
    border: Border.all(
      color: cs.onSurface.withValues(alpha: prominent ? 0.16 : 0.09),
    ),
  );
}

const IconData kCreateListingIconPhone = CarzonIcons.phone;
const IconData kCreateListingIconPrice = LucideIcons.tag;
const IconData kCreateListingIconListingType = CarzonIcons.compare;
const IconData kCreateListingIconEdit = LucideIcons.pencil;
const IconData kCreateListingIconChevronRight = CarzonIcons.chevronRight;
const IconData kCreateListingIconChevronDown = LucideIcons.chevronDown;
const IconData kCreateListingIconChevronUp = LucideIcons.chevronUp;

/// Muted passive glyph. Visible in dark mode, not bright white.
Color createListingPassiveIconColor(ThemeData theme) {
  final light = theme.brightness == Brightness.light;
  return theme.colorScheme.onSurface.withValues(alpha: light ? 0.55 : 0.68);
}

/// Leading glyph on a frosted fact, location, or phone summary.
class CreateListingFactIconChip extends StatelessWidget {
  const CreateListingFactIconChip({super.key, required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: kCreateListingFactIconChipExtent,
      height: kCreateListingFactIconChipExtent,
      child: DecoratedBox(
        decoration: createListingFactIconChipDecoration(theme),
        child: Icon(
          icon,
          size: 16,
          color: createListingPassiveIconColor(theme),
        ),
      ),
    );
  }
}

Color createListingChevronColor(ThemeData theme) {
  final light = theme.brightness == Brightness.light;
  return theme.colorScheme.onSurface.withValues(alpha: light ? 0.40 : 0.50);
}

Color createListingEditIconColor(ThemeData theme, {required bool enabled}) {
  final light = theme.brightness == Brightness.light;
  if (!enabled) {
    return theme.colorScheme.onSurface.withValues(alpha: 0.32);
  }
  return theme.colorScheme.onSurface.withValues(alpha: light ? 0.82 : 0.90);
}

/// Section card above the canvas. Border carries the separation, not shadow.
BoxDecoration createListingSectionSurfaceDecoration(ThemeData theme) {
  final cs = theme.colorScheme;
  final light = theme.brightness == Brightness.light;
  return BoxDecoration(
    color: light
        ? const Color(0xFFFFFDFB)
        : Color.alphaBlend(cs.onSurface.withValues(alpha: 0.055), cs.surface),
    borderRadius: BorderRadius.circular(kCreateListingComposeRadius),
    border: Border.all(
      color: cs.onSurface.withValues(alpha: light ? 0.07 : 0.14),
    ),
  );
}

Color createListingCanvasColor(ThemeData theme) {
  final cs = theme.colorScheme;
  final light = theme.brightness == Brightness.light;
  if (light) {
    return Color.alphaBlend(cs.primary.withValues(alpha: 0.035), Colors.white);
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
  return cs.onSurface.withValues(alpha: light ? 0.64 : 0.74);
}

Color createListingHairlineColor(ThemeData theme) {
  final light = theme.brightness == Brightness.light;
  return theme.colorScheme.onSurface.withValues(alpha: light ? 0.08 : 0.14);
}

TextStyle? createListingAppBarTitleStyle(ThemeData theme) {
  final light = theme.brightness == Brightness.light;
  return theme.textTheme.titleLarge?.copyWith(
    fontWeight: FontWeight.w700,
    letterSpacing: -0.44,
    height: 1.08,
    fontSize: 20,
    color: theme.colorScheme.onSurface.withValues(alpha: light ? 0.94 : 0.96),
  );
}

TextStyle? createListingSectionTitleStyle(ThemeData theme) {
  final light = theme.brightness == Brightness.light;
  return theme.textTheme.titleMedium?.copyWith(
    fontWeight: FontWeight.w600,
    letterSpacing: -0.28,
    height: 1.15,
    fontSize: 16,
    color: theme.colorScheme.onSurface.withValues(alpha: light ? 0.90 : 0.94),
  );
}

TextStyle? createListingSupportStyle(ThemeData theme) {
  final light = theme.brightness == Brightness.light;
  return theme.textTheme.bodySmall?.copyWith(
    color: theme.colorScheme.onSurface.withValues(alpha: light ? 0.50 : 0.58),
    fontWeight: FontWeight.w400,
    height: 1.4,
    fontSize: 13,
  );
}

TextStyle? createListingQuestionStyle(ThemeData theme) {
  final light = theme.brightness == Brightness.light;
  return theme.textTheme.titleSmall?.copyWith(
    fontWeight: FontWeight.w600,
    letterSpacing: -0.22,
    height: 1.25,
    fontSize: 16,
    color: theme.colorScheme.onSurface.withValues(alpha: light ? 0.92 : 0.96),
  );
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

/// Muted label on an unselected Create Listing segment or currency chip.
Color createListingInactiveSegmentLabel(ThemeData theme) {
  return theme.colorScheme.onSurface.withValues(
    alpha: theme.brightness == Brightness.light ? 0.58 : 0.64,
  );
}

/// Graphite selected thumb. Unselected stays transparent on the track.
BoxDecoration createListingActiveThumbDecoration(
  ThemeData theme, {
  required bool selected,
}) {
  final radius = BorderRadius.circular(kCreateListingSegmentRadius);
  if (!selected) {
    return BoxDecoration(
      color: Colors.transparent,
      borderRadius: radius,
      border: Border.all(color: Colors.transparent, width: 1),
    );
  }
  final light = theme.brightness == Brightness.light;
  return BoxDecoration(
    color: kCreateListingActiveFill,
    borderRadius: radius,
    border: Border.all(
      color: Colors.white.withValues(alpha: light ? 0.28 : 0.20),
      width: 1,
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

ButtonStyle createListingSecondaryActionStyle(
  ThemeData theme, {
  bool footer = false,
}) {
  final cs = theme.colorScheme;
  final light = theme.brightness == Brightness.light;
  return TextButton.styleFrom(
    foregroundColor: cs.onSurface.withValues(
      alpha: footer ? (light ? 0.70 : 0.78) : (light ? 0.64 : 0.72),
    ),
    disabledForegroundColor: cs.onSurface.withValues(alpha: 0.32),
    padding: EdgeInsets.symmetric(
      horizontal: footer ? 4 : 8,
      vertical: footer ? 10 : 8,
    ),
    minimumSize: const Size(44, 40),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    textStyle: theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w500,
      letterSpacing: -0.08,
      fontSize: footer ? 14 : 13.5,
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
    this.footer = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool enabled;
  final bool footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextButton(
      onPressed: enabled ? onPressed : null,
      style: createListingSecondaryActionStyle(theme, footer: footer),
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

  /// Slightly deeper field fill for a large input sitting directly on the canvas.
  bool separated = false,
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
      fontSize: 12,
      height: 1.25,
      letterSpacing: 0.1,
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
      final Color fill;
      if (states.contains(WidgetState.disabled)) {
        fill = createListingFieldFill(
          theme,
          state: CreateListingFieldVisualState.disabled,
          hasValue: hasValue,
        );
      } else if (states.contains(WidgetState.error)) {
        fill = createListingFieldFill(
          theme,
          state: CreateListingFieldVisualState.error,
          hasValue: hasValue,
        );
      } else if (states.contains(WidgetState.focused)) {
        fill = createListingFieldFill(
          theme,
          state: CreateListingFieldVisualState.focused,
          hasValue: hasValue,
        );
      } else {
        fill = createListingFieldFill(
          theme,
          state: occupancy,
          hasValue: hasValue,
        );
      }
      if (!separated) return fill;
      return Color.alphaBlend(
        cs.onSurface.withValues(alpha: light ? 0.04 : 0.055),
        fill,
      );
    }),
    contentPadding: EdgeInsets.fromLTRB(
      prefixIcon == null ? kCreateListingFieldHPad : 0,
      13,
      kCreateListingFieldHPad,
      13,
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
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitleText = subtitle?.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: createListingSectionTitleStyle(theme)),
        if (subtitleText != null && subtitleText.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(subtitleText, style: createListingSupportStyle(theme)),
        ],
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

BoxDecoration createListingComposeCardDecoration(ThemeData theme) {
  return createListingSectionSurfaceDecoration(theme);
}

/// Compact pencil + label. Hit target ≥ 44 without a large admin row.
class CreateListingManualEntryLink extends StatelessWidget {
  const CreateListingManualEntryLink({
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
    final cs = theme.colorScheme;

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(10),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    kCreateListingIconEdit,
                    size: kCreateListingEditIconSize,
                    color: createListingEditIconColor(theme, enabled: enabled),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: enabled
                            ? cs.onSurface.withValues(
                                alpha: theme.brightness == Brightness.light
                                    ? 0.88
                                    : 0.94,
                              )
                            : cs.onSurface.withValues(alpha: 0.32),
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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
