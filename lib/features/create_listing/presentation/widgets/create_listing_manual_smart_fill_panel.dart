import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../listings/domain/entities/listing.dart';
import '../../../listings/presentation/utils/listing_formatters.dart';
import '../../domain/entities/manual_smart_fill_result.dart';
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
    required this.onAnswer,
    required this.onDontKnow,
    required this.onRetry,
  });

  final AppLocalizations l10n;
  final ThemeData theme;
  final ManualSmartFillState state;
  final bool enabled;
  final String filledSummary;
  final void Function(String attribute, String value) onAnswer;
  final VoidCallback onDontKnow;
  final VoidCallback onRetry;

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
      ManualSmartFillStatus.needsClarification => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (filledSummary.isNotEmpty)
            _FilledChips(
              key: const ValueKey('create_listing_smart_fill_summary'),
              theme: theme,
              summary: filledSummary,
            ),
          if (state.showClarification)
            _ClarificationCard(
              l10n: l10n,
              theme: theme,
              clarification: state.result!.clarification!,
              enabled: enabled,
              onAnswer: onAnswer,
              onDontKnow: onDontKnow,
            ),
        ],
      ),
    };
  }
}

@visibleForTesting
String manualSmartFillClarificationPrompt(
  AppLocalizations l10n,
  String attribute,
) {
  return switch (attribute) {
    'body' => l10n.createListingSmartFillAskBody,
    'fuel' => l10n.createListingSmartFillAskFuel,
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
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
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
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          height: 1.35,
        ),
      ),
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
          color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
          fontWeight: FontWeight.w500,
          height: 1.35,
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
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
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

class _ClarificationCard extends StatelessWidget {
  const _ClarificationCard({
    required this.l10n,
    required this.theme,
    required this.clarification,
    required this.enabled,
    required this.onAnswer,
    required this.onDontKnow,
  });

  final AppLocalizations l10n;
  final ThemeData theme;
  final ManualSmartFillClarification clarification;
  final bool enabled;
  final void Function(String attribute, String value) onAnswer;
  final VoidCallback onDontKnow;

  @override
  Widget build(BuildContext context) {
    final options = [
      for (final option in clarification.options)
        if (manualSmartFillOptionLabel(
              l10n,
              clarification.attribute,
              option.value,
            ) !=
            null)
          (
            value: option.value,
            label: manualSmartFillOptionLabel(
              l10n,
              clarification.attribute,
              option.value,
            )!,
          ),
    ];
    if (options.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: DecoratedBox(
        key: const ValueKey('create_listing_smart_fill_clarification'),
        decoration: createListingIdentityCardDecoration(theme),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.createListingSmartFillSeveralVersions,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                manualSmartFillClarificationPrompt(
                  l10n,
                  clarification.attribute,
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final option in options)
                    ActionChip(
                      key: ValueKey(
                        'create_listing_smart_fill_option_${option.value}',
                      ),
                      label: Text(option.label),
                      onPressed: enabled
                          ? () =>
                                onAnswer(clarification.attribute, option.value)
                          : null,
                    ),
                ],
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: CreateListingSecondaryAction(
                  key: const ValueKey('create_listing_smart_fill_dont_know'),
                  label: l10n.createListingSmartFillDontKnow,
                  enabled: enabled,
                  onPressed: onDontKnow,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
