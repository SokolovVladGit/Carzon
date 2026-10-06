import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/vehicle_resolve_result.dart';
import '../bloc/create_listing_state.dart';
import 'create_listing_compose_layout.dart';

class CreateListingVehicleResolvePanel extends StatelessWidget {
  const CreateListingVehicleResolvePanel({
    super.key,
    required this.l10n,
    required this.theme,
    required this.resolve,
    required this.enabled,
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
  final VoidCallback onEnterManual;
  final VoidCallback onRetry;
  final String compactMake;
  final String compactModel;
  final int? compactYear;
  final String? compactVariant;

  @override
  Widget build(BuildContext context) {
    return switch (resolve.status) {
      CreateListingVinResolveStatus.idle => const SizedBox.shrink(),
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

class _ManualVehicleAction extends StatelessWidget {
  const _ManualVehicleAction({
    required this.l10n,
    required this.enabled,
    required this.onPressed,
  });

  final AppLocalizations l10n;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: CreateListingManualEntryLink(
        key: const ValueKey('create_listing_enter_manually'),
        label: l10n.createListingEnterManually,
        enabled: enabled,
        onPressed: onPressed,
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
      letterSpacing: -0.25,
      height: 1.15,
      fontSize: 17,
      color: cs.onSurface.withValues(alpha: light ? 0.94 : 0.96),
    );
    final secondaryStyle = theme.textTheme.bodyMedium?.copyWith(
      color: cs.onSurface.withValues(alpha: light ? 0.62 : 0.72),
      height: 1.25,
      fontSize: 14,
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
    final caution = warnings.isEmpty
        ? null
        : l10n.createListingVinSpecCaution;

    return Padding(
      padding: EdgeInsets.only(top: confirmed ? 4 : 10),
      child: DecoratedBox(
        key: const ValueKey('create_listing_vehicle_found_card'),
        decoration: createListingComposeCardDecoration(theme),
        child: Padding(
          padding: confirmed
              ? const EdgeInsets.fromLTRB(14, 8, 14, 0)
              : const EdgeInsets.fromLTRB(14, 12, 14, 10),
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
                if (caution != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    caution,
                    key: const ValueKey('create_listing_vin_spec_caution'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: CreateListingSecondaryAction(
                    label: l10n.createListingChangeManually,
                    enabled: enabled,
                    onPressed: onChangeManually,
                  ),
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
                        ?caution,
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
                            if (caution != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                caution,
                                key: const ValueKey(
                                  'create_listing_vin_spec_caution',
                                ),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                  height: 1.35,
                                ),
                              ),
                            ],
                            const SizedBox(height: 6),
                            Text(
                              l10n.createListingVehicleIdentifiedFromVin,
                              style: muted?.copyWith(fontSize: 12, height: 1.2),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
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
