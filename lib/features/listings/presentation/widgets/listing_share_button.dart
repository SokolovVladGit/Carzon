import 'package:flutter/material.dart';

import '../../../../core/config/env.dart';
import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../shared/ui/carzon_icons.dart';
import '../../domain/entities/listing.dart';
import '../utils/listing_share_launcher.dart';
import '../utils/listing_share_text.dart';
import '../utils/listing_share_url.dart';

typedef ListingShareUrlBuilder = String? Function(Listing listing);

/// Hero-style share control for a loaded listing details screen.
class ListingShareButton extends StatelessWidget {
  const ListingShareButton({
    super.key,
    required this.listing,
    this.shareLauncher,
    this.shareUrlBuilder,
  });

  final Listing listing;
  final ListingShareLauncher? shareLauncher;
  final ListingShareUrlBuilder? shareUrlBuilder;

  /// Central capability check used by the hero before it allocates chrome for
  /// this action. The button repeats the guard for safe standalone use.
  static bool get isAvailable => Env.listingSharingEnabled;

  Future<void> _handleTap(BuildContext context) async {
    final l10n = context.l10n;
    final shareUrl =
        shareUrlBuilder?.call(listing) ??
        buildListingShareUrl(Env.listingShareBaseUrl, listing.id);
    final text = buildListingShareText(l10n, listing, shareUrl: shareUrl);

    try {
      await (shareLauncher ?? launchListingShare)(text);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.listingShareFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!isAvailable && shareUrlBuilder == null) {
      return const SizedBox.shrink();
    }

    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final iconColor = scheme.onSurface.withValues(alpha: 0.92);

    return Semantics(
      button: true,
      label: l10n.listingShareAction,
      child: IconButton(
        tooltip: l10n.listingShareAction,
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(foregroundColor: iconColor),
        onPressed: () => _handleTap(context),
        icon: const Icon(CarzonIcons.share, size: 20),
      ),
    );
  }
}
