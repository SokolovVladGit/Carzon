import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/ui/carzon_icons.dart';
import '../../domain/entities/compare_item.dart';
import '../../domain/entities/compare_listing_snapshot.dart';
import '../cubit/compare_state.dart';

/// Floating capsule that surfaces the local compare set and opens `/compare`.
class CompareFloatingTray extends StatelessWidget {
  const CompareFloatingTray({
    super.key,
    required this.items,
    required this.onOpenCompare,
    this.solidThumbnails = false,
    this.showDropShadow = true,
  });

  final List<CompareItem> items;
  final VoidCallback onOpenCompare;

  /// Audit: flat chips instead of network images.
  final bool solidThumbnails;

  /// Host wraps tray with dock shield and supplies shadow.
  final bool showDropShadow;

  static const double horizontalMargin = 18;
  static const double height = 68;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final count = items.length;
    final isDark = theme.brightness == Brightness.dark;

    final title = count == 1
        ? l10n.compareTrayOneVehicle
        : l10n.compareTrayVehicleCount(count);
    final hint = count == 1 ? l10n.compareTrayAddOneMore : l10n.compareTrayOpen;

    final darkDecoration = isDark
        ? AppTheme.editorialDarkSectionCard(scheme, borderRadius: 28)
        : null;
    final surface = isDark ? Colors.transparent : Colors.white;
    final borderColor = scheme.outlineVariant.withValues(
      alpha: isDark ? 0.35 : 0.22,
    );
    final shadowColor = isDark
        ? scheme.primary.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.12);

    final capsuleChild = InkWell(
      onTap: onOpenCompare,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
        child: Row(
          children: [
            _CompareTrayThumbnailStack(
              items: items,
              solidThumbnails: solidThumbnails,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: scheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CarzonIcons.chevronRight,
              size: 20,
              color: scheme.primary.withValues(alpha: 0.9),
            ),
          ],
        ),
      ),
    );

    final capsule = darkDecoration != null
        ? Material(
            color: Colors.transparent,
            elevation: 0,
            shadowColor: Colors.transparent,
            clipBehavior: Clip.antiAlias,
            child: DecoratedBox(
              decoration: darkDecoration,
              child: capsuleChild,
            ),
          )
        : Material(
            color: surface,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
              side: BorderSide(color: borderColor),
            ),
            clipBehavior: Clip.antiAlias,
            child: capsuleChild,
          );

    return Semantics(
      button: true,
      label: '$title. $hint',
      child: showDropShadow
          ? DecoratedBox(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: shadowColor,
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: capsule,
            )
          : capsule,
    );
  }
}

class _CompareTrayThumbnailStack extends StatelessWidget {
  const _CompareTrayThumbnailStack({
    required this.items,
    required this.solidThumbnails,
  });

  final List<CompareItem> items;
  final bool solidThumbnails;

  static const double thumbSize = 44;
  static const double overlap = 14;

  @override
  Widget build(BuildContext context) {
    final visible = items.take(CompareState.maxItems).toList();
    final showCount = visible.length;
    final overflow = items.length > CompareState.maxItems
        ? items.length - CompareState.maxItems
        : 0;

    return SizedBox(
      width:
          thumbSize +
          (showCount - 1) * (thumbSize - overlap) +
          (overflow > 0 ? 8 : 0),
      height: thumbSize,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          for (var i = 0; i < showCount; i++)
            Positioned(
              left: i * (thumbSize - overlap),
              child: _Thumb(
                snapshot: visible[i].snapshot,
                solidThumbnail: solidThumbnails,
                showOverflowBadge: overflow > 0 && i == showCount - 1,
                overflowCount: overflow,
              ),
            ),
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({
    required this.snapshot,
    required this.solidThumbnail,
    this.showOverflowBadge = false,
    this.overflowCount = 0,
  });

  final CompareListingSnapshot snapshot;
  final bool solidThumbnail;
  final bool showOverflowBadge;
  final int overflowCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: _CompareTrayThumbnailStack.thumbSize,
      height: _CompareTrayThumbnailStack.thumbSize,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: scheme.surface, width: 1.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              clipBehavior: Clip.hardEdge,
              child: solidThumbnail
                  ? _CompareTraySolidThumb(listingId: snapshot.listingId)
                  : _CompareTrayCoverImage(imageUrl: snapshot.coverImageUrl),
            ),
          ),
          if (showOverflowBadge && overflowCount > 0)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: scheme.surface, width: 1.2),
                ),
                child: Text(
                  '+$overflowCount',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onPrimary,
                    fontWeight: FontWeight.w700,
                    height: 1,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Flat audit chip — no image decode.
class _CompareTraySolidThumb extends StatelessWidget {
  const _CompareTraySolidThumb({required this.listingId});

  final String listingId;

  @override
  Widget build(BuildContext context) {
    final hue = listingId.hashCode.abs() % 360;
    return ColoredBox(
      color: HSLColor.fromAHSL(1, hue.toDouble(), 0.35, 0.55).toColor(),
      child: const SizedBox.expand(),
    );
  }
}

/// Small fixed-size tray cover — avoids unconstrained listing cover sizing.
class _CompareTrayCoverImage extends StatelessWidget {
  const _CompareTrayCoverImage({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final url = imageUrl?.trim();

    if (url == null || url.isEmpty) {
      return ColoredBox(
        color: scheme.surfaceContainerHighest,
        child: Icon(
          Icons.directions_car_outlined,
          size: 22,
          color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
      );
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      width: _CompareTrayThumbnailStack.thumbSize,
      height: _CompareTrayThumbnailStack.thumbSize,
      gaplessPlayback: true,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) return child;
        return ColoredBox(color: scheme.surfaceContainerHighest);
      },
      errorBuilder: (_, _, _) => ColoredBox(
        color: scheme.surfaceContainerHighest,
        child: Icon(
          Icons.broken_image_outlined,
          size: 20,
          color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
