import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/ui/carzon_icons.dart';
import '../../domain/constants/listing_gallery_limits.dart';
import '../models/create_listing_photo_draft.dart';

/// Hero + optional thumbnails for the create-listing staging gallery (≤ [kMaxListingPhotos]).
///
/// Index 0 is rendered in the hero; when [photos] is non-empty, thumbnails + add tile appear below.
/// When empty, the hero alone is the add-photo surface — no duplicate small add tile.
class CreateListingMediaSection extends StatelessWidget {
  const CreateListingMediaSection({
    super.key,
    required this.photos,
    required this.pickingImage,
    required this.disabled,
    required this.onAddPhoto,
    required this.onRemovePhotoAt,
    this.showHeading = true,
  });

  /// Staging blobs in display order — first element is cover.
  final List<CreateListingPhotoDraft> photos;

  final bool pickingImage;
  final bool disabled;
  final VoidCallback onAddPhoto;
  final void Function(int index) onRemovePhotoAt;

  /// When false, hides the title + subtitle rows (parent section supplies hierarchy).
  final bool showHeading;

  static const phase3TestKey = ValueKey('create_listing_media_section');

  static const double _heroRadius = 24;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final canMutate = !disabled && !pickingImage;

    final heroBytes = photos.isNotEmpty ? photos.first.bytes : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      key: phase3TestKey,
      children: [
        if (showHeading) ...[
          Text(
            l10n.createListingMediaTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.createListingMediaSubtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
        ],
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(_heroRadius),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: (heroBytes == null && canMutate) ? onAddPhoto : null,
              borderRadius: BorderRadius.circular(_heroRadius),
              splashColor: theme.colorScheme.onSurface.withValues(alpha: 0.045),
              highlightColor: theme.colorScheme.onSurface.withValues(
                alpha: 0.022,
              ),
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_heroRadius),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: heroBytes != null ? 0.24 : 0.38,
                    ),
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
                  gradient: heroBytes == null
                      ? LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            theme.colorScheme.surface,
                            Color.alphaBlend(
                              theme.colorScheme.outlineVariant.withValues(
                                alpha: 0.035,
                              ),
                              theme.colorScheme.surface,
                            ),
                            theme.colorScheme.surfaceContainerLow,
                          ],
                          stops: const [0.0, 0.45, 1.0],
                        )
                      : null,
                  color: heroBytes != null
                      ? theme.colorScheme.surfaceContainerLow
                      : null,
                ),
                child: heroBytes != null
                    ? SizedBox.expand(
                        child: Image.memory(heroBytes, fit: BoxFit.cover),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          if (pickingImage) {
                            return Center(
                              child: SizedBox.square(
                                dimension: 30,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            );
                          }
                          final cs = theme.colorScheme;
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            child: Column(
                              children: [
                                Expanded(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.center,
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth: constraints.maxWidth - 20,
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          DecoratedBox(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Color.alphaBlend(
                                                cs.outlineVariant.withValues(
                                                  alpha: 0.075,
                                                ),
                                                cs.surface,
                                              ),
                                              border: Border.all(
                                                color: cs.outlineVariant
                                                    .withValues(alpha: 0.34),
                                              ),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(11),
                                              child: Icon(
                                                CarzonIcons.addPhoto,
                                                size: 28,
                                                color: cs.onSurfaceVariant
                                                    .withValues(alpha: 0.82),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            l10n.createListingHeroEmptyTitle,
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: -0.26,
                                                  height: 1.18,
                                                  color: cs.onSurface
                                                      .withValues(alpha: 0.94),
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            l10n.createListingHeroEmptyDetail,
                                            textAlign: TextAlign.center,
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: cs.onSurfaceVariant
                                                      .withValues(alpha: 0.88),
                                                  height: 1.32,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),
          ),
        ),
        if (photos.isNotEmpty) ...[
          const SizedBox(height: 18),
          _ThumbnailStrip(
            photos: photos,
            disabled: disabled,
            pickingImage: pickingImage,
            l10n: l10n,
            onRemovePhotoAt: onRemovePhotoAt,
            onAddPhoto: onAddPhoto,
          ),
        ],
      ],
    );
  }
}

class _ThumbnailStrip extends StatelessWidget {
  const _ThumbnailStrip({
    required this.photos,
    required this.disabled,
    required this.pickingImage,
    required this.l10n,
    required this.onRemovePhotoAt,
    required this.onAddPhoto,
  });

  final List<CreateListingPhotoDraft> photos;
  final bool disabled;
  final bool pickingImage;
  final AppLocalizations l10n;
  final void Function(int index) onRemovePhotoAt;
  final VoidCallback onAddPhoto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canMutate = !disabled && !pickingImage;

    final canAddMore = photos.length < kMaxListingPhotos;
    final addLabel = l10n.createListingAddMorePhotos;

    return SizedBox(
      height: 96,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (var i = 0; i < photos.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            _PhotoThumb(
              index: i,
              bytes: photos[i].bytes,
              isCover: i == 0,
              tooltipRemove: l10n.createListingRemovePhoto,
              coverBadge: l10n.createListingCoverBadge,
              onRemove: () => onRemovePhotoAt(i),
              enabledControls: canMutate,
              theme: theme,
            ),
          ],
          const SizedBox(width: 10),
          SizedBox(
            width: 128,
            child: _AddTile(
              enabled: canMutate && canAddMore,
              label: addLabel,
              busy: pickingImage,
              theme: theme,
              onTap: onAddPhoto,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  const _PhotoThumb({
    required this.index,
    required this.bytes,
    required this.isCover,
    required this.tooltipRemove,
    required this.coverBadge,
    required this.onRemove,
    required this.enabledControls,
    required this.theme,
  });

  final int index;
  final Uint8List bytes;
  final bool isCover;
  final String tooltipRemove;
  final String coverBadge;
  final VoidCallback onRemove;
  final bool enabledControls;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltipRemove,
      child: SizedBox(
        width: 128,
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true),
                if (isCover)
                  Positioned(
                    left: 6,
                    top: 6,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer.withValues(
                          alpha: 0.92,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        child: Text(
                          coverBadge,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: Material(
                    type: MaterialType.transparency,
                    child: IconButton(
                      tooltip: tooltipRemove,
                      constraints: const BoxConstraints(
                        minWidth: 34,
                        minHeight: 34,
                      ),
                      padding: EdgeInsets.zero,
                      style: IconButton.styleFrom(
                        backgroundColor: theme.colorScheme.surface.withValues(
                          alpha: .88,
                        ),
                      ),
                      onPressed: enabledControls ? onRemove : null,
                      icon: Icon(CarzonIcons.close, size: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({
    required this.enabled,
    required this.label,
    required this.busy,
    required this.theme,
    required this.onTap,
  });

  final bool enabled;
  final String label;
  final bool busy;
  final ThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled && !busy ? onTap : null,
            borderRadius: BorderRadius.circular(14),
            splashColor: theme.colorScheme.onSurface.withValues(alpha: 0.042),
            highlightColor: theme.colorScheme.onSurface.withValues(alpha: 0.02),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: enabled ? 0.38 : 0.22,
                  ),
                  width: 1,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
                color: Color.alphaBlend(
                  theme.colorScheme.outlineVariant.withValues(
                    alpha: enabled ? 0.042 : 0.025,
                  ),
                  theme.colorScheme.surface,
                ),
              ),
              child: busy
                  ? Center(
                      child: SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 26,
                          color: theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.82,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          label,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.88),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
