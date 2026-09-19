import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/ui/carzon_icons.dart';
import '../../domain/entities/vehicle_resolve_result.dart';
import '../bloc/create_listing_state.dart';
import '../models/vin_resolve_display.dart';
import 'create_listing_compose_layout.dart';

class CreateListingVehicleResolvePanel extends StatelessWidget {
  const CreateListingVehicleResolvePanel({
    super.key,
    required this.l10n,
    required this.theme,
    required this.resolve,
    required this.enabled,
    required this.onConfirm,
    required this.onEnterManual,
    required this.onRetry,
    this.compactMake = '',
    this.compactModel = '',
    this.compactYear,
    this.compactVariant,
  });

  final AppLocalizations l10n;
  final ThemeData theme;
  final CreateListingVehicleResolve resolve;
  final bool enabled;
  final VoidCallback onConfirm;
  final VoidCallback onEnterManual;
  final VoidCallback onRetry;
  final String compactMake;
  final String compactModel;
  final int? compactYear;
  final String? compactVariant;

  @override
  Widget build(BuildContext context) {
    return switch (resolve.status) {
      CreateListingVinResolveStatus.idle => _IdleManualPath(
        l10n: l10n,
        theme: theme,
        enabled: enabled,
        onPressed: onEnterManual,
      ),
      CreateListingVinResolveStatus.manual => const SizedBox.shrink(),
      CreateListingVinResolveStatus.resolving => _StatusText(
        key: const ValueKey('create_listing_vin_resolving'),
        theme: theme,
        text: l10n.createListingVinResolving,
      ),
      CreateListingVinResolveStatus.resolved => _ResolvedCard(
        l10n: l10n,
        theme: theme,
        suggestion: resolve.suggestion?.vehicle,
        warnings: resolve.suggestion?.warnings ?? const [],
        confirmed: resolve.confirmed,
        compactMake: compactMake,
        compactModel: compactModel,
        compactYear: compactYear,
        compactVariant: compactVariant,
        enabled: enabled,
        onConfirm: onConfirm,
        onChangeManually: onEnterManual,
      ),
      CreateListingVinResolveStatus.partial => _MessageBlock(
        key: const ValueKey('create_listing_vin_partial'),
        theme: theme,
        title: l10n.createListingVinPartialTitle,
        highlight: _partialHighlight(resolve.suggestion?.vehicle),
        highlightKey: const ValueKey('create_listing_vin_partial_make'),
        body: l10n.createListingVinPartial,
        child: _ManualVehicleAction(
          l10n: l10n,
          theme: theme,
          enabled: enabled,
          onPressed: onEnterManual,
        ),
      ),
      CreateListingVinResolveStatus.noData => _MessageBlock(
        key: const ValueKey('create_listing_vin_no_data'),
        theme: theme,
        title: l10n.createListingVinNoData,
        body: l10n.createListingVinMayMiss,
        child: _ManualVehicleAction(
          l10n: l10n,
          theme: theme,
          enabled: enabled,
          onPressed: onEnterManual,
        ),
      ),
      CreateListingVinResolveStatus.failure => _MessageBlock(
        key: const ValueKey('create_listing_vin_failure'),
        theme: theme,
        title: l10n.createListingVinResolverFailed,
        body: l10n.createListingVinMayMiss,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CreateListingSecondaryAction(
              key: const ValueKey('create_listing_vin_retry'),
              label: l10n.commonRetry,
              enabled: enabled,
              onPressed: onRetry,
            ),
            _ManualVehicleAction(
              l10n: l10n,
              theme: theme,
              enabled: enabled,
              onPressed: onEnterManual,
            ),
          ],
        ),
      ),
      CreateListingVinResolveStatus.likelyInputError => _MessageBlock(
        key: const ValueKey('create_listing_vin_checksum'),
        theme: theme,
        title: null,
        body: l10n.createListingVinChecksumHint,
        child: _ManualVehicleAction(
          l10n: l10n,
          theme: theme,
          enabled: enabled,
          onPressed: onEnterManual,
        ),
      ),
    };
  }

  String? _partialHighlight(VehicleResolveSuggestion? vehicle) {
    if (vehicle == null) return null;
    final line = vehicle.identityHeadline;
    return line.isEmpty ? null : line;
  }
}

@visibleForTesting
String createListingResolvedIdentitySubtitle(VehicleResolveSuggestion vehicle) {
  final year = vehicle.year;
  final variant = vehicle.variantHint;
  if (year != null && variant != null) {
    return '$year · $variant';
  }
  if (year != null) {
    return '$year';
  }
  return variant ?? '';
}

@visibleForTesting
String createListingConfirmedIdentityPrimary({
  required String make,
  required String model,
  int? year,
}) {
  final parts = [
    if (make.trim().isNotEmpty) make.trim(),
    if (model.trim().isNotEmpty) model.trim(),
  ];
  final head = parts.join(' ');
  if (year != null) {
    return head.isEmpty ? '$year' : '$head · $year';
  }
  return head;
}

class _StatusText extends StatelessWidget {
  const _StatusText({super.key, required this.theme, required this.text});

  final ThemeData theme;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _IdleManualPath extends StatelessWidget {
  const _IdleManualPath({
    required this.l10n,
    required this.theme,
    required this.enabled,
    required this.onPressed,
  });

  final AppLocalizations l10n;
  final ThemeData theme;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final muted = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.72),
      fontWeight: FontWeight.w500,
      letterSpacing: 0.2,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 2),
          child: Text(
            l10n.createListingOrSeparator,
            textAlign: TextAlign.center,
            style: muted,
          ),
        ),
        _ManualVehicleAction(
          l10n: l10n,
          theme: theme,
          enabled: enabled,
          onPressed: onPressed,
        ),
      ],
    );
  }
}

class _ManualVehicleAction extends StatelessWidget {
  const _ManualVehicleAction({
    required this.l10n,
    required this.theme,
    required this.enabled,
    required this.onPressed,
  });

  final AppLocalizations l10n;
  final ThemeData theme;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    final light = theme.brightness == Brightness.light;
    final title = l10n.createListingManualVehicleTitle;
    final subtitle = l10n.createListingManualVehicleSubtitle;
    final iconColor = createListingContactIconColor(theme);
    final fill = Color.alphaBlend(
      cs.primary.withValues(alpha: light ? 0.055 : 0.12),
      cs.surface,
    );
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Semantics(
        button: true,
        enabled: enabled,
        label: '$title. $subtitle',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: const ValueKey('create_listing_enter_manually'),
            onTap: enabled ? onPressed : null,
            borderRadius: BorderRadius.circular(kCreateListingFieldRadius),
            child: Ink(
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(kCreateListingFieldRadius),
                border: Border.all(
                  color: createListingFieldBorder(theme, focused: false),
                  width: 0.8,
                ),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 54),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
                  child: Row(
                    children: [
                      Icon(
                        CarzonIcons.coverCarPlaceholder,
                        size: 20,
                        color: iconColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ExcludeSemantics(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                title,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.15,
                                  height: 1.2,
                                  color: cs.onSurface.withValues(
                                    alpha: light ? 0.92 : 0.96,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                subtitle,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant.withValues(
                                    alpha: light ? 0.72 : 0.78,
                                  ),
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Icon(
                        CarzonIcons.chevronRight,
                        size: 18,
                        color: createListingPickerChevronColor(
                          theme,
                          enabled: enabled,
                          empty: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageBlock extends StatelessWidget {
  const _MessageBlock({
    super.key,
    required this.theme,
    required this.title,
    required this.body,
    required this.child,
    this.highlight,
    this.highlightKey,
  });

  final ThemeData theme;
  final String? title;
  final String? highlight;
  final Key? highlightKey;
  final String body;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null && title!.isNotEmpty)
            Text(
              title!,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          if (highlight != null && highlight!.isNotEmpty)
            Text(
              highlight!,
              key: highlightKey,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          Text(
            body,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _ResolvedCard extends StatelessWidget {
  const _ResolvedCard({
    required this.l10n,
    required this.theme,
    required this.suggestion,
    required this.warnings,
    required this.confirmed,
    required this.compactMake,
    required this.compactModel,
    required this.compactYear,
    required this.compactVariant,
    required this.enabled,
    required this.onConfirm,
    required this.onChangeManually,
  });

  final AppLocalizations l10n;
  final ThemeData theme;
  final VehicleResolveSuggestion? suggestion;
  final List<String> warnings;
  final bool confirmed;
  final String compactMake;
  final String compactModel;
  final int? compactYear;
  final String? compactVariant;
  final bool enabled;
  final VoidCallback onConfirm;
  final VoidCallback onChangeManually;

  @override
  Widget build(BuildContext context) {
    final vehicle = suggestion;
    if (vehicle == null) return const SizedBox.shrink();
    final cs = theme.colorScheme;
    final light = theme.brightness == Brightness.light;
    final muted = theme.textTheme.labelMedium?.copyWith(
      color: cs.onSurface.withValues(alpha: light ? 0.48 : 0.58),
      fontWeight: FontWeight.w500,
    );
    final titleStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
      height: 1.2,
      fontSize: 18,
      color: cs.onSurface.withValues(alpha: light ? 0.94 : 0.96),
    );
    final secondaryStyle = theme.textTheme.bodyMedium?.copyWith(
      color: cs.onSurface.withValues(alpha: light ? 0.58 : 0.68),
      height: 1.3,
    );

    final make = compactMake.trim().isNotEmpty
        ? compactMake.trim()
        : (vehicle.make ?? '');
    final model = compactModel.trim().isNotEmpty
        ? compactModel.trim()
        : (vehicle.model ?? '');
    final year = compactYear ?? vehicle.year;
    final variant = (compactVariant?.trim().isNotEmpty ?? false)
        ? compactVariant!.trim()
        : vehicle.variantHint;
    final primary = createListingConfirmedIdentityPrimary(
      make: make,
      model: model,
      year: year,
    );
    final spec = vinResolveDisplaySpec(
      vehicle: vehicle,
      warnings: warnings,
      l10n: l10n,
    );
    final specLines = _VinSpecLines(
      spec: spec,
      theme: theme,
      secondaryStyle: secondaryStyle,
    );

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: DecoratedBox(
        key: const ValueKey('create_listing_vehicle_found_card'),
        decoration: createListingIdentityCardDecoration(theme),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!confirmed) ...[
                Text(l10n.createListingVehicleFound, style: muted),
                const SizedBox(height: 6),
                Text(primary, style: titleStyle),
                if (variant != null) ...[
                  const SizedBox(height: 3),
                  Text(variant, style: secondaryStyle),
                ],
                specLines,
                const SizedBox(height: 12),
                Wrap(
                  spacing: 4,
                  runSpacing: 0,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    FilledButton(
                      key: const ValueKey('create_listing_confirm_vehicle'),
                      style: createListingConfirmButtonStyle(theme),
                      onPressed: enabled ? onConfirm : null,
                      child: Text(l10n.createListingConfirmVehicle),
                    ),
                    CreateListingSecondaryAction(
                      label: l10n.createListingChangeManually,
                      enabled: enabled,
                      onPressed: onChangeManually,
                    ),
                  ],
                ),
              ] else
                Column(
                  key: const ValueKey(
                    'create_listing_vehicle_confirmed_summary',
                  ),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      container: true,
                      label: [
                        primary,
                        ?variant,
                        if (spec.line1.isNotEmpty) spec.line1,
                        if (spec.line2.isNotEmpty) spec.line2,
                        ?spec.body,
                        ?spec.caution,
                        l10n.createListingVehicleIdentifiedFromVin,
                      ].join('. '),
                      child: ExcludeSemantics(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(primary, style: titleStyle),
                            if (variant != null) ...[
                              const SizedBox(height: 3),
                              Text(variant, style: secondaryStyle),
                            ],
                            specLines,
                            const SizedBox(height: 4),
                            Text(
                              l10n.createListingVehicleIdentifiedFromVin,
                              style: muted,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: CreateListingSecondaryAction(
                        key: const ValueKey(
                          'create_listing_change_confirmed_vehicle',
                        ),
                        label: l10n.createListingChangeManually,
                        enabled: enabled,
                        onPressed: onChangeManually,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VinSpecLines extends StatelessWidget {
  const _VinSpecLines({
    required this.spec,
    required this.theme,
    required this.secondaryStyle,
  });

  final VinResolveDisplaySpec spec;
  final ThemeData theme;
  final TextStyle? secondaryStyle;

  @override
  Widget build(BuildContext context) {
    if (!spec.hasTechnicalLines && spec.caution == null) {
      return const SizedBox.shrink();
    }
    final cs = theme.colorScheme;
    return Column(
      key: const ValueKey('create_listing_vin_spec_summary'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (spec.line1.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            spec.line1,
            key: const ValueKey('create_listing_vin_spec_line1'),
            style: secondaryStyle,
          ),
        ],
        if (spec.line2.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            spec.line2,
            key: const ValueKey('create_listing_vin_spec_line2'),
            style: secondaryStyle,
          ),
        ],
        if (spec.body != null) ...[
          const SizedBox(height: 3),
          Text(
            spec.body!,
            key: const ValueKey('create_listing_vin_spec_body'),
            style: secondaryStyle,
          ),
        ],
        if (spec.caution != null) ...[
          const SizedBox(height: 8),
          Text(
            spec.caution!,
            key: const ValueKey('create_listing_vin_spec_caution'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }
}
