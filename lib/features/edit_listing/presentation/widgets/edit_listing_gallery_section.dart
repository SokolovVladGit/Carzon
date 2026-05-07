import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/ui/carzon_icons.dart';
import '../../../create_listing/domain/constants/listing_gallery_limits.dart';
import '../models/edit_listing_gallery_slot.dart';

/// Hero + thumbnails for edit-listing with mixed remote rows and local drafts.
///
/// Index `0` is cover. When [galleryMutationsEnabled] is false (gallery RPC load
/// failed), add/remove/disable except viewing [readOnlyHeroUrl] fallback.
class EditListingGallerySection extends StatelessWidget {
  const EditListingGallerySection({
    super.key,
    required this.slots,
    required this.pickingImage,
    required this.submitting,
    required this.galleryMutationsEnabled,
    required this.readOnlyHeroUrl,
    required this.onAddPhoto,
    required this.onRemovePhotoAt,
  });

  /// Staging slots in display order.
  final List<EditListingGallerySlot> slots;

  final bool pickingImage;
  final bool submitting;

  /// When false, uploads/removals are disabled (failed `listing_images` load).
  final bool galleryMutationsEnabled;

  /// Shown read-only when [slots] is empty but a cover fallback exists during
  /// a failed gallery fetch.
  final String? readOnlyHeroUrl;

  final VoidCallback onAddPhoto;
  final void Function(int index) onRemovePhotoAt;

  static const widgetTestKey = ValueKey('edit_listing_media_section');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    final canMutateGallery =
        galleryMutationsEnabled && !submitting && !pickingImage;

    Widget? heroChild;
    if (slots.isNotEmpty) {
      final first = slots.first;
      heroChild = _heroForSlot(theme, first);
    } else if (readOnlyHeroUrl != null && readOnlyHeroUrl!.trim().isNotEmpty) {
      heroChild = _NetworkThumb(url: readOnlyHeroUrl!.trim(), theme: theme);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      key: widgetTestKey,
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
        if (!galleryMutationsEnabled) ...[
          const SizedBox(height: 8),
          Text(
            l10n.editListingGalleryReadOnlyHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 12),
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Material(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap:
                  (heroChild == null &&
                      canMutateGallery &&
                      galleryMutationsEnabled)
                  ? onAddPhoto
                  : null,
              child: heroChild != null
                  ? SizedBox.expand(child: heroChild)
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
          slots: slots,
          canMutate: canMutateGallery,
          mutationsEnabled: galleryMutationsEnabled,
          pickingImage: pickingImage,
          l10n: l10n,
          theme: theme,
          onRemovePhotoAt: onRemovePhotoAt,
          onAddPhoto: onAddPhoto,
        ),
      ],
    );
  }

  Widget _heroForSlot(ThemeData theme, EditListingGallerySlot slot) {
    return switch (slot) {
      EditListingGalleryRemoteSlot(:final publicUrl) => _NetworkThumb(
        url: publicUrl,
        theme: theme,
      ),
      EditListingGalleryLocalSlot(:final upload) => Image.memory(
        upload.bytes,
        fit: BoxFit.cover,
        width: double.infinity,
      ),
    };
  }
}

class _ThumbnailStrip extends StatelessWidget {
  const _ThumbnailStrip({
    required this.slots,
    required this.canMutate,
    required this.mutationsEnabled,
    required this.pickingImage,
    required this.l10n,
    required this.theme,
    required this.onRemovePhotoAt,
    required this.onAddPhoto,
  });

  final List<EditListingGallerySlot> slots;
  final bool canMutate;
  final bool mutationsEnabled;
  final bool pickingImage;
  final AppLocalizations l10n;
  final ThemeData theme;
  final void Function(int index) onRemovePhotoAt;
  final VoidCallback onAddPhoto;

  @override
  Widget build(BuildContext context) {
    final canMutatePhotos = mutationsEnabled && canMutate && !pickingImage;
    final canAddMore = slots.length < kMaxListingPhotos;
    final addLabel = slots.isEmpty
        ? l10n.createListingAddPhoto
        : l10n.createListingAddMorePhotos;

    return SizedBox(
      height: 96,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (var i = 0; i < slots.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            _SlotThumb(
              slot: slots[i],
              isCover: i == 0,
              tooltipRemove: l10n.createListingRemovePhoto,
              coverBadge: l10n.createListingCoverBadge,
              onRemove: () => onRemovePhotoAt(i),
              enabledControls: canMutatePhotos,
              theme: theme,
            ),
          ],
          const SizedBox(width: 10),
          SizedBox(
            width: 128,
            child: _AddTile(
              enabled: canMutatePhotos && mutationsEnabled && canAddMore,
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

class _SlotThumb extends StatelessWidget {
  const _SlotThumb({
    required this.slot,
    required this.isCover,
    required this.tooltipRemove,
    required this.coverBadge,
    required this.onRemove,
    required this.enabledControls,
    required this.theme,
  });

  final EditListingGallerySlot slot;
  final bool isCover;
  final String tooltipRemove;
  final String coverBadge;
  final VoidCallback onRemove;
  final bool enabledControls;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    Widget image;
    final content = switch (slot) {
      EditListingGalleryRemoteSlot(:final publicUrl) => _NetworkThumb(
        url: publicUrl,
        theme: theme,
      ),
      EditListingGalleryLocalSlot(:final upload) => Image.memory(
        upload.bytes,
        fit: BoxFit.cover,
        gaplessPlayback: true,
      ),
    };

    image = SizedBox.expand(child: content);

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
                image,
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

class _NetworkThumb extends StatelessWidget {
  const _NetworkThumb({required this.url, required this.theme});

  final String url;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => ColoredBox(
        color: theme.colorScheme.surfaceContainerHighest,
        child: Center(
          child: Icon(
            CarzonIcons.brokenImage,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return ColoredBox(
          color: theme.colorScheme.surfaceContainerHighest,
          child: Center(
            child: SizedBox.square(
              dimension: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        );
      },
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
          color: theme.colorScheme.surface.withValues(alpha: 0),
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
