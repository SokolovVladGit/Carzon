import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../shared/ui/carzon_icons.dart';
import 'create_listing_compose_layout.dart';
import '../../domain/constants/listing_gallery_limits.dart';
import '../models/create_listing_photo_draft.dart';

/// Cover-first gallery. Index 0 is the large tile. Max [kMaxListingPhotos].
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

    return LayoutBuilder(
      key: phase3TestKey,
      builder: (context, constraints) {
        final gap = 6.0;
        final width = constraints.maxWidth;
        final mainW = (width - gap) * 0.58;
        final sideW = width - gap - mainW;
        final mainH = mainW * 0.78;

        Widget cell(int index, {required bool cover, required bool large}) {
          final tile = index < photos.length
              ? _PhotoTile(
                  key: cover
                      ? coverKey
                      : ValueKey('create_listing_photo_$index'),
                  index: index,
                  bytes: photos[index].bytes,
                  isCover: cover,
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
                  large: large,
                  onTap: onAddPhoto,
                  theme: theme,
                );
          return SizedBox.expand(child: tile);
        }

        final showStrip = photos.length >= 5;

        Widget sideCell(int index) {
          return Expanded(child: cell(index, cover: false, large: false));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: mainH,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: mainW,
                    child: cell(0, cover: true, large: true),
                  ),
                  SizedBox(width: gap),
                  SizedBox(
                    width: sideW,
                    child: Column(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              sideCell(1),
                              SizedBox(width: gap),
                              sideCell(2),
                            ],
                          ),
                        ),
                        SizedBox(height: gap),
                        Expanded(
                          child: Row(
                            children: [
                              sideCell(3),
                              SizedBox(width: gap),
                              sideCell(4),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (showStrip) ...[
              const SizedBox(height: 8),
              _SecondaryPhotoRow(
                height: 76,
                gap: gap,
                constrainedTile: 76,
                children: [
                  for (var i = 5; i < photos.length; i++)
                    _PhotoTile(
                      key: ValueKey('create_listing_photo_$i'),
                      index: i,
                      bytes: photos[i].bytes,
                      isCover: false,
                      coverBadge: l10n.createListingCoverBadge,
                      tooltipRemove: l10n.createListingRemovePhoto,
                      enabled: canMutate,
                      onRemove: () => onRemovePhotoAt(i),
                      theme: theme,
                    ),
                  if (photos.length < kMaxListingPhotos)
                    _EmptySlot(
                      primary: true,
                      showPlaceholderKey: false,
                      large: false,
                      label: l10n.createListingAddPhoto,
                      busy: pickingImage,
                      enabled: canAdd,
                      onTap: onAddPhoto,
                      theme: theme,
                    ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Bottom gallery row. Three or four cells share the full width.
/// One or two cells stay a fixed tile so a single photo does not stretch.
class _SecondaryPhotoRow extends StatelessWidget {
  const _SecondaryPhotoRow({
    required this.height,
    required this.gap,
    required this.constrainedTile,
    required this.children,
  });

  final double height;
  final double gap;
  final double constrainedTile;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final expand = children.length >= 3;
    return SizedBox(
      height: height,
      child: Row(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(width: gap),
            if (expand)
              Expanded(child: children[i])
            else
              SizedBox(
                width: constrainedTile,
                height: height,
                child: children[i],
              ),
          ],
        ],
      ),
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
    final hit = isCover ? 44.0 : 36.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(isCover ? 16 : 12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true),
          if (isCover)
            Positioned(
              left: 8,
              bottom: 8,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: kCreateListingActiveFill.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Text(
                    coverBadge,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: kCreateListingActiveForeground,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
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
    required this.large,
    required this.onTap,
    required this.theme,
  });

  final bool large;
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
      alpha: large ? (light ? 0.58 : 0.72) : (light ? 0.40 : 0.52),
    );
    final sheen = large ? (light ? 0.42 : 0.10) : (light ? 0.20 : 0.05);

    final radius = large ? 16.0 : 12.0;
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
            prominent: large,
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
                              Colors.white.withValues(alpha: sheen),
                              Colors.white.withValues(alpha: 0),
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
                            size: large ? 28 : 18,
                            color: iconColor,
                          ),
                          if (primary && large) ...[
                            const SizedBox(height: 6),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Text(
                                label,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: iconColor,
                                  fontWeight: FontWeight.w600,
                                  height: 1.15,
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
