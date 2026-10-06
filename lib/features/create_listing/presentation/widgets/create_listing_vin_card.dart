import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/ui/carzon_icons.dart';
import 'create_listing_compose_layout.dart';
import 'create_listing_quiet_surface.dart';

/// VIN field and scan. The page shell owns the shared hero image.
class CreateListingVinCard extends StatelessWidget {
  const CreateListingVinCard({
    super.key,
    required this.l10n,
    required this.theme,
    required this.controller,
    required this.enabled,
    required this.scanning,
    required this.onScan,
    required this.onChanged,
    required this.validator,
  });

  static const Key heroKey = ValueKey('create_listing_vin_hero');
  static const Key backKey = ValueKey('create_listing_back');

  final AppLocalizations l10n;
  final ThemeData theme;
  final TextEditingController controller;
  final bool enabled;
  final bool scanning;
  final VoidCallback onScan;
  final ValueChanged<String> onChanged;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) {
    final canScan = enabled && !scanning;

    return CreateListingQuietSurface(
      title: l10n.createListingVinCardHelper,
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 14),
      child: Column(
        key: heroKey,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final scale = MediaQuery.textScalerOf(context).scale(1);
              final stacked = constraints.maxWidth < 268 || scale > 1.22;
              final field = _VinField(
                l10n: l10n,
                controller: controller,
                enabled: enabled,
                onChanged: onChanged,
                validator: validator,
              );
              final scan = _ScanButton(
                label: l10n.createListingScanVinShort,
                tooltip: l10n.vinScannerTitle,
                canScan: canScan,
                scanning: scanning,
                onScan: onScan,
                expand: stacked,
              );
              if (stacked) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [field, const SizedBox(height: 8), scan],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: field),
                  const SizedBox(width: 6),
                  scan,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _VinField extends StatelessWidget {
  const _VinField({
    required this.l10n,
    required this.controller,
    required this.enabled,
    required this.onChanged,
    required this.validator,
  });

  final AppLocalizations l10n;
  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) {
    final light = Theme.of(context).brightness == Brightness.light;
    final ink = light ? const Color(0xFF14181F) : const Color(0xFFF4EDE4);
    // Inner stroke. Painted inside the field so the 48pt row does not grow.
    final hue = light ? const Color(0xFF7A6A58) : const Color(0xFFC4B5A4);
    final idle = hue.withValues(alpha: light ? 0.40 : 0.42);
    final focused = hue.withValues(alpha: light ? 0.66 : 0.68);
    return TextFormField(
      key: const ValueKey('create_listing_vin_field'),
      controller: controller,
      enabled: enabled,
      onChanged: onChanged,
      validator: validator,
      textCapitalization: TextCapitalization.characters,
      style: TextStyle(
        color: ink,
        fontWeight: FontWeight.w600,
        fontSize: 15,
        height: 1.2,
        letterSpacing: 0.28,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      cursorColor: ink,
      maxLength: 32,
      buildCounter:
          (context, {required currentLength, required isFocused, maxLength}) =>
              null,
      decoration: InputDecoration(
        filled: true,
        fillColor: light ? Colors.white : const Color(0xFF1C1916),
        hintText: l10n.listingVinFieldLabel,
        hintStyle: TextStyle(
          color: ink.withValues(alpha: light ? 0.42 : 0.68),
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
        ),
        contentPadding: const EdgeInsets.fromLTRB(10, 14, 6, 14),
        border: _VinInnerStroke(idle),
        enabledBorder: _VinInnerStroke(idle),
        disabledBorder: _VinInnerStroke(
          hue.withValues(alpha: light ? 0.24 : 0.22),
        ),
        focusedBorder: _VinInnerStroke(focused),
        errorBorder: const _VinInnerStroke(Color(0xFFB42318)),
        focusedErrorBorder: const _VinInnerStroke(Color(0xFFB42318)),
        errorStyle: const TextStyle(
          color: Color(0xFFB42318),
          fontSize: 12,
          height: 1.25,
        ),
        errorMaxLines: 3,
      ),
    );
  }
}

/// 1.15px stroke drawn inside the field. [dimensions] stay zero so the
/// control keeps its current height next to Scan VIN.
class _VinInnerStroke extends InputBorder {
  const _VinInnerStroke(this.color) : super(borderSide: BorderSide.none);

  final Color color;

  static const double width = 1.15;
  static const double radius = 14;

  @override
  InputBorder copyWith({BorderSide? borderSide}) => this;

  @override
  bool get isOutline => true;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(radius)));
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return getInnerPath(rect, textDirection: textDirection);
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
    final inset = width / 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.deflate(inset),
        Radius.circular(radius - inset),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..color = color,
    );
  }

  @override
  ShapeBorder scale(double t) => this;
}

class _ScanButton extends StatelessWidget {
  const _ScanButton({
    required this.label,
    required this.tooltip,
    required this.canScan,
    required this.scanning,
    required this.onScan,
    required this.expand,
  });

  final String label;
  final String tooltip;
  final bool canScan;
  final bool scanning;
  final VoidCallback onScan;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final child = Tooltip(
      message: tooltip,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: canScan ? kCreateListingActiveFill : const Color(0xFF2A3038),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withValues(alpha: canScan ? 0.62 : 0.28),
            width: 1.25,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            key: const ValueKey('create_listing_scan_vin'),
            onTap: canScan ? onScan : null,
            borderRadius: BorderRadius.circular(14),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: 48,
                minWidth: expand ? 48 : 76,
                maxWidth: expand ? double.infinity : 100,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
                  children: [
                    Icon(
                      CarzonIcons.scan,
                      size: 16,
                      color: scanning
                          ? Colors.white.withValues(alpha: 0.45)
                          : Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    if (expand) return child;
    return child;
  }
}
