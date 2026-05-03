import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/ui/carzon_icons.dart';
import '../../domain/constants/listing_gallery_limits.dart';
import '../models/create_listing_photo_draft.dart';

/// Hero + thumbnails for the create-listing staging gallery (≤ [kMaxListingPhotos]).
///
/// Index 0 is rendered in the hero; all photos appear as removable thumbnails below.
/// Add actions are routed through [onAddPhoto] until the limit is reached.
class CreateListingMediaSection extends StatelessWidget {
  const CreateListingMediaSection({
    super.key,
    required this.photos,
    required this.pickingImage,
    required this.disabled,
    required this.onAddPhoto,
    required this.onRemovePhotoAt,
  });

  /// Staging blobs in display order — first element is cover.
  final List<CreateListingPhotoDraft> photos;

  final bool pickingImage;
  final bool disabled;
  final VoidCallback onAddPhoto;
  final void Function(int index) onRemovePhotoAt;

  static const phase3TestKey = ValueKey('create_listing_media_section');

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
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Material(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: (heroBytes == null && canMutate) ? onAddPhoto : null,
              child: heroBytes != null
                  ? Image.memory(
                      heroBytes,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    )
                  : Center(
                      child: pickingImage
                          ? SizedBox.square(
                              dimension: 28,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.primary,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  CarzonIcons.addPhoto,
                                  size: 40,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(height: 12),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                  ),
                                  child: Text(
                                    l10n.createListingMediaHeroEmptyHint,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        _ThumbnailStrip(
          photos: photos,
          disabled: disabled,
          pickingImage: pickingImage,
          l10n: l10n,
          onRemovePhotoAt: onRemovePhotoAt,
          onAddPhoto: onAddPhoto,
        ),
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
    final addLabel = photos.isEmpty
        ? l10n.createListingAddPhoto
        : l10n.createListingAddMorePhotos;

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
            borderRadius: BorderRadius.circular(12),
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
                        color: theme.colorScheme.surface.withValues(alpha: .9),
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
                            fontWeight: FontWeight.w600,
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
            borderRadius: BorderRadius.circular(12),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: .45),
                  width: 1.25,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
                color: theme.colorScheme.surfaceContainerLow,
              ),
              child: busy
                  ? Center(
                      child: SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 26,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          label,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurfaceVariant,
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
