import 'package:flutter/material.dart';
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
import '../widgets/listing_cover_image.dart';

/// Minimal launcher seam local to this page — mirrors the
/// `EditListingImagePicker` typedef on the edit-listing page so widget
/// tests can intercept `launchUrl` without owning a global abstraction.
typedef ListingDetailsUriLauncher = Future<bool> Function(Uri uri);

Future<bool> _launchExternalUri(Uri uri) =>
    launchUrl(uri, mode: LaunchMode.externalApplication);

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
      // The cover Hero must be mounted on the first frame of the push
      // transition, otherwise Flutter's HeroController can't find a
      // matching destination tag and the feed → details flight is
      // silently skipped. Keeping the cover outside the state switch
      // guarantees the Hero destination exists in every state.
      body: BlocBuilder<ListingDetailsCubit, ListingDetailsState>(
        builder: (context, state) {
          // Once the cubit resolves, the loaded listing is the single
          // source of truth — even if its own `coverImageUrl` is null
          // we must not keep showing the initial URL, otherwise the
          // page would display a stale photo for a listing that no
          // longer has one. Before the listing loads, fall back to
          // the URL passed through route `extra` so the Hero flight
          // animates the real tapped photo. Deep-linked routes arrive
          // with neither, so the Hero destination falls back to the
          // placeholder until the load completes.
          final coverUrl = state.listing != null
              ? state.listing!.coverImageUrl
              : initialCoverImageUrl;
          return SingleChildScrollView(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _DetailsCover(listingId: id, imageUrl: coverUrl),
                ),
                switch (state.status) {
                  ListingDetailsStatus.initial ||
                  ListingDetailsStatus.loading =>
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: LoadingView(),
                    ),
                  ListingDetailsStatus.failure => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: ErrorView(
                        message: state.errorMessage ??
                            l10n.listingDetailsLoadFailed,
                        onRetry: () =>
                            context.read<ListingDetailsCubit>().load(id),
                      ),
                    ),
                  ListingDetailsStatus.success => _DetailsBody(
                      listing: state.listing!,
                      reportEmail: reportEmail,
                      uriLauncher: uriLauncher,
                    ),
                },
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Top-of-page cover block on [ListingDetailsPage]. Always mounted so
/// the feed → details Hero flight has a destination on the first frame
/// of the push transition.
///
/// During `initial`/`loading` the image URL is still unknown and the
/// block renders the same placeholder used by [ListingCoverImage].
/// Once the cubit resolves, the URL is swapped in place — the Hero
/// tag does not change, so there is exactly one destination `Hero`
/// mounted for `listing-cover-<id>` at any time.
class _DetailsCover extends StatelessWidget {
  const _DetailsCover({required this.listingId, required this.imageUrl});

  final String listingId;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
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
    final theme = Theme.of(context);
    final l10n = context.l10n;
    // Cover is rendered by _DetailsCover one level up, so this body is
    // just the textual + contact content below the photo. Padding
    // mirrors the previous layout (16 horizontal, 16 gap under the
    // cover) so visual spacing is unchanged.
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(listing.title, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            formatEur(listing.priceEur),
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          _DetailRow(label: l10n.listingFieldMake, value: listing.make),
          _DetailRow(label: l10n.listingFieldModel, value: listing.model),
          _DetailRow(label: l10n.listingFieldYear, value: listing.year.toString()),
          _DetailRow(
            label: l10n.listingFieldMileage,
            value: formatKm(listing.mileageKm),
          ),
          _DetailRow(
            label: l10n.listingFieldType,
            value: formatType(l10n, listing.type),
          ),
          _DetailRow(label: l10n.listingFieldCity, value: listing.city),
          _DetailRow(
            label: l10n.listingFieldRegion,
            value: formatMarketRegion(l10n, listing.marketRegion),
          ),
          _DetailRow(
            label: l10n.listingFieldPosted,
            value: formatDate(listing.createdAt),
          ),
          const SizedBox(height: 24),
          _ContactActions(listing: listing),
          if (reportEmail != null && reportEmail!.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 8),
            _ReportListingAction(
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

/// Small "Report listing" surface shown below the contact actions.
///
/// Rendered only when [Env.reportEmail] resolves to a non-empty value,
/// so Carzon never exposes a fake recipient. The surface is purely a
/// launcher: there is no backend write, no auth requirement, and no
/// reports table. A motivated reporter can still use the mail app
/// directly — this is just a discoverability improvement.
class _ReportListingAction extends StatelessWidget {
  const _ReportListingAction({
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.reportListingDescription,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => _onTap(context),
            icon: const Icon(Icons.flag_outlined),
            label: Text(l10n.reportListing),
          ),
        ),
      ],
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

    if (tel == null && (telegram == null || telegram.isEmpty) && waDigits == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.contactSellerSection, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (tel != null)
          _phoneRevealed
              ? FilledButton.icon(
                  onPressed: () => _launch(context, Uri.parse(tel)),
                  icon: const Icon(Icons.call),
                  label: Text(phone!.trim()),
                )
              : FilledButton.icon(
                  onPressed: () => setState(() => _phoneRevealed = true),
                  icon: const Icon(Icons.visibility_outlined),
                  label: Text(l10n.contactShowPhone),
                ),
        if (tel != null) ...[
          const SizedBox(height: 6),
          Text(
            l10n.contactPublicNotice,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (telegram != null && telegram.isNotEmpty) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _launch(
              context,
              Uri.parse('https://t.me/$telegram'),
            ),
            icon: const Icon(Icons.send),
            label: Text(l10n.contactTelegramLabel(telegram)),
          ),
        ],
        if (waDigits != null) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _launch(
              context,
              Uri.parse('https://wa.me/$waDigits'),
            ),
            icon: const Icon(Icons.chat),
            label: Text(l10n.contactWhatsapp),
          ),
        ],
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: theme.textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}

