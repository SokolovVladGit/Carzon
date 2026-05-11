import 'package:flutter/material.dart';

import 'listing_cover_image.dart';

const Duration _fullscreenIndicatorAnimDuration = Duration(milliseconds: 220);

/// Opens an immersive fullscreen photo viewer with Hero flight from details.
void openListingDetailsFullscreenGallery(
  BuildContext context, {
  required String listingId,
  required List<String> urls,
  required int initialIndex,
  required double heroFlightSourceTopRadius,
}) {
  if (urls.isEmpty) return;
  final n = urls.length;
  final i = initialIndex.clamp(0, n - 1);
  Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (ctx) => ListingDetailsFullscreenGalleryPage(
        listingId: listingId,
        urls: urls,
        initialIndex: i,
        heroFlightSourceTopRadius: heroFlightSourceTopRadius,
      ),
    ),
  );
}

Object _fullscreenHeroTag(String listingId, int index) => index == 0
    ? listingCoverHeroTag(listingId)
    : listingDetailsGalleryHeroTag(listingId, index);

/// No AnimatedOpacity — matches Hero-bound listing details policy.
Widget _fullscreenHeroNetworkFrameBuilder(
  BuildContext context,
  Widget imageWidget,
  int? frame,
  bool wasSynchronouslyLoaded,
) {
  if (wasSynchronouslyLoaded) return imageWidget;
  return frame == null ? const ColoredBox(color: Colors.black) : imageWidget;
}

/// Fullscreen carousel with pinch-zoom; disables paging while zoomed.
class ListingDetailsFullscreenGalleryPage extends StatefulWidget {
  const ListingDetailsFullscreenGalleryPage({
    super.key,
    required this.listingId,
    required this.urls,
    required this.initialIndex,
    required this.heroFlightSourceTopRadius,
  });

  final String listingId;
  final List<String> urls;
  final int initialIndex;
  final double heroFlightSourceTopRadius;

  @override
  State<ListingDetailsFullscreenGalleryPage> createState() =>
      _ListingDetailsFullscreenGalleryPageState();
}

class _ListingDetailsFullscreenGalleryPageState
    extends State<ListingDetailsFullscreenGalleryPage> {
  static const double _zoomLockThreshold = 1.01;
  static const double _doubleTapScale = 2.5;

  late final PageController _pageController;
  late final List<TransformationController> _zoomControllers;

  late int _currentPage;
  bool _zoomedPagingLocked = false;
  VoidCallback? _boundZoomListener;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialIndex.clamp(0, widget.urls.length - 1);
    _pageController = PageController(initialPage: _currentPage);
    _zoomControllers = List.generate(
      widget.urls.length,
      (_) => TransformationController(),
    );
    _bindZoomListenerForPage(_currentPage);
  }

  void _bindZoomListenerForPage(int page) {
    _boundZoomListener?.call();
    _boundZoomListener = null;
    final c = _zoomControllers[page];
    void onZoom() {
      final scale = c.value.getMaxScaleOnAxis();
      final locked = scale > _zoomLockThreshold;
      if (locked != _zoomedPagingLocked && mounted) {
        setState(() => _zoomedPagingLocked = locked);
      }
    }

    c.addListener(onZoom);
    _boundZoomListener = () => c.removeListener(onZoom);
    onZoom();
  }

  @override
  void dispose() {
    _boundZoomListener?.call();
    for (final c in _zoomControllers) {
      c.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  void _resetAllTransformsExcept(int keep) {
    for (var j = 0; j < _zoomControllers.length; j++) {
      if (j != keep) {
        _zoomControllers[j].value = Matrix4.identity();
      }
    }
  }

  void _onGalleryPageChanged(int i) {
    setState(() {
      _currentPage = i;
      _zoomedPagingLocked = false;
    });
    _resetAllTransformsExcept(i);
    _zoomControllers[i].value = Matrix4.identity();
    _bindZoomListenerForPage(i);
  }

  void _onDoubleTapDown(TapDownDetails details) {
    final c = _zoomControllers[_currentPage];
    final scale = c.value.getMaxScaleOnAxis();
    if (scale > _zoomLockThreshold) {
      c.value = Matrix4.identity();
      setState(() => _zoomedPagingLocked = false);
      return;
    }

    final size = MediaQuery.sizeOf(context);
    final cx = size.width / 2;
    final cy = size.height / 2;
    final forward = Matrix4.translationValues(cx, cy, 0);
    final scaled = Matrix4.diagonal3Values(_doubleTapScale, _doubleTapScale, 1);
    final back = Matrix4.translationValues(-cx, -cy, 0);
    c.value = forward * scaled * back;
    setState(() => _zoomedPagingLocked = true);
  }

  @override
  Widget build(BuildContext context) {
    final urls = widget.urls;
    final scheme = Theme.of(context).colorScheme;
    final closeTooltip = MaterialLocalizations.of(context).closeButtonTooltip;

    return Scaffold(
      key: const ValueKey<String>('listing-fullscreen-gallery'),
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _pageController,
            physics: _zoomedPagingLocked
                ? const NeverScrollableScrollPhysics()
                : const PageScrollPhysics(),
            itemCount: urls.length,
            onPageChanged: _onGalleryPageChanged,
            itemBuilder: (context, index) {
              final url = urls[index].trim();
              final heroTag = _fullscreenHeroTag(widget.listingId, index);
              final image = url.isEmpty
                  ? const ColoredBox(color: Colors.black)
                  : Image.network(
                      url,
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                      errorBuilder: (_, _, _) =>
                          const ColoredBox(color: Colors.black),
                      frameBuilder: _fullscreenHeroNetworkFrameBuilder,
                    );

              return Hero(
                tag: heroTag,
                flightShuttleBuilder: listingCoverHeroFlightShuttleBuilder(
                  widget.heroFlightSourceTopRadius,
                ),
                child: LayoutBuilder(
                  builder: (ctx, constraints) {
                    final child = SizedBox(
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      child: Center(child: image),
                    );
                    final iv = InteractiveViewer(
                      transformationController: _zoomControllers[index],
                      minScale: 1,
                      maxScale: 4,
                      clipBehavior: Clip.hardEdge,
                      boundaryMargin: const EdgeInsets.all(120),
                      child: child,
                    );
                    return index == _currentPage
                        ? GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onDoubleTapDown: _onDoubleTapDown,
                            child: iv,
                          )
                        : iv;
                  },
                ),
              );
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Align(
                alignment: Alignment.topLeft,
                child: Tooltip(
                  message: closeTooltip,
                  child: Semantics(
                    button: true,
                    label: closeTooltip,
                    child: Material(
                      color: Colors.white.withValues(alpha: 0.12),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => Navigator.of(context).pop(),
                        child: const SizedBox(
                          width: 44,
                          height: 44,
                          child: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (urls.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: MediaQuery.paddingOf(context).bottom + 20,
              child: _FullscreenGalleryIndicator(
                currentIndex: _currentPage,
                imageCount: urls.length,
                activeColor: scheme.primary.withValues(alpha: 0.9),
                inactiveColor: Colors.white.withValues(alpha: 0.38),
              ),
            ),
        ],
      ),
    );
  }
}

class _FullscreenGalleryIndicator extends StatelessWidget {
  const _FullscreenGalleryIndicator({
    required this.currentIndex,
    required this.imageCount,
    required this.activeColor,
    required this.inactiveColor,
  });

  final int currentIndex;
  final int imageCount;
  final Color activeColor;
  final Color inactiveColor;

  static const double _dot = 5.5;
  static const double _pill = 18;
  static const double _h = 5.5;

  @override
  Widget build(BuildContext context) {
    final safe = currentIndex.clamp(0, imageCount - 1);
    final track = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(imageCount, (i) {
        final on = i == safe;
        return AnimatedContainer(
          duration: _fullscreenIndicatorAnimDuration,
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          height: _h,
          width: on ? _pill : _dot,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: on ? activeColor : inactiveColor,
          ),
        );
      }),
    );

    return Semantics(
      label: '${safe + 1} of $imageCount',
      child: SizedBox(
        width: double.infinity,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: track,
        ),
      ),
    );
  }
}
