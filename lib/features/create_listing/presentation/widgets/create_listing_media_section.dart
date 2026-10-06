import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../shared/ui/carzon_icons.dart';
import 'create_listing_compose_layout.dart';
import '../../domain/constants/listing_gallery_limits.dart';
import '../models/create_listing_photo_draft.dart';

/// Nine equal slots. Index 0 is the cover. Max [kMaxListingPhotos].
class CreateListingMediaSection extends StatelessWidget {
  const CreateListingMediaSection({
    super.key,
    required this.photos,
    required this.pickingImage,
    required this.disabled,
    required this.onAddPhoto,
    required this.onRemovePhotoAt,
  });

  final List<CreateListingPhotoDraft> photos;
  final bool pickingImage;
  final bool disabled;
  final VoidCallback onAddPhoto;
  final void Function(int index) onRemovePhotoAt;

  static const phase3TestKey = ValueKey('create_listing_media_section');
  static const coverKey = ValueKey('create_listing_photo_cover');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final canMutate = !disabled && !pickingImage;
    final canAdd = canMutate && photos.length < kMaxListingPhotos;

    const gap = 8.0;
    return LayoutBuilder(
      key: phase3TestKey,
      builder: (context, constraints) {
        final tile = (constraints.maxWidth - gap * 2) / 3;

        Widget cell(int index) {
          final filled = index < photos.length;
          final child = filled
              ? _PhotoTile(
                  key: index == 0
                      ? coverKey
                      : ValueKey('create_listing_photo_$index'),
                  index: index,
                  bytes: photos[index].bytes,
                  isCover: index == 0,
                  coverBadge: l10n.createListingCoverBadge,
                  tooltipRemove: l10n.createListingRemovePhoto,
                  enabled: canMutate,
                  onRemove: () => onRemovePhotoAt(index),
                  theme: theme,
                )
              : _EmptySlot(
                  primary: index == photos.length && canAdd,
                  showPlaceholderKey: index != photos.length,
                  label: l10n.createListingAddPhoto,
                  busy: pickingImage && index == photos.length,
                  enabled: canAdd,
                  onTap: onAddPhoto,
                  theme: theme,
                );
          return SizedBox.expand(child: child);
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var row = 0; row < 3; row++) ...[
              if (row > 0) const SizedBox(height: gap),
              SizedBox(
                height: tile,
                child: Row(
                  children: [
                    for (var col = 0; col < 3; col++) ...[
                      if (col > 0) const SizedBox(width: gap),
                      Expanded(child: cell(row * 3 + col)),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    super.key,
    required this.index,
    required this.bytes,
    required this.isCover,
    required this.coverBadge,
    required this.tooltipRemove,
    required this.enabled,
    required this.onRemove,
    required this.theme,
  });

  final int index;
  final Uint8List bytes;
  final bool isCover;
  final String coverBadge;
  final String tooltipRemove;
  final bool enabled;
  final VoidCallback onRemove;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    const hit = 36.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true),
          if (isCover)
            Positioned(
              left: 6,
              bottom: 6,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: kCreateListingActiveFill.withValues(alpha: 0.88),
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
                      color: kCreateListingActiveForeground,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                      height: 1.1,
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
                key: ValueKey('create_listing_remove_photo_$index'),
                tooltip: tooltipRemove,
                constraints: BoxConstraints(minWidth: hit, minHeight: hit),
                padding: EdgeInsets.zero,
                style: IconButton.styleFrom(
                  backgroundColor: cs.surface.withValues(alpha: 0.92),
                  shape: const CircleBorder(),
                ),
                onPressed: enabled ? onRemove : null,
                icon: Icon(
                  CarzonIcons.close,
                  size: 16,
                  color: cs.onSurface.withValues(alpha: 0.78),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySlot extends StatelessWidget {
  const _EmptySlot({
    required this.primary,
    required this.showPlaceholderKey,
    required this.label,
    required this.busy,
    required this.enabled,
    required this.onTap,
    required this.theme,
  });

  final bool primary;
  final bool showPlaceholderKey;
  final String label;
  final bool busy;
  final bool enabled;
  final VoidCallback onTap;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    final light = theme.brightness == Brightness.light;
    final iconColor = cs.onSurface.withValues(
      alpha: primary ? (light ? 0.55 : 0.7) : (light ? 0.32 : 0.42),
    );
    final sheen = light ? 0.22 : 0.07;
    final sheenTint = light ? Colors.white : const Color(0xFFF3EBE3);

    const radius = 16.0;
    final shape = BorderRadius.circular(radius);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: primary
            ? const ValueKey('create_listing_add_photo')
            : (showPlaceholderKey
                  ? const ValueKey('create_listing_photo_placeholder')
                  : null),
        onTap: enabled && !busy ? onTap : null,
        borderRadius: shape,
        child: Ink(
          decoration: createListingCeramicPlaceholderDecoration(
            theme,
            prominent: primary,
            radius: radius,
          ),
          child: busy
              ? Center(
                  child: SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: cs.primary,
                    ),
                  ),
                )
              : Stack(
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: shape,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: const Alignment(0.2, 0.85),
                            colors: [
                              sheenTint.withValues(alpha: sheen),
                              sheenTint.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CarzonIcons.addPhoto,
                            size: primary ? 22 : 18,
                            color: iconColor,
                          ),
                          if (primary) ...[
                            const SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: Text(
                                label,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: iconColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                  height: 1.1,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
