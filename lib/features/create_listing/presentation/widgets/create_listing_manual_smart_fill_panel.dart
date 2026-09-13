import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../listings/domain/entities/listing.dart';
import '../../../listings/presentation/utils/listing_formatters.dart';
import '../../domain/entities/manual_smart_fill_refinement.dart';
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
    required this.onSelectOption,
    required this.onDontKnow,
    required this.onRetry,
    this.onRestart,
  });

  final AppLocalizations l10n;
  final ThemeData theme;
  final ManualSmartFillState state;
  final bool enabled;
  final String filledSummary;
  final ValueChanged<ManualSmartFillRefinementOption> onSelectOption;
  final VoidCallback onDontKnow;
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
        onSelectOption: onSelectOption,
        onDontKnow: onDontKnow,
        onRestart: onRestart,
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
    required this.onSelectOption,
    required this.onDontKnow,
    this.onRestart,
  });

  final AppLocalizations l10n;
  final ThemeData theme;
  final ManualSmartFillState state;
  final bool enabled;
  final String filledSummary;
  final ValueChanged<ManualSmartFillRefinementOption> onSelectOption;
  final VoidCallback onDontKnow;
  final VoidCallback? onRestart;

  @override
  Widget build(BuildContext context) {
    final showRestart = state.canRestart && onRestart != null;
    final showCard = state.showClarification || showRestart;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (filledSummary.isNotEmpty)
          _FilledChips(
            key: const ValueKey('create_listing_smart_fill_summary'),
            theme: theme,
            summary: filledSummary,
          ),
        if (showCard)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: DecoratedBox(
              decoration: createListingIdentityCardDecoration(theme),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (state.showClarification)
                    _RefinementBody(
                      l10n: l10n,
                      theme: theme,
                      next: state.result?.nextRefinement,
                      clarification: state.result?.clarification,
                      enabled: enabled,
                      onSelectOption: onSelectOption,
                      onDontKnow: onDontKnow,
                    ),
                  if (showRestart) ...[
                    if (state.showClarification)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: kCreateListingModulePad,
                        ),
                        child: ColoredBox(
                          color: createListingHairlineColor(theme),
                          child: const SizedBox(height: 1),
                        ),
                      ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          12,
                          state.showClarification ? 2 : 6,
                          12,
                          6,
                        ),
                        child: CreateListingSecondaryAction(
                          key: const ValueKey(
                            'create_listing_smart_fill_restart',
                          ),
                          label: l10n.createListingSmartFillRestart,
                          enabled: enabled,
                          footer: true,
                          onPressed: onRestart!,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _RefinementBody extends StatelessWidget {
  const _RefinementBody({
    required this.l10n,
    required this.theme,
    required this.next,
    required this.clarification,
    required this.enabled,
    required this.onSelectOption,
    required this.onDontKnow,
  });

  final AppLocalizations l10n;
  final ThemeData theme;
  final ManualSmartFillNextRefinement? next;
  final ManualSmartFillClarification? clarification;
  final bool enabled;
  final ValueChanged<ManualSmartFillRefinementOption> onSelectOption;
  final VoidCallback onDontKnow;

  @override
  Widget build(BuildContext context) {
    final kind =
        next?.kind ??
        parseManualSmartFillRefinementKind(clarification?.attribute);
    if (kind == null) return const SizedBox.shrink();

    final options = next != null
        ? next!.options
        : [
            for (final option in clarification?.options ?? const [])
              ManualSmartFillRefinementOption(
                id: option.value,
                kind: kind,
                candidateCount: option.candidateCount ?? 0,
                bodyType: kind == ManualSmartFillRefinementKind.body
                    ? option.value
                    : null,
                fuelType: kind == ManualSmartFillRefinementKind.fuel
                    ? option.value
                    : null,
                transmissionType:
                    kind == ManualSmartFillRefinementKind.transmission
                    ? option.value
                    : null,
              ),
          ];

    final labeled = <({ManualSmartFillRefinementOption option, String label})>[
      for (final option in options)
        if (_optionLabel(l10n, option) != null)
          (option: option, label: _optionLabel(l10n, option)!),
    ];
    if (labeled.isEmpty) return const SizedBox.shrink();

    return Padding(
      key: const ValueKey('create_listing_smart_fill_clarification'),
      padding: const EdgeInsets.fromLTRB(
        kCreateListingModulePad,
        14,
        kCreateListingModulePad,
        8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.createListingSmartFillSeveralVersions,
            style: createListingSupportStyle(
              theme,
            )?.copyWith(fontSize: 12.5, letterSpacing: 0.02),
          ),
          const SizedBox(height: 4),
          Text(
            manualSmartFillClarificationPrompt(l10n, kind.wireValue),
            style: createListingQuestionStyle(theme),
          ),
          const SizedBox(height: 12),
          if (kind == ManualSmartFillRefinementKind.engine)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final item in labeled)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _EngineOptionTile(
                      optionId: item.option.id,
                      label: item.label,
                      enabled: enabled,
                      onPressed: () => onSelectOption(item.option),
                    ),
                  ),
              ],
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in labeled)
                  ActionChip(
                    key: ValueKey(
                      'create_listing_smart_fill_option_${item.option.canonicalValue ?? item.option.id}',
                    ),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                    side: BorderSide(
                      color: createListingFieldBorder(theme, focused: false),
                      width: 0.7,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        kCreateListingSegmentRadius,
                      ),
                    ),
                    backgroundColor: createListingFieldFill(
                      theme,
                      hasValue: false,
                    ),
                    label: Text(
                      item.label,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.08,
                        color: createListingValueColor(theme, enabled: enabled),
                      ),
                    ),
                    onPressed: enabled
                        ? () => onSelectOption(item.option)
                        : null,
                  ),
              ],
            ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: CreateListingSecondaryAction(
              key: const ValueKey('create_listing_smart_fill_dont_know'),
              label: l10n.createListingSmartFillDontKnow,
              enabled: enabled,
              footer: true,
              onPressed: onDontKnow,
            ),
          ),
        ],
      ),
    );
  }
}

class _EngineOptionTile extends StatelessWidget {
  const _EngineOptionTile({
    required this.optionId,
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  final String optionId;
  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(kCreateListingFieldRadius);
    return Material(
      key: ValueKey('create_listing_smart_fill_option_$optionId'),
      color: createListingFieldFill(theme, hasValue: false),
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(
          color: createListingFieldBorder(theme, focused: false),
          width: 0.7,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: radius,
        splashColor: theme.colorScheme.onSurface.withValues(alpha: 0.06),
        highlightColor: theme.colorScheme.onSurface.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                letterSpacing: -0.1,
                height: 1.25,
                color: createListingValueColor(theme, enabled: enabled),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String? _optionLabel(
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
