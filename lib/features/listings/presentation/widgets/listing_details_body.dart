import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/errors/content_moderation_failure.dart';
import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/utils/result.dart';
import '../../../../shared/ui/carzon_icons.dart';
import '../../../sellers/presentation/widgets/seller_trust_section.dart';
import '../../domain/entities/listing.dart';
import '../utils/listing_formatters.dart';
import '../../domain/entities/listing_report_reason.dart';
import '../utils/listing_report_submitter.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import 'listing_details_vin_entry.dart';
import '../../../vehicle_model_data/presentation/widgets/listing_details_model_passport_section.dart';
import '../../../vehicle_recall_data/presentation/widgets/listing_details_recall_section.dart';

String? _nonEmptyTrimmedDescription(Listing listing) {
  final raw = listing.description;
  if (raw == null) return null;
  final t = raw.trim();
  return t.isEmpty ? null : t;
}

/// Below-hero content block: specs list, public-contact notice,
/// seller trust, optional report action.
///
/// Behavior, visuals, and localization keys are unchanged from the
/// previous same-library `part`; all inputs are passed explicitly.
class BelowHeroContent extends StatelessWidget {
  const BelowHeroContent({
    super.key,
    required this.listing,
    required this.reportSubmitter,
  });

  final Listing listing;
  final ListingReportSubmitter reportSubmitter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        _DetailsList(listing: listing),
        ListingDetailsModelPassportSection(listingId: listing.id),
        ListingDetailsRecallSection(listingId: listing.id),
        if (_nonEmptyTrimmedDescription(listing) case final desc?) ...[
          const SizedBox(height: 28),
          _ListingDescriptionBlock(text: desc),
        ],
        const SizedBox(height: 24),
        if (listing.sellerId != null &&
            listing.sellerId!.trim().isNotEmpty) ...[
          SellerTrustSection(sellerId: listing.sellerId!.trim()),
        ],
        Text(
          l10n.contactPublicNotice,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        _ReportLink(listing: listing, submitter: reportSubmitter),
      ],
    );
  }
}

/// Free-text seller description (shown only when non-empty).
class _ListingDescriptionBlock extends StatelessWidget {
  const _ListingDescriptionBlock({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.listingDetailsDescriptionSection,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          text,
          style: theme.textTheme.bodyLarge?.copyWith(
            height: 1.45,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.92),
          ),
        ),
      ],
    );
  }
}

/// Flat details list. Rows use editorial label/value layout; empty values omitted.
class _DetailsList extends StatelessWidget {
  const _DetailsList({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    bool hasValue(String v) => v.trim().isNotEmpty;

    final rows = <_DetailsRowData>[
      if (hasValue(listing.make))
        _DetailsRowData(l10n.listingFieldMake, listing.make.trim()),
      if (hasValue(listing.model))
        _DetailsRowData(l10n.listingFieldModel, listing.model.trim()),
      _DetailsRowData(l10n.listingFieldYear, listing.year.toString()),
      _DetailsRowData(
        l10n.listingFieldMileage,
        formatKm(l10n, listing.mileageKm),
      ),
      _DetailsRowData(l10n.listingFieldType, formatType(l10n, listing.type)),
      if (listing.bodyType != null)
        _DetailsRowData(
          l10n.listingFieldBodyType,
          formatListingBodyType(l10n, listing.bodyType!),
        ),
      if (hasValue(listing.city))
        _DetailsRowData(l10n.listingFieldCity, listing.city.trim()),
      if (listing.fuelType != null)
        _DetailsRowData(
          l10n.listingFuelType,
          formatListingFuelType(l10n, listing.fuelType!),
        ),
      if (listing.engineDisplacementLiters != null)
        _DetailsRowData(
          l10n.listingEngineDisplacement,
          formatEngineDisplacementForDisplay(
            l10n,
            listing.engineDisplacementLiters,
          ),
        ),
      if (listing.enginePowerHp != null)
        _DetailsRowData(
          l10n.listingEnginePower,
          formatEnginePowerHpDisplay(l10n, listing.enginePowerHp),
        ),
      if (listing.drivetrain != null)
        _DetailsRowData(
          l10n.listingDrivetrain,
          formatListingDrivetrain(l10n, listing.drivetrain!),
        ),
      if (listing.transmissionType != null)
        _DetailsRowData(
          l10n.compareRowTransmission,
          formatListingTransmissionType(l10n, listing.transmissionType!),
        ),
      if (listing.registration != null &&
          listing.registration!.trim().isNotEmpty)
        _DetailsRowData(l10n.listingRegistration, listing.registration!.trim()),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.listingDetailsSpecs,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
          ),
        ),
        const SizedBox(height: 14),
        ListingDetailsVinEntry(listing: listing),
        const SizedBox(height: 12),
        for (var i = 0; i < rows.length; i++)
          _ListingSpecRow(
            data: rows[i],
            showBottomDivider: i < rows.length - 1,
          ),
      ],
    );
  }
}

class _DetailsRowData {
  const _DetailsRowData(this.label, this.value);
  final String label;
  final String value;
}

/// Two-column spec row: muted label left, strong value right; optional
/// full-width row divider only (no label/value connector).
class _ListingSpecRow extends StatelessWidget {
  const _ListingSpecRow({required this.data, required this.showBottomDivider});

  final _DetailsRowData data;
  final bool showBottomDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final dividerAlpha = isDark ? 0.26 : 0.16;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 46,
                child: Text(
                  data.label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.78),
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.06,
                    height: 1.38,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 54,
                child: Text(
                  data.value,
                  textAlign: TextAlign.right,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.95),
                    fontWeight: FontWeight.w600,
                    height: 1.38,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showBottomDivider)
          Divider(
            height: 1,
            thickness: 0.5,
            color: scheme.outlineVariant.withValues(alpha: dividerAlpha),
          ),
      ],
    );
  }
}

/// Always-present native listing-report flow. Guests see the action and a
/// deterministic explanation that sign-in is required before submission.
class _ReportLink extends StatefulWidget {
  const _ReportLink({required this.listing, required this.submitter});

  final Listing listing;
  final ListingReportSubmitter submitter;

  @override
  State<_ReportLink> createState() => _ReportLinkState();
}

class _ReportLinkState extends State<_ReportLink> {
  bool _submitting = false;

  Future<void> _onTap(BuildContext context) async {
    if (_submitting) return;
    final l10n = context.l10n;
    final auth = context.read<AuthCubit>().state;
    final authenticated =
        auth.status == AuthStatus.authenticated && auth.user != null;
    if (!authenticated) {
      final shouldSignIn = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.reportListingSignInTitle),
          content: Text(l10n.reportListingSignInBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.commonSignIn),
            ),
          ],
        ),
      );
      if (shouldSignIn == true && context.mounted) {
        await context.push(AppRoutes.signIn);
      }
      return;
    }

    final submission = await showListingReportSheet(context);
    if (!context.mounted || submission == null) return;
    setState(() => _submitting = true);
    final result = await widget.submitter(
      listingId: widget.listing.id,
      reason: submission.reason,
      note: submission.note,
    );
    if (!context.mounted) return;
    setState(() => _submitting = false);
    final message = switch (result) {
      Success<void>() => l10n.reportListingSuccess,
      FailureResult(:final failure) when isContentRejectedFailure(failure) =>
        l10n.contentModerationRejected,
      FailureResult(:final failure)
          when failure.message.toLowerCase().contains('not authenticated') =>
        l10n.reportListingSignInBody,
      FailureResult() => l10n.reportListingSubmitFailed,
    };
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.reportListingDescription,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _submitting ? null : () => _onTap(context),
            icon: _submitting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(CarzonIcons.report),
            label: Text(l10n.reportListing),
          ),
        ),
      ],
    );
  }
}

class ListingReportSubmission {
  const ListingReportSubmission({required this.reason, this.note});

  final ListingReportReason reason;
  final String? note;
}

Future<ListingReportSubmission?> showListingReportSheet(BuildContext context) {
  return showModalBottomSheet<ListingReportSubmission>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _ListingReportSheet(),
  );
}

class _ListingReportSheet extends StatefulWidget {
  const _ListingReportSheet();

  @override
  State<_ListingReportSheet> createState() => _ListingReportSheetState();
}

class _ListingReportSheetState extends State<_ListingReportSheet> {
  ListingReportReason _reason = ListingReportReason.scam;
  final _noteController = TextEditingController();
  String? _noteError;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  String _reasonLabel(ListingReportReason reason) => switch (reason) {
    ListingReportReason.scam => context.l10n.reportListingReasonScam,
    ListingReportReason.spam => context.l10n.reportListingReasonSpam,
    ListingReportReason.inappropriate =>
      context.l10n.reportListingReasonInappropriate,
    ListingReportReason.misleading =>
      context.l10n.reportListingReasonMisleading,
    ListingReportReason.prohibited =>
      context.l10n.reportListingReasonProhibited,
    ListingReportReason.other => context.l10n.reportListingReasonOther,
  };

  void _submit() {
    final note = _noteController.text.trim();
    if (note.length > kListingReportNoteMaxLength) {
      setState(() => _noteError = context.l10n.reportListingNoteTooLong);
      return;
    }
    Navigator.pop(
      context,
      ListingReportSubmission(
        reason: _reason,
        note: note.isEmpty ? null : note,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.reportListingSheetTitle,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            RadioGroup<ListingReportReason>(
              groupValue: _reason,
              onChanged: (value) {
                if (value != null) setState(() => _reason = value);
              },
              child: Column(
                children: [
                  for (final reason in ListingReportReason.values)
                    RadioListTile<ListingReportReason>(
                      contentPadding: EdgeInsets.zero,
                      value: reason,
                      title: Text(_reasonLabel(reason)),
                    ),
                ],
              ),
            ),
            TextField(
              controller: _noteController,
              maxLines: 4,
              maxLength: kListingReportNoteMaxLength,
              decoration: InputDecoration(
                labelText: context.l10n.reportListingNoteLabel,
                hintText: context.l10n.reportListingNotePlaceholder,
                errorText: _noteError,
              ),
              onChanged: (_) {
                if (_noteError != null) setState(() => _noteError = null);
              },
            ),
            const SizedBox(height: 12),
            FilledButton(
              key: const ValueKey<String>('listing_report_submit'),
              onPressed: _submit,
              child: Text(context.l10n.reportListingSubmit),
            ),
          ],
        ),
      ),
    );
  }
}
