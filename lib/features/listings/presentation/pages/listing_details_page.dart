import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../favorites/presentation/widgets/favorite_toggle_button.dart';
import '../../domain/entities/listing.dart';
import '../bloc/listing_details_cubit.dart';
import '../bloc/listing_details_state.dart';
import '../utils/contact_format.dart';
import '../utils/listing_formatters.dart';
import '../utils/report_listing_mailto.dart';
import '../widgets/details_section_card.dart';
import '../widgets/listing_cover_image.dart';

/// Minimal launcher seam local to this page — mirrors the
/// `EditListingImagePicker` typedef on the edit-listing page so widget
/// tests can intercept `launchUrl` without owning a global abstraction.
typedef ListingDetailsUriLauncher = Future<bool> Function(Uri uri);

Future<bool> _launchExternalUri(Uri uri) =>
    launchUrl(uri, mode: LaunchMode.externalApplication);

/// Horizontal gutter applied to every section of the details page.
const double _pageHPadding = 16;

/// Vertical spacing between section cards.
const double _sectionGap = 16;

/// Radius used for the cover image on the details page. Matches
/// [DetailsSectionCard.radius] so the cover visually aligns with the
/// surrounding cards.
const double _coverRadius = DetailsSectionCard.radius;

class ListingDetailsPage extends StatelessWidget {
  const ListingDetailsPage({
    super.key,
    required this.id,
    this.reportEmail,
    this.uriLauncher,
    this.initialCoverImageUrl,
  });

  final String id;

  /// Optional ops/moderation inbox for the "Report listing" action.
  /// When `null` or empty, the report surface is hidden entirely —
  /// the MVP must never synthesize a fake recipient. The app router
  /// passes `Env.reportEmail` here so the value is configurable via
  /// `.env` without any rebuild.
  final String? reportEmail;

  /// Test seam for the "Report listing" mailto launcher. In production
  /// this is null and the widget falls back to [launchUrl]. The page's
  /// existing contact actions deliberately keep using [launchUrl]
  /// directly to minimise diff surface for this feature.
  final ListingDetailsUriLauncher? uriLauncher;

  /// Cover image URL already known by the navigating caller, passed
  /// through `GoRouter` `extra` so the Hero flight on the push
  /// transition animates the real tapped photo instead of the
  /// placeholder. Used only until [ListingDetailsCubit] emits a
  /// loaded [Listing], after which that listing's own
  /// `coverImageUrl` takes over. `null` on deep links.
  final String? initialCoverImageUrl;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ListingDetailsCubit>()..load(id),
      child: _ListingDetailsView(
        id: id,
        reportEmail: reportEmail,
        uriLauncher: uriLauncher,
        initialCoverImageUrl: initialCoverImageUrl,
      ),
    );
  }
}

class _ListingDetailsView extends StatelessWidget {
  const _ListingDetailsView({
    required this.id,
    required this.reportEmail,
    required this.uriLauncher,
    required this.initialCoverImageUrl,
  });

  final String id;
  final String? reportEmail;
  final ListingDetailsUriLauncher? uriLauncher;
  final String? initialCoverImageUrl;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallback: AppRoutes.listings),
        title: Text(l10n.listingDetailsTitle),
        actions: [FavoriteToggleButton(listingId: id)],
      ),
      // The Hero flight from the feed must find a destination Hero
      // with tag `listing-cover-<id>` on the first frame of the push
      // transition, regardless of cubit state. To guarantee that:
      //   - during initial / loading / failure we render a top-level
      //     cover placeholder using the URL passed via route `extra`.
      //   - in success we render exactly one cover inside the new
      //     card-based body (after the summary) using the loaded
      //     listing's own `coverImageUrl`.
      // Exactly one `ListingCoverImage` + one Hero with the id-based
      // tag is mounted at all times — existing Hero/back-button
      // widget tests keep passing unchanged.
      body: BlocBuilder<ListingDetailsCubit, ListingDetailsState>(
        builder: (context, state) {
          switch (state.status) {
            case ListingDetailsStatus.initial:
            case ListingDetailsStatus.loading:
              return _LoadingScaffold(
                listingId: id,
                initialCoverImageUrl: initialCoverImageUrl,
              );
            case ListingDetailsStatus.failure:
              return _FailureScaffold(
                listingId: id,
                initialCoverImageUrl: initialCoverImageUrl,
                message: state.errorMessage ?? l10n.listingDetailsLoadFailed,
                onRetry: () =>
                    context.read<ListingDetailsCubit>().load(id),
              );
            case ListingDetailsStatus.success:
              return _DetailsBody(
                listing: state.listing!,
                reportEmail: reportEmail,
                uriLauncher: uriLauncher,
              );
          }
        },
      ),
    );
  }
}

/// Covers the `loading` / `initial` states with a Hero-safe cover
/// block at the top and a centered spinner below. Kept separate from
/// the success layout so it renders exactly one `ListingCoverImage`
/// that the push-transition `Hero` can target.
class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold({
    required this.listingId,
    required this.initialCoverImageUrl,
  });

  final String listingId;
  final String? initialCoverImageUrl;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        _pageHPadding,
        _pageHPadding,
        _pageHPadding,
        _pageHPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailsCover(listingId: listingId, imageUrl: initialCoverImageUrl),
          const SizedBox(height: 32),
          const LoadingView(),
        ],
      ),
    );
  }
}

/// Covers the `failure` state with the same Hero-safe cover block and
/// a retry surface. Keeping the cover mounted preserves the push
/// transition destination even when the cubit reports an error.
class _FailureScaffold extends StatelessWidget {
  const _FailureScaffold({
    required this.listingId,
    required this.initialCoverImageUrl,
    required this.message,
    required this.onRetry,
  });

  final String listingId;
  final String? initialCoverImageUrl;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        _pageHPadding,
        _pageHPadding,
        _pageHPadding,
        _pageHPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailsCover(listingId: listingId, imageUrl: initialCoverImageUrl),
          const SizedBox(height: 24),
          ErrorView(message: message, onRetry: onRetry),
        ],
      ),
    );
  }
}

/// Cover block reused across all states. Wraps [ListingCoverImage]
/// with the shared 16:9 aspect ratio, card-matching radius, and the
/// stable id-based Hero tag expected by the feed → details
/// transition.
class _DetailsCover extends StatelessWidget {
  const _DetailsCover({required this.listingId, required this.imageUrl});

  final String listingId;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(_coverRadius),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: ListingCoverImage(
          imageUrl: imageUrl,
          heroTag: listingCoverHeroTag(listingId),
        ),
      ),
    );
  }
}

/// Success-state body. Renders, top-down:
///   1. Summary card (title, price, compact meta row).
///   2. Cover image (shared Hero destination).
///   3. Specs card (make/model/year/mileage/type/city/region/posted).
///   4. Contact card (Telegram/WhatsApp + phone reveal/copy).
///   5. Optional Report footer card.
class _DetailsBody extends StatelessWidget {
  const _DetailsBody({
    required this.listing,
    required this.reportEmail,
    required this.uriLauncher,
  });

  final Listing listing;
  final String? reportEmail;
  final ListingDetailsUriLauncher? uriLauncher;

  @override
  Widget build(BuildContext context) {
    final hasReport = reportEmail != null && reportEmail!.isNotEmpty;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        _pageHPadding,
        _pageHPadding,
        _pageHPadding,
        _pageHPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SummaryCard(listing: listing),
          const SizedBox(height: _sectionGap),
          _DetailsCover(
            listingId: listing.id,
            imageUrl: listing.coverImageUrl,
          ),
          const SizedBox(height: _sectionGap),
          _SpecsCard(listing: listing),
          const SizedBox(height: _sectionGap),
          _ContactCard(listing: listing),
          if (hasReport) ...[
            const SizedBox(height: _sectionGap),
            _ReportFooterCard(
              listing: listing,
              recipientEmail: reportEmail!,
              launcher: uriLauncher ?? _launchExternalUri,
            ),
          ],
        ],
      ),
    );
  }
}

/// Hero / summary block shown above the cover image. Highlights the
/// title and price and exposes a compact meta row
/// (mileage · year · city) so the key facts are visible before the
/// user scrolls past the photo.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final metaParts = <String>[
      formatKm(listing.mileageKm),
      listing.year.toString(),
      listing.city,
    ];
    return DetailsSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            listing.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            formatEur(listing.priceEur),
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            metaParts.join(' · '),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            semanticsLabel:
                '${formatKm(listing.mileageKm)}, ${listing.year}, ${listing.city}',
          ),
          const SizedBox(height: 4),
          Text(
            formatMarketRegion(l10n, listing.marketRegion),
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Specs card replacing the old raw label/value table. Uses the same
/// l10n keys as before so existing l10n tests and translations keep
/// working, but renders each row with clearer hierarchy: muted label
/// on the left, stronger value on the right.
class _SpecsCard extends StatelessWidget {
  const _SpecsCard({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rows = <_SpecRow>[
      _SpecRow(label: l10n.listingFieldMake, value: listing.make),
      _SpecRow(label: l10n.listingFieldModel, value: listing.model),
      _SpecRow(label: l10n.listingFieldYear, value: listing.year.toString()),
      _SpecRow(
        label: l10n.listingFieldMileage,
        value: formatKm(listing.mileageKm),
      ),
      _SpecRow(
        label: l10n.listingFieldType,
        value: formatType(l10n, listing.type),
      ),
      _SpecRow(label: l10n.listingFieldCity, value: listing.city),
      _SpecRow(
        label: l10n.listingFieldRegion,
        value: formatMarketRegion(l10n, listing.marketRegion),
      ),
      _SpecRow(
        label: l10n.listingFieldPosted,
        value: formatDate(listing.createdAt),
      ),
    ];
    return DetailsSectionCard(
      title: l10n.listingDetailsSpecs,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const _SpecDivider(),
            rows[i],
          ],
        ],
      ),
    );
  }
}

class _SpecRow extends StatelessWidget {
  const _SpecRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 108,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecDivider extends StatelessWidget {
  const _SpecDivider();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.outlineVariant.withValues(
          alpha: 0.5,
        );
    return Divider(height: 1, thickness: 1, color: color);
  }
}

/// Contact card wrapping the existing `_ContactActions` state + logic
/// with the target marketplace layout:
///   * left column: message actions (Telegram, WhatsApp) — wrap when
///     space is tight.
///   * right column: phone reveal → phone call + copy once revealed.
/// Labels, icons, and launch URIs are preserved unchanged so the
/// contact-reveal widget tests keep passing.
class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final phone = listing.contactPhone;
    final tel = telUriString(phone);
    final telegram = listing.telegramUsername;
    final waDigits =
        listing.whatsappEnabled ? whatsappDigits(phone) : null;

    if (tel == null &&
        (telegram == null || telegram.isEmpty) &&
        waDigits == null) {
      return const SizedBox.shrink();
    }

    return DetailsSectionCard(
      title: l10n.contactSellerSection,
      child: _ContactActions(listing: listing),
    );
  }
}

/// Compact contact area on listing details.
///
/// Phone visibility: the raw phone number is hidden behind a local
/// "Show phone number" reveal step. This is a light, UI-only
/// friction — it does not gate any API call, does not require sign-in,
/// and does not prevent a motivated scraper from hitting the public
/// feed. Telegram and WhatsApp actions remain visible because their
/// labels do not include the phone number.
///
/// Once revealed, a small "Copy" action appears next to the phone so
/// the user can paste the number into any dialer or messenger without
/// manually selecting text. Copy uses the system clipboard only and
/// surfaces a localized confirmation snackbar; it never re-contacts
/// the server.
class _ContactActions extends StatefulWidget {
  const _ContactActions({required this.listing});

  final Listing listing;

  @override
  State<_ContactActions> createState() => _ContactActionsState();
}

class _ContactActionsState extends State<_ContactActions> {
  bool _phoneRevealed = false;

  Future<void> _launch(BuildContext context, Uri uri) async {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        _showError(context);
      }
    } catch (_) {
      if (context.mounted) _showError(context);
    }
  }

  void _showError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.contactActionFailed)),
    );
  }

  Future<void> _copyPhone(BuildContext context, String rawPhone) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await Clipboard.setData(ClipboardData(text: rawPhone.trim()));
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.contactPhoneCopied)),
      );
    } catch (_) {
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.contactActionFailed)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final listing = widget.listing;
    final phone = listing.contactPhone;
    final tel = telUriString(phone);
    final telegram = listing.telegramUsername;
    final waDigits =
        listing.whatsappEnabled ? whatsappDigits(phone) : null;

    final messageActions = <Widget>[
      if (telegram != null && telegram.isNotEmpty)
        OutlinedButton.icon(
          onPressed: () => _launch(
            context,
            Uri.parse('https://t.me/$telegram'),
          ),
          icon: const Icon(Icons.send),
          label: Text(l10n.contactTelegramLabel(telegram)),
        ),
      if (waDigits != null)
        OutlinedButton.icon(
          onPressed: () => _launch(
            context,
            Uri.parse('https://wa.me/$waDigits'),
          ),
          icon: const Icon(Icons.chat),
          label: Text(l10n.contactWhatsapp),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (messageActions.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: messageActions,
          ),
        if (messageActions.isNotEmpty && tel != null)
          const SizedBox(height: 12),
        if (tel != null)
          _phoneRevealed
              ? _RevealedPhoneRow(
                  phoneLabel: phone!.trim(),
                  onCall: () => _launch(context, Uri.parse(tel)),
                  onCopy: () => _copyPhone(context, phone),
                )
              : Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: () => setState(() => _phoneRevealed = true),
                    icon: const Icon(Icons.visibility_outlined),
                    label: Text(l10n.contactShowPhone),
                  ),
                ),
        if (tel != null) ...[
          const SizedBox(height: 10),
          Text(
            l10n.contactPublicNotice,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

/// Revealed-phone surface: primary "call" button showing the raw
/// phone number + a secondary "copy to clipboard" action. The call
/// button keeps the `Icons.call` + phone label contract expected by
/// `listing_details_contact_reveal_test`.
class _RevealedPhoneRow extends StatelessWidget {
  const _RevealedPhoneRow({
    required this.phoneLabel,
    required this.onCall,
    required this.onCopy,
  });

  final String phoneLabel;
  final VoidCallback onCall;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: onCall,
            icon: const Icon(Icons.call),
            label: Text(
              phoneLabel,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: onCopy,
          icon: const Icon(Icons.copy_outlined),
          label: Text(l10n.contactCopyPhone),
        ),
      ],
    );
  }
}

/// Subtle footer card hosting the "Report listing" action. Rendered
/// only when [Env.reportEmail] resolves to a non-empty value, so
/// Carzon never exposes a fake recipient. The surface is purely a
/// launcher: there is no backend write, no auth requirement, and no
/// reports table.
class _ReportFooterCard extends StatelessWidget {
  const _ReportFooterCard({
    required this.listing,
    required this.recipientEmail,
    required this.launcher,
  });

  final Listing listing;
  final String recipientEmail;
  final ListingDetailsUriLauncher launcher;

  Future<void> _onTap(BuildContext context) async {
    final uri = buildReportListingMailto(
      l10n: context.l10n,
      listing: listing,
      recipientEmail: recipientEmail,
    );
    try {
      final ok = await launcher(uri);
      if (!ok && context.mounted) _showError(context);
    } catch (_) {
      if (context.mounted) _showError(context);
    }
  }

  void _showError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.reportListingMailFailed)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return DetailsSectionCard(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.reportListingDescription,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _onTap(context),
              icon: const Icon(Icons.flag_outlined),
              label: Text(l10n.reportListing),
            ),
          ),
        ],
      ),
    );
  }
}
