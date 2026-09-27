import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/ui/carzon_icons.dart';
import 'create_listing_compose_layout.dart';

/// Image-backed VIN hero. [controller] stays the page-owned VIN source.
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
  static const Key imageKey = ValueKey('create_listing_vin_hero_image');
  static const Key backKey = ValueKey('create_listing_back');

  /// Native asset 1983×793. Used as a cover background, not a fixed frame.
  static const String backgroundAsset = 'assets/bg/car_bg_listing.png';
  static const double imageAspectRatio = 1983 / 793;

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
    final topInset = MediaQuery.paddingOf(context).top;

    return ClipRRect(
      key: heroKey,
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              backgroundAsset,
              key: imageKey,
              fit: BoxFit.cover,
              alignment: Alignment.centerRight,
              errorBuilder: (context, error, stackTrace) {
                return const ColoredBox(color: Color(0xFF1A2430));
              },
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x59000000),
                    Color(0x24000000),
                    Color(0x8C10141A),
                  ],
                  stops: [0, 0.48, 1],
                ),
              ),
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0x73000000),
                    Color(0x26000000),
                    Color(0x00000000),
                  ],
                  stops: [0, 0.46, 0.78],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, topInset, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 44,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: IconTheme(
                      data: const IconThemeData(color: Colors.white),
                      child: AppBackButton(
                        key: backKey,
                        fallback: AppRoutes.listings,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  l10n.createListingVinHeroEyebrow.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.1,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.createListingVinHeroTitle,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                    height: 1.05,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.createListingVinCardHelper,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.82),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final scale = MediaQuery.textScalerOf(context).scale(1);
                    final stacked = constraints.maxWidth < 300 || scale > 1.15;
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 13, child: field),
                        const SizedBox(width: 8),
                        Expanded(flex: 7, child: scan),
                      ],
                    );
                  },
                ),
              ],
            ),
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
    const ink = Color(0xFF14181F);
    return TextFormField(
      key: const ValueKey('create_listing_vin_field'),
      controller: controller,
      enabled: enabled,
      onChanged: onChanged,
      validator: validator,
      textCapitalization: TextCapitalization.characters,
      style: const TextStyle(
        color: ink,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
      cursorColor: ink,
      maxLength: 32,
      buildCounter:
          (context, {required currentLength, required isFocused, maxLength}) =>
              null,
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        hintText: l10n.listingVinFieldLabel,
        hintStyle: TextStyle(
          color: ink.withValues(alpha: 0.42),
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
        ),
        prefixIcon: Icon(
          CarzonIcons.scan,
          size: 18,
          color: ink.withValues(alpha: 0.55),
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 40,
          minHeight: 40,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: ink, width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFB42318)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFB42318), width: 1.2),
        ),
        errorStyle: const TextStyle(
          color: Color(0xFFFFD2CC),
          fontSize: 12,
          height: 1.25,
        ),
        errorMaxLines: 3,
      ),
    );
  }
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
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
                  children: [
                    Icon(
                      CarzonIcons.scan,
                      size: 18,
                      color: scanning
                          ? Colors.white.withValues(alpha: 0.45)
                          : Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
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
