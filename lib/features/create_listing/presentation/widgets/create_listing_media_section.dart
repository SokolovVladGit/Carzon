import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/ui/carzon_icons.dart';
import '../../domain/constants/listing_gallery_limits.dart';
import '../models/create_listing_photo_draft.dart';

/// Hero + optional thumbnails for the create-listing staging gallery (≤ [kMaxListingPhotos]).
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

  final List<CreateListingPhotoDraft> photos;
  final bool pickingImage;
  final bool disabled;
  final VoidCallback onAddPhoto;
  final void Function(int index) onRemovePhotoAt;
  final bool showHeading;

  static const phase3TestKey = ValueKey('create_listing_media_section');

  static const double _frameRadius = 20;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final light = theme.brightness == Brightness.light;
    final l10n = context.l10n;
    final canMutate = !disabled && !pickingImage;
    final quiet = cs.onSurfaceVariant.withValues(alpha: light ? 0.62 : 0.82);
    final premiumAccent = light
        ? cs.primary.withValues(alpha: 0.78)
        : AppTheme.editorialAccentColor(cs).withValues(alpha: 0.95);

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
              letterSpacing: -0.12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.createListingMediaSubtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: quiet,
              height: 1.38,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
        ],
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_frameRadius + 6),
            border: Border.all(
              color: light
                  ? cs.primary.withValues(alpha: 0.24)
                  : AppTheme.editorialAccentColor(cs).withValues(alpha: 0.30),
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.alphaBlend(
                  cs.primary.withValues(alpha: light ? 0.075 : 0.16),
                  light ? cs.surfaceContainerLowest : cs.surfaceContainerHigh,
                ),
                Color.alphaBlend(
                  cs.onSurface.withValues(alpha: light ? 0.012 : 0.035),
                  light ? cs.surface : cs.surfaceContainerLow,
                ),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: cs.shadow.withValues(alpha: light ? 0.070 : 0.24),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: cs.primary.withValues(alpha: light ? 0.055 : 0.08),
                blurRadius: 22,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.zero,
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(_frameRadius + 6),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: (heroBytes == null && canMutate) ? onAddPhoto : null,
                  borderRadius: BorderRadius.circular(_frameRadius + 6),
                  splashColor: cs.onSurface.withValues(alpha: 0.04),
                  highlightColor: cs.onSurface.withValues(alpha: 0.02),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: heroBytes != null
                          ? null
                          : LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color.alphaBlend(
                                  cs.primary.withValues(
                                    alpha: light ? 0.030 : 0.10,
                                  ),
                                  light
                                      ? cs.surfaceContainerLowest
                                      : cs.surfaceContainerHigh,
                                ),
                                Color.alphaBlend(
                                  cs.onSurface.withValues(
                                    alpha: light ? 0.018 : 0.040,
                                  ),
                                  light ? cs.surface : cs.surfaceContainerLow,
                                ),
                              ],
                            ),
                      color: heroBytes != null ? cs.surfaceContainerLow : null,
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (heroBytes != null)
                          Image.memory(heroBytes, fit: BoxFit.cover)
                        else
                          LayoutBuilder(
                            builder: (context, constraints) {
                              if (pickingImage) {
                                return Center(
                                  child: SizedBox.square(
                                    dimension: 28,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: quiet,
                                    ),
                                  ),
                                );
                              }
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.center,
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth: constraints.maxWidth - 16,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        DecoratedBox(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            gradient: light
                                                ? LinearGradient(
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                    colors: [
                                                      Color.alphaBlend(
                                                        cs.primary.withValues(
                                                          alpha: 0.10,
                                                        ),
                                                        cs.surface,
                                                      ),
                                                      cs.surface,
                                                    ],
                                                  )
                                                : RadialGradient(
                                                    colors: [
                                                      Color.alphaBlend(
                                                        cs.primary.withValues(
                                                          alpha: 0.22,
                                                        ),
                                                        cs.surfaceContainerHigh,
                                                      ),
                                                      cs.surfaceContainerLow,
                                                    ],
                                                  ),
                                            border: Border.all(
                                              color: light
                                                  ? cs.primary.withValues(
                                                      alpha: 0.28,
                                                    )
                                                  : AppTheme.editorialAccentColor(
                                                      cs,
                                                    ).withValues(alpha: 0.40),
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color:
                                                    (light
                                                            ? cs.shadow
                                                            : cs.primary)
                                                        .withValues(
                                                          alpha: light
                                                              ? 0.065
                                                              : 0.14,
                                                        ),
                                                blurRadius: 20,
                                                offset: const Offset(0, 7),
                                                spreadRadius: -2,
                                              ),
                                            ],
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(13),
                                            child: Icon(
                                              CarzonIcons.addPhoto,
                                              size: 27,
                                              color: premiumAccent,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 11),
                                        Text(
                                          l10n.createListingHeroEmptyTitle,
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: -0.24,
                                                height: 1.12,
                                                fontSize: 16,
                                                color: cs.onSurface.withValues(
                                                  alpha: 0.93,
                                                ),
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          l10n.createListingHeroEmptyDetail,
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: quiet.withValues(
                                                  alpha: 0.92,
                                                ),
                                                height: 1.34,
                                                fontSize: 11.5,
                                              ),
                                        ),
                                        const SizedBox(height: 11),
                                        DecoratedBox(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                            border: Border.all(
                                              color: light
                                                  ? cs.primary.withValues(
                                                      alpha: 0.30,
                                                    )
                                                  : AppTheme.editorialAccentColor(
                                                      cs,
                                                    ).withValues(alpha: 0.38),
                                            ),
                                            color: light
                                                ? Color.alphaBlend(
                                                    cs.primary.withValues(
                                                      alpha: 0.050,
                                                    ),
                                                    cs.surface,
                                                  )
                                                : Color.alphaBlend(
                                                    cs.primary.withValues(
                                                      alpha: 0.12,
                                                    ),
                                                    cs.surfaceContainerHigh,
                                                  ),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 8.5,
                                            ),
                                            child: Text(
                                              l10n.createListingAddPhoto,
                                              style: theme.textTheme.labelMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w700,
                                                    letterSpacing: 0.04,
                                                    color: cs.onSurface
                                                        .withValues(
                                                          alpha: light
                                                              ? 0.82
                                                              : 0.92,
                                                        ),
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        if (heroBytes == null)
                          Positioned(
                            left: 12,
                            top: 12,
                            child: _CoverHintChip(
                              label: l10n.createListingMediaCoverHint,
                              theme: theme,
                            ),
                          ),
                      ],
                    ),
                  ),
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

class _CoverHintChip extends StatelessWidget {
  const _CoverHintChip({required this.label, required this.theme});

  final String label;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    final light = theme.brightness == Brightness.light;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: light
              ? cs.primary.withValues(alpha: 0.20)
              : AppTheme.editorialAccentColor(cs).withValues(alpha: 0.28),
        ),
        color: light
            ? Color.alphaBlend(
                cs.primary.withValues(alpha: 0.030),
                cs.surface.withValues(alpha: 0.94),
              )
            : Color.alphaBlend(
                cs.primary.withValues(alpha: 0.08),
                cs.surfaceContainerHigh,
              ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: 10,
            letterSpacing: 0.2,
            color: cs.onSurfaceVariant.withValues(alpha: light ? 0.68 : 0.74),
          ),
        ),
      ),
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
      height: 94,
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
            width: 124,
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
    final cs = theme.colorScheme;
    return Tooltip(
      message: tooltipRemove,
      child: SizedBox(
        width: 124,
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
                        color: cs.onSurface.withValues(alpha: 0.76),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        child: Text(
                          coverBadge,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 10.5,
                            letterSpacing: 0.2,
                            color: cs.surface.withValues(alpha: 0.96),
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
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      padding: EdgeInsets.zero,
                      style: IconButton.styleFrom(
                        backgroundColor: cs.surface.withValues(alpha: 0.92),
                      ),
                      onPressed: enabledControls ? onRemove : null,
                      icon: Icon(
                        CarzonIcons.close,
                        size: 17,
                        color: cs.onSurface.withValues(alpha: 0.72),
                      ),
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
    final cs = theme.colorScheme;
    final light = theme.brightness == Brightness.light;
    final quiet = cs.onSurfaceVariant.withValues(alpha: light ? 0.62 : 0.82);

    return Tooltip(
      message: label,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled && !busy ? onTap : null,
            borderRadius: BorderRadius.circular(12),
            splashColor: cs.onSurface.withValues(alpha: 0.04),
            highlightColor: cs.onSurface.withValues(alpha: 0.02),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: enabled && !light
                      ? AppTheme.editorialAccentColor(
                          cs,
                        ).withValues(alpha: 0.26)
                      : cs.outlineVariant.withValues(
                          alpha: enabled ? (light ? 0.32 : 0.34) : 0.2,
                        ),
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
                color: Color.alphaBlend(
                  (light ? cs.outlineVariant : cs.primary).withValues(
                    alpha: enabled ? (light ? 0.03 : 0.06) : 0.02,
                  ),
                  light ? cs.surface : cs.surfaceContainerLow,
                ),
              ),
              child: busy
                  ? Center(
                      child: SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: quiet,
                        ),
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 24,
                          color: quiet,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          label,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                            color: quiet,
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
