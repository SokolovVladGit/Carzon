import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../listings/domain/entities/listing.dart';
import '../../../listings/presentation/utils/listing_formatters.dart';
import '../models/create_listing_quick_choices.dart';
import 'create_listing_quiet_surface.dart';

/// Missing-characteristic questions under the facts card.
///
/// One or two gaps are shown immediately. Three or more show the first two
/// and keep the rest behind a text action. The parent owns the form values.
class CreateListingCharacteristicQuickPicks extends StatefulWidget {
  const CreateListingCharacteristicQuickPicks({
    super.key,
    required this.missing,
    required this.enabled,
    required this.onDrivetrain,
    required this.onTransmission,
    required this.onDoors,
    required this.onSeats,
    required this.onCylinders,
  });

  final List<CreateListingQuickChoiceKind> missing;
  final bool enabled;
  final ValueChanged<ListingDrivetrain> onDrivetrain;
  final ValueChanged<ListingTransmissionType> onTransmission;
  final ValueChanged<int> onDoors;
  final ValueChanged<int> onSeats;
  final ValueChanged<int> onCylinders;

  @override
  State<CreateListingCharacteristicQuickPicks> createState() =>
      _CreateListingCharacteristicQuickPicksState();
}

class _CreateListingCharacteristicQuickPicksState
    extends State<CreateListingCharacteristicQuickPicks> {
  /// Kept across step changes. Ignored once fewer than three questions remain.
  bool _extrasOpen = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final visible = createListingVisibleQuickChoices(
      widget.missing,
      extrasOpen: _extrasOpen,
    );
    final hidden = createListingHiddenQuickChoiceCount(
      widget.missing,
      extrasOpen: _extrasOpen,
    );
    final single = widget.missing.length == 1;

    return Column(
      key: const ValueKey('create_listing_quick_choices_body'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < visible.length; i++) ...[
          if (i > 0) const SizedBox(height: 14),
          _QuickChoiceGroup(
            kind: visible[i],
            l10n: l10n,
            enabled: widget.enabled,
            showHint: single,
            onDrivetrain: widget.onDrivetrain,
            onTransmission: widget.onTransmission,
            onCount: switch (visible[i]) {
              CreateListingQuickChoiceKind.doors => widget.onDoors,
              CreateListingQuickChoiceKind.seats => widget.onSeats,
              CreateListingQuickChoiceKind.cylinders => widget.onCylinders,
              _ => null,
            },
          ),
        ],
        if (hidden > 0)
          _QuickChoiceTextAction(
            key: const ValueKey('create_listing_quick_choices_more'),
            label: l10n.createListingQuickChoicesMoreCount(hidden),
            enabled: widget.enabled,
            onPressed: () => setState(() => _extrasOpen = true),
          ),
        if (widget.missing.length > kCreateListingQuickChoicesPreviewCount &&
            _extrasOpen)
          _QuickChoiceTextAction(
            key: const ValueKey('create_listing_quick_choices_collapse'),
            label: l10n.createListingQuickChoicesCollapse,
            enabled: widget.enabled,
            onPressed: () => setState(() => _extrasOpen = false),
          ),
      ],
    );
  }
}

class _QuickChoiceGroup extends StatelessWidget {
  const _QuickChoiceGroup({
    required this.kind,
    required this.l10n,
    required this.enabled,
    required this.showHint,
    required this.onDrivetrain,
    required this.onTransmission,
    required this.onCount,
  });

  final CreateListingQuickChoiceKind kind;
  final AppLocalizations l10n;
  final bool enabled;
  final bool showHint;
  final ValueChanged<ListingDrivetrain> onDrivetrain;
  final ValueChanged<ListingTransmissionType> onTransmission;
  final ValueChanged<int>? onCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(
      alpha: theme.brightness == Brightness.light ? 0.55 : 0.68,
    );
    final label = switch (kind) {
      CreateListingQuickChoiceKind.drivetrain =>
        l10n.createListingQuickChoiceAskDrivetrain,
      CreateListingQuickChoiceKind.transmission =>
        l10n.createListingQuickChoiceAskTransmission,
      CreateListingQuickChoiceKind.doors =>
        l10n.createListingQuickChoiceAskDoors,
      CreateListingQuickChoiceKind.seats =>
        l10n.createListingQuickChoiceAskSeats,
      CreateListingQuickChoiceKind.cylinders =>
        l10n.createListingQuickChoiceAskCylinders,
    };

    return Column(
      key: ValueKey('create_listing_quick_field_${kind.name}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: createListingQuietTitleStyle(theme),
        ),
        if (showHint) ...[
          const SizedBox(height: 2),
          Text(
            l10n.createListingQuickChoiceHint,
            key: const ValueKey('create_listing_quick_choices_hint'),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: muted,
              fontSize: 13,
              height: 1.25,
            ),
          ),
        ],
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: switch (kind) {
            CreateListingQuickChoiceKind.drivetrain => [
              for (final value in ListingDrivetrain.values)
                _QuickChip(
                  key: ValueKey(
                    'create_listing_quick_drivetrain_${value.name}',
                  ),
                  label: formatListingDrivetrain(l10n, value),
                  enabled: enabled,
                  onPressed: () => onDrivetrain(value),
                ),
            ],
            CreateListingQuickChoiceKind.transmission => [
              for (final value in ListingTransmissionType.values)
                _QuickChip(
                  key: ValueKey(
                    'create_listing_quick_transmission_${value.name}',
                  ),
                  label: formatListingTransmissionType(l10n, value),
                  enabled: enabled,
                  onPressed: () => onTransmission(value),
                ),
            ],
            _ => [
              for (final value in createListingQuickCountChoices(kind))
                _QuickChip(
                  key: ValueKey('create_listing_quick_${kind.name}_$value'),
                  label: '$value',
                  enabled: enabled,
                  onPressed: () => onCount?.call(value),
                ),
              _QuickChip(
                key: ValueKey('create_listing_quick_${kind.name}_more'),
                label: l10n.createListingQuickChoicesMore,
                enabled: enabled,
                onPressed: () => _openRemainingCounts(context),
              ),
            ],
          },
        ),
      ],
    );
  }

  Future<void> _openRemainingCounts(BuildContext context) async {
    final max = createListingQuickCountMax(kind);
    if (max < 1) return;
    final picked = await showCreateListingQuickCountPicker(
      context: context,
      title: switch (kind) {
        CreateListingQuickChoiceKind.doors => l10n.listingDoors,
        CreateListingQuickChoiceKind.seats => l10n.listingSeats,
        _ => l10n.listingEngineCylinders,
      },
      max: max,
    );
    if (picked == null) return;
    onCount?.call(picked);
  }
}

Future<int?> showCreateListingQuickCountPicker({
  required BuildContext context,
  required String title,
  required int max,
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return _QuickCountSheet(title: title, max: max);
    },
  );
}

class _QuickChoiceTextAction extends StatelessWidget {
  const _QuickChoiceTextAction({
    super.key,
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = theme.colorScheme.onSurface.withValues(
      alpha: theme.brightness == Brightness.light ? 0.72 : 0.8,
    );
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        style: TextButton.styleFrom(
          foregroundColor: ink,
          disabledForegroundColor: ink.withValues(alpha: 0.38),
          padding: const EdgeInsets.symmetric(vertical: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          alignment: Alignment.centerLeft,
          overlayColor: theme.colorScheme.onSurface.withValues(alpha: 0.06),
        ),
        onPressed: enabled ? onPressed : null,
        child: Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelLarge?.copyWith(
            color: enabled ? ink : ink.withValues(alpha: 0.38),
            fontWeight: FontWeight.w600,
            fontSize: 13,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}

class _QuickCountSheet extends StatelessWidget {
  const _QuickCountSheet({required this.title, required this.max});

  final String title;
  final int max;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final height = MediaQuery.sizeOf(context).height;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: height * 0.55),
        child: Column(
          key: const ValueKey('create_listing_quick_count_sheet'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var n = 1; n <= max; n++)
                      _QuickChip(
                        key: ValueKey('create_listing_quick_count_$n'),
                        label: '$n',
                        enabled: true,
                        onPressed: () => Navigator.pop(context, n),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({
    super.key,
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final light = theme.brightness == Brightness.light;
    final cs = theme.colorScheme;
    final fill = light
        ? const Color(0xFFF3EBE3)
        : Color.alphaBlend(cs.onSurface.withValues(alpha: 0.10), cs.surface);
    final ink = cs.onSurface.withValues(alpha: light ? 0.88 : 0.92);

    return Material(
      color: fill,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: enabled ? onPressed : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              color: enabled ? ink : ink.withValues(alpha: 0.38),
              fontWeight: FontWeight.w600,
              fontSize: 13,
              height: 1.15,
            ),
          ),
        ),
      ),
    );
  }
}
