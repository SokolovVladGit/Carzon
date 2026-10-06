import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../listings/domain/entities/listing.dart';
import '../../../listings/presentation/utils/listing_formatters.dart';
import '../../domain/entities/manual_smart_fill_refinement.dart';
import '../bloc/manual_smart_fill_state.dart';
import '../models/catalog_resolved_form_prefill.dart';
import '../models/listing_preview_data.dart';
import 'create_listing_compose_layout.dart';

class CreateListingManualSmartFillPanel extends StatelessWidget {
  const CreateListingManualSmartFillPanel({
    super.key,
    required this.l10n,
    required this.theme,
    required this.state,
    required this.enabled,
    required this.filledSummary,
    required this.onRetry,
    this.onRestart,
  });

  final AppLocalizations l10n;
  final ThemeData theme;
  final ManualSmartFillState state;
  final bool enabled;
  final String filledSummary;
  final VoidCallback onRetry;
  final VoidCallback? onRestart;

  @override
  Widget build(BuildContext context) {
    return switch (state.status) {
      ManualSmartFillStatus.idle => const SizedBox.shrink(),
      ManualSmartFillStatus.loading => _StatusRow(
        key: const ValueKey('create_listing_smart_fill_loading'),
        theme: theme,
        text: l10n.createListingSmartFillLoading,
      ),
      ManualSmartFillStatus.noData => _MutedText(
        key: const ValueKey('create_listing_smart_fill_no_data'),
        theme: theme,
        text: l10n.createListingSmartFillNoData,
      ),
      ManualSmartFillStatus.failure => _FailureBlock(
        l10n: l10n,
        theme: theme,
        enabled: enabled,
        onRetry: onRetry,
      ),
      ManualSmartFillStatus.filled ||
      ManualSmartFillStatus.needsClarification => _SmartFillModule(
        l10n: l10n,
        theme: theme,
        state: state,
        enabled: enabled,
        filledSummary: filledSummary,
        onRestart: onRestart,
      ),
    };
  }
}

String manualSmartFillClarificationPrompt(
  AppLocalizations l10n,
  String attribute,
) {
  return switch (attribute) {
    'body' => l10n.createListingSmartFillAskBody,
    'fuel' => l10n.createListingSmartFillAskFuel,
    'engine' => l10n.createListingSmartFillAskEngine,
    'transmission' => l10n.createListingSmartFillAskTransmission,
    _ => l10n.createListingSmartFillSeveralVersions,
  };
}

@visibleForTesting
String? manualSmartFillOptionLabel(
  AppLocalizations l10n,
  String attribute,
  String value,
) {
  if (attribute == 'body') {
    final type = catalogResolvedBodyType(value);
    return type == null ? null : formatListingBodyType(l10n, type);
  }
  if (attribute == 'fuel') {
    final type = catalogResolvedFuelType(value);
    return type == null ? null : formatListingFuelType(l10n, type);
  }
  if (attribute == 'transmission') {
    final type = catalogResolvedTransmissionType(value);
    if (type == null || type == ListingTransmissionType.other) return null;
    return formatListingTransmissionType(l10n, type);
  }
  return null;
}

@visibleForTesting
String? manualSmartFillEngineOptionLabel(
  AppLocalizations l10n,
  ManualSmartFillRefinementOption option,
) {
  final fuel = catalogResolvedFuelType(option.fuelType);
  final liters = catalogResolvedDisplacementLiters(
    option.engineDisplacementLiters,
  );
  final hp = catalogResolvedPowerHp(option.enginePowerHp);
  if (fuel == null || liters == null || hp == null) return null;
  return [
    formatListingFuelType(l10n, fuel),
    formatEngineDisplacementForDisplay(l10n, liters),
    formatEnginePowerHpDisplay(l10n, hp),
  ].join(' · ');
}

String manualSmartFillFilledSummary(
  AppLocalizations l10n, {
  ListingBodyType? bodyType,
  ListingFuelType? fuelType,
  double? displacementLiters,
}) {
  return listingPreviewJoin([
    if (bodyType != null) formatListingBodyType(l10n, bodyType),
    if (fuelType != null) formatListingFuelType(l10n, fuelType),
    if (displacementLiters != null)
      formatEngineDisplacementForDisplay(l10n, displacementLiters),
  ]);
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({super.key, required this.theme, required this.text});

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
          Expanded(child: Text(text, style: createListingSupportStyle(theme))),
        ],
      ),
    );
  }
}

class _MutedText extends StatelessWidget {
  const _MutedText({super.key, required this.theme, required this.text});

  final ThemeData theme;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(text, style: createListingSupportStyle(theme)),
    );
  }
}

class _FilledChips extends StatelessWidget {
  const _FilledChips({super.key, required this.theme, required this.summary});

  final ThemeData theme;
  final String summary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        summary,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
          fontWeight: FontWeight.w500,
          height: 1.35,
          letterSpacing: -0.08,
        ),
      ),
    );
  }
}

class _FailureBlock extends StatelessWidget {
  const _FailureBlock({
    required this.l10n,
    required this.theme,
    required this.enabled,
    required this.onRetry,
  });

  final AppLocalizations l10n;
  final ThemeData theme;
  final bool enabled;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.createListingSmartFillFailed,
            style: createListingSupportStyle(theme),
          ),
          CreateListingSecondaryAction(
            key: const ValueKey('create_listing_smart_fill_retry'),
            label: l10n.commonRetry,
            enabled: enabled,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

class _SmartFillModule extends StatelessWidget {
  const _SmartFillModule({
    required this.l10n,
    required this.theme,
    required this.state,
    required this.enabled,
    required this.filledSummary,
    this.onRestart,
  });

  final AppLocalizations l10n;
  final ThemeData theme;
  final ManualSmartFillState state;
  final bool enabled;
  final String filledSummary;
  final VoidCallback? onRestart;

  @override
  Widget build(BuildContext context) {
    final showRestart =
        !state.showClarification && state.canRestart && onRestart != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (filledSummary.isNotEmpty)
          _FilledChips(
            key: const ValueKey('create_listing_smart_fill_summary'),
            theme: theme,
            summary: filledSummary,
          ),
        if (state.showClarification)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              l10n.createListingSmartFillPending,
              key: const ValueKey('create_listing_smart_fill_pending'),
              style: createListingSupportStyle(theme),
            ),
          ),
        if (showRestart)
          Align(
            alignment: Alignment.centerLeft,
            child: CreateListingSecondaryAction(
              key: const ValueKey('create_listing_smart_fill_restart'),
              label: l10n.createListingSmartFillRestart,
              enabled: enabled,
              footer: true,
              onPressed: onRestart!,
            ),
          ),
      ],
    );
  }
}


String? manualSmartFillRefinementOptionLabel(
  AppLocalizations l10n,
  ManualSmartFillRefinementOption option,
) {
  if (option.kind == ManualSmartFillRefinementKind.engine) {
    return manualSmartFillEngineOptionLabel(l10n, option);
  }
  final value = option.canonicalValue;
  if (value == null) return null;
  return manualSmartFillOptionLabel(l10n, option.kind.wireValue, value);
}
