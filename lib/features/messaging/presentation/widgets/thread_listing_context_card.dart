import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/l10n/app_localizations_x.dart';
import '../../../listings/domain/entities/listing_currency.dart';
import '../../../listings/presentation/utils/listing_formatters.dart';
import '../../domain/entities/conversation.dart';
import '../utils/thread_listing_copy.dart';

/// Compact listing summary at the top of a conversation thread.
class ThreadListingContextCard extends StatelessWidget {
  const ThreadListingContextCard({
    super.key,
    required this.conversation,
    required this.listingIdShortFallback,
  });

  final Conversation conversation;
  final String listingIdShortFallback;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final primary = threadListingPrimaryLine(
      conversation,
      listingIdShortFallback,
    );
    final city = conversation.listingCity?.trim();
    final cover = conversation.listingCoverImageUrl?.trim();
    final priceLine = _priceLine(conversation);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Material(
        color: cs.surfaceContainerLow.withValues(alpha: 0.94),
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.35)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push(
            AppRoutes.listingDetailsPath(conversation.listingId),
            extra: ListingDetailsExtra(
              coverImageUrl: cover != null && cover.isNotEmpty ? cover : null,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _Thumbnail(url: cover),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        primary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                          color: cs.onSurface,
                        ),
                      ),
                      if (priceLine != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          priceLine,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: cs.primary,
                            height: 1.2,
                          ),
                        ),
                      ],
                      if (city != null && city.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          city,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            height: 1.2,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        l10n.messagingThreadViewListingHint,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.primary.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _priceLine(Conversation c) {
    final amount = c.listingPriceAmount;
    if (amount == null) return null;
    final currency = listingCurrencyFromDbString(c.listingPriceCurrencyDb);
    return formatListingPrice(amount, currency);
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const size = 52.0;
    final borderRadius = BorderRadius.circular(12);
    if (url == null || url!.isEmpty) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: ColoredBox(
          color: cs.surfaceContainerHighest,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(
              Icons.directions_car_outlined,
              color: cs.onSurfaceVariant.withValues(alpha: 0.45),
            ),
          ),
        ),
      );
    }
    return ClipRRect(
      borderRadius: borderRadius,
      child: Image.network(
        url!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => ColoredBox(
          color: cs.surfaceContainerHighest,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(
              Icons.broken_image_outlined,
              color: cs.onSurfaceVariant.withValues(alpha: 0.45),
            ),
          ),
        ),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return SizedBox(
            width: size,
            height: size,
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: cs.primary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
