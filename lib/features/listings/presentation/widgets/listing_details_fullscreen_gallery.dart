import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import 'listing_cover_image.dart';

const Duration _fullscreenIndicatorAnimDuration = Duration(milliseconds: 220);

// --- Dismiss thresholds (tunable) ---
const double _dismissDistanceViewportFraction = 0.18;
const double _dismissDistanceMinLogical = 96;
const double _dismissDistanceMaxLogical = 180;
const double _dismissVelocityThreshold = 900;
const double _dismissVelocityMinDisplacement = 24;
const double _dismissMaxScaleReduction = 0.04;
const double _upwardDragResistanceFactor = 0.18;

const Duration _dismissSnapBackDuration = Duration(milliseconds: 210);
const Duration _dismissCommitDuration = Duration(milliseconds: 220);
const Curve _dismissMotionCurve = Curves.easeOutCubic;

const double _zoomLockThreshold = 1.01;
const double _doubleTapScale = 2.5;
const double _zoomBoundaryMargin = 120;
const double _axisLockSlop = 8;
const double _axisDominanceRatio = 1.2;

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
    _ListingDetailsFullscreenGalleryRoute(
      builder: (ctx) => ListingDetailsFullscreenGalleryPage(
        listingId: listingId,
        urls: urls,
        initialIndex: i,
        heroFlightSourceTopRadius: heroFlightSourceTopRadius,
      ),
    ),
  );
}

/// Non-opaque fullscreen route so interactive dismiss can reveal listing details.
class _ListingDetailsFullscreenGalleryRoute extends PageRoute<void> {
  _ListingDetailsFullscreenGalleryRoute({required this.builder});

  final WidgetBuilder builder;
  bool _interactiveDismissCommitted = false;

  void markInteractiveDismissCommitted() {
    _interactiveDismissCommitted = true;
    controller
      ?..duration = Duration.zero
      ..reverseDuration = Duration.zero;
  }

  @override
  bool get opaque => false;

  @override
  bool get fullscreenDialog => true;

  @override
  bool get barrierDismissible => false;

  @override
  Color get barrierColor => Colors.transparent;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 280);

  @override
  Duration get reverseTransitionDuration => _interactiveDismissCommitted
      ? Duration.zero
      : const Duration(milliseconds: 240);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (_interactiveDismissCommitted) return child;
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
      child: child,
    );
  }
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

enum _GalleryInteractionPhase {
  idle,
  axisUndecided,
  horizontalPageDrag,
  dismissDragging,
  initialPinch,
  zoomed,
  dismissSnappingBack,
  dismissCommitting,
}

@visibleForTesting
class ListingFullscreenGalleryDebugState extends StatelessWidget {
  const ListingFullscreenGalleryDebugState({
    super.key,
    required this.page,
    required this.dismissOffset,
    required this.backdropOpacity,
    required this.chromeOpacity,
    required this.presentationScale,
    required this.matrix,
    required this.phase,
    required this.releaseVelocity,
  });

  final int page;
  final double dismissOffset;
  final double backdropOpacity;
  final double chromeOpacity;
  final double presentationScale;
  final Matrix4 matrix;
  final String phase;
  final Offset releaseVelocity;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

double _dismissDistanceThreshold(double viewportHeight) {
  return (viewportHeight * _dismissDistanceViewportFraction).clamp(
    _dismissDistanceMinLogical,
    _dismissDistanceMaxLogical,
  );
}

/// Fullscreen carousel with pinch-zoom, swipe-down dismiss, and paging lock while zoomed.
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
    extends State<ListingDetailsFullscreenGalleryPage>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  late final List<TransformationController> _zoomControllers;
  late final AnimationController _dismissMotionController;

  late int _currentPage;
  _GalleryInteractionPhase _phase = _GalleryInteractionPhase.idle;
  Drag? _pageDrag;
  int? _pageDragOriginPage;
  double _horizontalDragTotal = 0;
  Offset _accumulatedDelta = Offset.zero;
  Offset _lastGlobalFocalPoint = Offset.zero;
  Offset _lastLocalFocalPoint = Offset.zero;
  Offset _doubleTapLocalPosition = Offset.zero;
  double _lastPinchScaleSignal = 1;
  int _pointerCount = 0;
  int? _primaryPointer;
  final List<(Duration, Offset)> _primaryVelocitySamples = [];
  Offset _primaryReleaseVelocity = Offset.zero;
  final Set<int> _zoomedPointers = {};
  int? _zoomedTapPointer;
  Offset _zoomedTapDownPosition = Offset.zero;
  Duration? _lastZoomedTapTime;
  Offset? _lastZoomedTapPosition;

  double _dismissDragOffset = 0;
  double _backdropOpacity = 1;
  double _presentationScale = 1;
  double _chromeOpacity = 1;
  bool _popInFlight = false;
  bool _normalPopInFlight = false;
  bool _allowRoutePop = false;
  bool _heroEnabled = true;

  Animation<double>? _dismissOffsetAnim;
  Animation<double>? _backdropOpacityAnim;
  Animation<double>? _presentationScaleAnim;
  Animation<double>? _chromeOpacityAnim;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialIndex.clamp(0, widget.urls.length - 1);
    _pageController = PageController(initialPage: _currentPage);
    _zoomControllers = List.generate(
      widget.urls.length,
      (_) => TransformationController(),
    );
    _dismissMotionController = AnimationController(vsync: this)
      ..addListener(_onDismissAnimationTick);
  }

  bool get _isZoomedEffective => _phase == _GalleryInteractionPhase.zoomed;

  bool get _baseCoordinatorEnabled =>
      !_isZoomedEffective &&
      !_popInFlight &&
      !_normalPopInFlight &&
      (_phase == _GalleryInteractionPhase.idle ||
          _phase == _GalleryInteractionPhase.axisUndecided ||
          _phase == _GalleryInteractionPhase.horizontalPageDrag ||
          _phase == _GalleryInteractionPhase.dismissDragging ||
          _phase == _GalleryInteractionPhase.initialPinch);

  @override
  void dispose() {
    _pageDrag?.cancel();
    _dismissMotionController.dispose();
    for (final c in _zoomControllers) {
      c.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  void _normalizeZoomIfAtBaseScale() {
    final c = _zoomControllers[_currentPage];
    if (c.value.getMaxScaleOnAxis() <= _zoomLockThreshold) {
      c.value = Matrix4.identity();
      if (mounted && _phase == _GalleryInteractionPhase.zoomed) {
        setState(() => _phase = _GalleryInteractionPhase.idle);
      }
    }
  }

  void _onZoomInteractionEnd(ScaleEndDetails details) {
    _normalizeZoomIfAtBaseScale();
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
      if (_phase != _GalleryInteractionPhase.horizontalPageDrag) {
        _phase = _GalleryInteractionPhase.idle;
      }
    });
    _resetAllTransformsExcept(i);
    _zoomControllers[i].value = Matrix4.identity();
  }

  void _onDoubleTapDown(TapDownDetails details) {
    _doubleTapLocalPosition = details.localPosition;
  }

  void _toggleDoubleTapZoom() {
    if (_popInFlight || _normalPopInFlight) return;
    final c = _zoomControllers[_currentPage];
    if (_isZoomedEffective) {
      c.value = Matrix4.identity();
      setState(() => _phase = _GalleryInteractionPhase.idle);
      return;
    }
    if (_phase != _GalleryInteractionPhase.idle) return;

    final focal = _doubleTapLocalPosition;
    final forward = Matrix4.translationValues(focal.dx, focal.dy, 0);
    final scaled = Matrix4.diagonal3Values(_doubleTapScale, _doubleTapScale, 1);
    final back = Matrix4.translationValues(-focal.dx, -focal.dy, 0);
    c.value = forward * scaled * back;
    setState(() => _phase = _GalleryInteractionPhase.zoomed);
  }

  void _syncDismissPresentationFromOffset(double offset) {
    final vh = MediaQuery.sizeOf(context).height;
    final threshold = _dismissDistanceThreshold(vh);
    final progress = (offset / threshold).clamp(0.0, 1.2);
    _backdropOpacity = (1.0 - progress).clamp(0.0, 1.0);
    _presentationScale =
        1.0 - (progress.clamp(0.0, 1.0) * _dismissMaxScaleReduction);
    _chromeOpacity = (1.0 - progress).clamp(0.0, 1.0);
  }

  void _resetDismissPresentation() {
    _dismissDragOffset = 0;
    _backdropOpacity = 1;
    _presentationScale = 1;
    _chromeOpacity = 1;
  }

  void _onPointerDown(PointerDownEvent event) {
    if (_pointerCount == 0) {
      _primaryPointer = event.pointer;
      _primaryVelocitySamples
        ..clear()
        ..add((event.timeStamp, event.position));
      _primaryReleaseVelocity = Offset.zero;
    }
    _pointerCount++;
    if (_pointerCount >= 2 && _baseCoordinatorEnabled) {
      _enterInitialPinch();
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (event.pointer != _primaryPointer) return;
    _primaryVelocitySamples.add((event.timeStamp, event.position));
    final cutoff = event.timeStamp - const Duration(milliseconds: 80);
    while (_primaryVelocitySamples.length > 2 &&
        _primaryVelocitySamples[1].$1 < cutoff) {
      _primaryVelocitySamples.removeAt(0);
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (event.pointer == _primaryPointer) {
      _primaryVelocitySamples.add((event.timeStamp, event.position));
      if (_primaryVelocitySamples.length >= 2) {
        final first = _primaryVelocitySamples.first;
        final last = _primaryVelocitySamples.last;
        final elapsedMicros = (last.$1 - first.$1).inMicroseconds;
        if (elapsedMicros > 0) {
          _primaryReleaseVelocity =
              (last.$2 - first.$2) *
              (Duration.microsecondsPerSecond / elapsedMicros);
        }
      }
      _primaryPointer = null;
      _primaryVelocitySamples.clear();
    }
    _pointerCount = (_pointerCount - 1).clamp(0, 10);
    if (_phase == _GalleryInteractionPhase.initialPinch && _pointerCount < 2) {
      _finishInitialPinch();
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (event.pointer == _primaryPointer) {
      _primaryPointer = null;
      _primaryVelocitySamples.clear();
      _primaryReleaseVelocity = Offset.zero;
    }
    _pointerCount = (_pointerCount - 1).clamp(0, 10);
    _cancelCoordinatorGesture();
  }

  void _onZoomedPointerDown(PointerDownEvent event) {
    _zoomedPointers.add(event.pointer);
    if (_zoomedPointers.length == 1) {
      _zoomedTapPointer = event.pointer;
      _zoomedTapDownPosition = event.localPosition;
    } else {
      _zoomedTapPointer = null;
    }
  }

  void _onZoomedPointerMove(PointerMoveEvent event) {
    if (event.pointer == _zoomedTapPointer &&
        (event.localPosition - _zoomedTapDownPosition).distance >
            _axisLockSlop) {
      _zoomedTapPointer = null;
    }
  }

  void _onZoomedPointerUp(PointerUpEvent event) {
    _zoomedPointers.remove(event.pointer);
    if (event.pointer != _zoomedTapPointer) return;
    _zoomedTapPointer = null;
    final lastTime = _lastZoomedTapTime;
    final lastPosition = _lastZoomedTapPosition;
    final isDoubleTap =
        lastTime != null &&
        event.timeStamp - lastTime <= const Duration(milliseconds: 300) &&
        lastPosition != null &&
        (event.localPosition - lastPosition).distance <= 32;
    if (isDoubleTap) {
      _lastZoomedTapTime = null;
      _lastZoomedTapPosition = null;
      _doubleTapLocalPosition = event.localPosition;
      _toggleDoubleTapZoom();
    } else {
      _lastZoomedTapTime = event.timeStamp;
      _lastZoomedTapPosition = event.localPosition;
    }
  }

  void _onZoomedPointerCancel(PointerCancelEvent event) {
    _zoomedPointers.remove(event.pointer);
    if (event.pointer == _zoomedTapPointer) {
      _zoomedTapPointer = null;
    }
  }

  void _onBaseScaleStart(ScaleStartDetails details) {
    if (!_baseCoordinatorEnabled || _pointerCount >= 2) return;
    _accumulatedDelta = Offset.zero;
    _lastGlobalFocalPoint = details.focalPoint;
    _lastLocalFocalPoint = details.localFocalPoint;
    setState(() => _phase = _GalleryInteractionPhase.axisUndecided);
  }

  void _onBaseScaleUpdate(ScaleUpdateDetails details) {
    _lastGlobalFocalPoint = details.focalPoint;
    _lastLocalFocalPoint = details.localFocalPoint;
    if (details.pointerCount >= 2 || _pointerCount >= 2) {
      if (_phase != _GalleryInteractionPhase.initialPinch) {
        _enterInitialPinch();
      }
      _updateInitialPinch(details);
      return;
    }

    if (_phase == _GalleryInteractionPhase.axisUndecided) {
      _accumulatedDelta += details.focalPointDelta;
      final dx = _accumulatedDelta.dx.abs();
      final dy = _accumulatedDelta.dy.abs();
      if (dx < _axisLockSlop && dy < _axisLockSlop) return;
      if (dx > dy * _axisDominanceRatio) {
        _beginHorizontalPageDrag();
        _updateHorizontalPageDrag(_accumulatedDelta.dx);
      } else if (dy > dx * _axisDominanceRatio) {
        setState(() => _phase = _GalleryInteractionPhase.dismissDragging);
        _updateDismissDrag(_accumulatedDelta.dy);
      }
      return;
    }

    if (_phase == _GalleryInteractionPhase.horizontalPageDrag) {
      _horizontalDragTotal += details.focalPointDelta.dx;
      _updateHorizontalPageDrag(details.focalPointDelta.dx);
    } else if (_phase == _GalleryInteractionPhase.dismissDragging) {
      _updateDismissDrag(details.focalPointDelta.dy);
    }
  }

  void _onBaseScaleEnd(ScaleEndDetails details) {
    if (_phase == _GalleryInteractionPhase.horizontalPageDrag) {
      final scaleVelocity = details.velocity.pixelsPerSecond.dx;
      var velocity = _primaryReleaseVelocity.dx.abs() > scaleVelocity.abs()
          ? _primaryReleaseVelocity.dx
          : scaleVelocity;
      final viewportWidth = _pageController.position.viewportDimension;
      if (velocity.abs() < 400 &&
          _horizontalDragTotal.abs() >= viewportWidth * 0.18) {
        velocity = _horizontalDragTotal.sign * 800;
      }
      final drag = _pageDrag;
      _pageDrag = null;
      drag?.end(
        DragEndDetails(
          velocity: Velocity(pixelsPerSecond: Offset(velocity, 0)),
          primaryVelocity: velocity,
        ),
      );
      _horizontalDragTotal = 0;
      setState(() => _phase = _GalleryInteractionPhase.idle);
      return;
    }
    if (_phase == _GalleryInteractionPhase.dismissDragging) {
      final scaleVelocity = details.velocity.pixelsPerSecond.dy;
      final velocity = _primaryReleaseVelocity.dy.abs() > scaleVelocity.abs()
          ? _primaryReleaseVelocity.dy
          : scaleVelocity;
      _finishDismissDrag(velocity);
      return;
    }
    if (_phase == _GalleryInteractionPhase.initialPinch) {
      _finishInitialPinch();
      return;
    }
    if (_phase == _GalleryInteractionPhase.axisUndecided) {
      setState(() => _phase = _GalleryInteractionPhase.idle);
    }
  }

  void _beginHorizontalPageDrag() {
    if (!_pageController.hasClients) return;
    _pageDragOriginPage = _currentPage;
    _horizontalDragTotal = _accumulatedDelta.dx;
    _pageDrag = _pageController.position.drag(
      DragStartDetails(
        globalPosition: _lastGlobalFocalPoint,
        localPosition: _lastLocalFocalPoint,
      ),
      () => _pageDrag = null,
    );
    setState(() => _phase = _GalleryInteractionPhase.horizontalPageDrag);
  }

  void _updateHorizontalPageDrag(double dx) {
    _pageDrag?.update(
      DragUpdateDetails(
        globalPosition: _lastGlobalFocalPoint,
        localPosition: _lastLocalFocalPoint,
        delta: Offset(dx, 0),
        primaryDelta: dx,
      ),
    );
  }

  void _updateDismissDrag(double delta) {
    setState(() {
      if (delta > 0) {
        _dismissDragOffset += delta;
      } else {
        _dismissDragOffset =
            (_dismissDragOffset + delta * _upwardDragResistanceFactor).clamp(
              0.0,
              double.infinity,
            );
      }
      _syncDismissPresentationFromOffset(_dismissDragOffset);
    });
  }

  void _finishDismissDrag(double velocity) {
    final viewportHeight = MediaQuery.sizeOf(context).height;
    final threshold = _dismissDistanceThreshold(viewportHeight);
    final shouldCommit =
        _dismissDragOffset >= threshold ||
        (velocity >= _dismissVelocityThreshold &&
            _dismissDragOffset >= _dismissVelocityMinDisplacement);
    if (shouldCommit) {
      _runDismissCommitAnimation(viewportHeight: viewportHeight);
    } else {
      _runDismissSnapBackAnimation();
    }
  }

  void _enterInitialPinch() {
    final stablePage = _pageDragOriginPage ?? _currentPage;
    _pageDrag?.cancel();
    _pageDrag = null;
    if (_pageController.hasClients) {
      _pageController.jumpToPage(stablePage);
    }
    _pageDragOriginPage = null;
    _horizontalDragTotal = 0;
    _currentPage = stablePage;
    _resetAllTransformsExcept(stablePage);
    _dismissMotionController.stop();
    _resetDismissPresentation();
    _lastPinchScaleSignal = 1;
    setState(() => _phase = _GalleryInteractionPhase.initialPinch);
  }

  void _updateInitialPinch(ScaleUpdateDetails details) {
    final signal = details.scale <= 0 ? 1.0 : details.scale;
    final signalFactor = signal / _lastPinchScaleSignal;
    _lastPinchScaleSignal = signal;
    final controller = _zoomControllers[_currentPage];
    final currentScale = controller.value.getMaxScaleOnAxis();
    final targetScale = (currentScale * signalFactor).clamp(1.0, 4.0);
    final factor = targetScale / currentScale;
    if ((factor - 1).abs() < 0.0001) return;
    final focal = details.localFocalPoint;
    controller.value =
        Matrix4.translationValues(focal.dx, focal.dy, 0) *
        Matrix4.diagonal3Values(factor, factor, 1) *
        Matrix4.translationValues(-focal.dx, -focal.dy, 0) *
        controller.value;
    setState(() {});
  }

  void _finishInitialPinch() {
    final controller = _zoomControllers[_currentPage];
    if (controller.value.getMaxScaleOnAxis() > _zoomLockThreshold) {
      setState(() => _phase = _GalleryInteractionPhase.zoomed);
    } else {
      controller.value = Matrix4.identity();
      setState(() => _phase = _GalleryInteractionPhase.idle);
    }
  }

  void _cancelCoordinatorGesture() {
    _pageDrag?.cancel();
    _pageDrag = null;
    if (_pageController.hasClients) {
      _pageController.jumpToPage(_pageDragOriginPage ?? _currentPage);
    }
    _pageDragOriginPage = null;
    _horizontalDragTotal = 0;
    if (_dismissDragOffset > 0) {
      _runDismissSnapBackAnimation();
      return;
    }
    _normalizeZoomIfAtBaseScale();
    if (mounted && !_isZoomedEffective) {
      setState(() => _phase = _GalleryInteractionPhase.idle);
    }
  }

  void _runDismissSnapBackAnimation() {
    setState(() => _phase = _GalleryInteractionPhase.dismissSnappingBack);

    final startOffset = _dismissDragOffset;
    final startBackdrop = _backdropOpacity;
    final startScale = _presentationScale;
    final startChrome = _chromeOpacity;

    _dismissMotionController.duration = _dismissSnapBackDuration;
    _dismissOffsetAnim = Tween<double>(begin: startOffset, end: 0).animate(
      CurvedAnimation(
        parent: _dismissMotionController,
        curve: _dismissMotionCurve,
      ),
    );
    _backdropOpacityAnim = Tween<double>(begin: startBackdrop, end: 1).animate(
      CurvedAnimation(
        parent: _dismissMotionController,
        curve: _dismissMotionCurve,
      ),
    );
    _presentationScaleAnim = Tween<double>(begin: startScale, end: 1).animate(
      CurvedAnimation(
        parent: _dismissMotionController,
        curve: _dismissMotionCurve,
      ),
    );
    _chromeOpacityAnim = Tween<double>(begin: startChrome, end: 1).animate(
      CurvedAnimation(
        parent: _dismissMotionController,
        curve: _dismissMotionCurve,
      ),
    );

    _dismissMotionController.forward(from: 0).then((_) {
      if (!mounted) return;
      setState(() {
        _phase = _GalleryInteractionPhase.idle;
        _resetDismissPresentation();
      });
    });
  }

  void _runDismissCommitAnimation({required double viewportHeight}) {
    if (_popInFlight) return;
    _popInFlight = true;
    (ModalRoute.of(context) as _ListingDetailsFullscreenGalleryRoute?)
        ?.markInteractiveDismissCommitted();
    setState(() {
      _phase = _GalleryInteractionPhase.dismissCommitting;
      _heroEnabled = false;
    });

    final startOffset = _dismissDragOffset;
    final startBackdrop = _backdropOpacity;
    final startScale = _presentationScale;
    final startChrome = _chromeOpacity;
    final endOffset = viewportHeight * 1.05;

    _dismissMotionController.duration = _dismissCommitDuration;
    _dismissOffsetAnim = Tween<double>(begin: startOffset, end: endOffset)
        .animate(
          CurvedAnimation(
            parent: _dismissMotionController,
            curve: _dismissMotionCurve,
          ),
        );
    _backdropOpacityAnim = Tween<double>(begin: startBackdrop, end: 0).animate(
      CurvedAnimation(
        parent: _dismissMotionController,
        curve: _dismissMotionCurve,
      ),
    );
    _presentationScaleAnim =
        Tween<double>(
          begin: startScale,
          end: 1.0 - _dismissMaxScaleReduction,
        ).animate(
          CurvedAnimation(
            parent: _dismissMotionController,
            curve: _dismissMotionCurve,
          ),
        );
    _chromeOpacityAnim = Tween<double>(begin: startChrome, end: 0).animate(
      CurvedAnimation(
        parent: _dismissMotionController,
        curve: _dismissMotionCurve,
      ),
    );

    _dismissMotionController.forward(from: 0).then((_) async {
      if (!mounted) return;
      setState(() => _allowRoutePop = true);
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      Navigator.of(context).pop();
    });
  }

  void _onDismissAnimationTick() {
    if (!mounted ||
        _dismissOffsetAnim == null ||
        _backdropOpacityAnim == null ||
        _presentationScaleAnim == null ||
        _chromeOpacityAnim == null) {
      return;
    }
    setState(() {
      _dismissDragOffset = _dismissOffsetAnim!.value;
      _backdropOpacity = _backdropOpacityAnim!.value;
      _presentationScale = _presentationScaleAnim!.value;
      _chromeOpacity = _chromeOpacityAnim!.value;
    });
  }

  Future<void> _requestNormalPop() async {
    if (_popInFlight || _normalPopInFlight) return;
    _normalPopInFlight = true;
    _pageDrag?.cancel();
    _pageDrag = null;
    _dismissMotionController.stop();
    if (_pageController.hasClients) {
      _pageController.jumpToPage(_pageDragOriginPage ?? _currentPage);
    }
    _pageDragOriginPage = null;
    _horizontalDragTotal = 0;
    _zoomControllers[_currentPage].value = Matrix4.identity();
    setState(() {
      _phase = _GalleryInteractionPhase.idle;
      _resetDismissPresentation();
      _heroEnabled = true;
      _allowRoutePop = true;
    });
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final urls = widget.urls;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final closeTooltip = MaterialLocalizations.of(context).closeButtonTooltip;
    Widget? debugState;
    assert(() {
      debugState = ValueListenableBuilder<Matrix4>(
        valueListenable: _zoomControllers[_currentPage],
        builder: (context, matrix, child) => ListingFullscreenGalleryDebugState(
          key: const Key('listing-fullscreen-gallery-debug-state'),
          page: _currentPage,
          dismissOffset: _dismissDragOffset,
          backdropOpacity: _backdropOpacity,
          chromeOpacity: _chromeOpacity,
          presentationScale: _presentationScale,
          matrix: Matrix4.copy(matrix),
          phase: _phase.name,
          releaseVelocity: _primaryReleaseVelocity,
        ),
      );
      return true;
    }());

    return PopScope(
      canPop: _allowRoutePop,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _requestNormalPop();
      },
      child: Scaffold(
        key: const ValueKey<String>('listing-fullscreen-gallery'),
        backgroundColor: Colors.transparent,
        body: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              key: const Key('listing-fullscreen-gallery-backdrop'),
              color: Colors.black.withValues(alpha: _backdropOpacity),
            ),
            Transform.translate(
              offset: Offset(0, _dismissDragOffset),
              child: Transform.scale(
                scale: _presentationScale,
                alignment: Alignment.center,
                child: Stack(
                  key: const Key('listing-fullscreen-gallery-dismiss-layer'),
                  fit: StackFit.expand,
                  children: [
                    HeroMode(
                      enabled: _heroEnabled,
                      child: IgnorePointer(
                        ignoring: !_isZoomedEffective,
                        child: PageView.builder(
                          key: const Key('listing-fullscreen-gallery-pageview'),
                          controller: _pageController,
                          physics: _isZoomedEffective
                              ? const NeverScrollableScrollPhysics()
                              : const PageScrollPhysics(),
                          itemCount: urls.length,
                          onPageChanged: _onGalleryPageChanged,
                          itemBuilder: (context, index) {
                            final url = urls[index].trim();
                            final heroTag = _fullscreenHeroTag(
                              widget.listingId,
                              index,
                            );
                            final image = url.isEmpty
                                ? const ColoredBox(color: Colors.black)
                                : Image.network(
                                    url,
                                    fit: BoxFit.contain,
                                    gaplessPlayback: true,
                                    errorBuilder: (_, _, _) =>
                                        const ColoredBox(color: Colors.black),
                                    frameBuilder:
                                        _fullscreenHeroNetworkFrameBuilder,
                                  );

                            final allowZoomPan =
                                index == _currentPage && _isZoomedEffective;
                            return Hero(
                              tag: heroTag,
                              flightShuttleBuilder:
                                  listingCoverHeroFlightShuttleBuilder(
                                    widget.heroFlightSourceTopRadius,
                                  ),
                              child: LayoutBuilder(
                                builder: (ctx, constraints) {
                                  final child = SizedBox(
                                    width: constraints.maxWidth,
                                    height: constraints.maxHeight,
                                    child: Center(child: image),
                                  );
                                  final viewer = InteractiveViewer(
                                    key: index == _currentPage
                                        ? const Key(
                                            'listing-fullscreen-gallery-active-viewer',
                                          )
                                        : null,
                                    transformationController:
                                        _zoomControllers[index],
                                    minScale: 1,
                                    maxScale: 4,
                                    clipBehavior: Clip.hardEdge,
                                    panEnabled: allowZoomPan,
                                    scaleEnabled: allowZoomPan,
                                    boundaryMargin: allowZoomPan
                                        ? const EdgeInsets.all(
                                            _zoomBoundaryMargin,
                                          )
                                        : EdgeInsets.zero,
                                    onInteractionEnd: allowZoomPan
                                        ? _onZoomInteractionEnd
                                        : null,
                                    child: child,
                                  );
                                  if (!allowZoomPan) return viewer;
                                  return Listener(
                                    behavior: HitTestBehavior.translucent,
                                    onPointerDown: _onZoomedPointerDown,
                                    onPointerMove: _onZoomedPointerMove,
                                    onPointerUp: _onZoomedPointerUp,
                                    onPointerCancel: _onZoomedPointerCancel,
                                    child: viewer,
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    if (!_isZoomedEffective)
                      Positioned.fill(
                        child: Listener(
                          behavior: HitTestBehavior.translucent,
                          onPointerDown: _onPointerDown,
                          onPointerMove: _onPointerMove,
                          onPointerUp: _onPointerUp,
                          onPointerCancel: _onPointerCancel,
                          child: GestureDetector(
                            key: const Key(
                              'listing-fullscreen-gallery-interaction-coordinator',
                            ),
                            behavior: HitTestBehavior.translucent,
                            onScaleStart: _baseCoordinatorEnabled
                                ? _onBaseScaleStart
                                : null,
                            onScaleUpdate: _baseCoordinatorEnabled
                                ? _onBaseScaleUpdate
                                : null,
                            onScaleEnd: _baseCoordinatorEnabled
                                ? _onBaseScaleEnd
                                : null,
                            onDoubleTapDown: _onDoubleTapDown,
                            onDoubleTap: _toggleDoubleTapZoom,
                          ),
                        ),
                      ),
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: MediaQuery.paddingOf(context).top + 80,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(
                                  alpha: isDark ? 0.58 : 0.48,
                                ),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: MediaQuery.paddingOf(context).top + 8,
                      left: 8,
                      child: Opacity(
                        opacity: _chromeOpacity,
                        child: Tooltip(
                          message: closeTooltip,
                          child: Semantics(
                            button: true,
                            label: closeTooltip,
                            child: _FullscreenGalleryGlassButton(
                              key: const Key(
                                'listing-fullscreen-gallery-close',
                              ),
                              isDark: isDark,
                              scheme: scheme,
                              onTap: _requestNormalPop,
                              child: const Icon(Icons.close, size: 22),
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
                        child: Opacity(
                          opacity: _chromeOpacity,
                          child: _FullscreenGalleryIndicator(
                            key: const Key(
                              'listing-fullscreen-gallery-indicator',
                            ),
                            currentIndex: _currentPage,
                            imageCount: urls.length,
                            isDark: isDark,
                            scheme: scheme,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (debugState != null) debugState!,
          ],
        ),
      ),
    );
  }
}

/// Frosted circular control for fullscreen gallery chrome.
class _FullscreenGalleryGlassButton extends StatelessWidget {
  const _FullscreenGalleryGlassButton({
    super.key,
    required this.isDark,
    required this.scheme,
    required this.onTap,
    required this.child,
  });

  final bool isDark;
  final ColorScheme scheme;
  final VoidCallback onTap;
  final Widget child;

  static const double _size = 44;

  @override
  Widget build(BuildContext context) {
    final iconColor = Colors.white.withValues(alpha: isDark ? 0.96 : 0.94);
    final borderColor = isDark
        ? AppTheme.editorialAccentColor(scheme).withValues(alpha: 0.34)
        : Colors.white.withValues(alpha: 0.42);
    final fill = isDark
        ? BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: 0.5),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.alphaBlend(
                  scheme.primary.withValues(alpha: 0.18),
                  Colors.black.withValues(alpha: 0.55),
                ),
                Color.alphaBlend(
                  scheme.onSurface.withValues(alpha: 0.08),
                  Colors.black.withValues(alpha: 0.42),
                ),
              ],
            ),
          )
        : BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.14),
            border: Border.all(color: borderColor, width: 0.5),
          );

    return SizedBox(
      width: _size,
      height: _size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.28),
              blurRadius: isDark ? 14 : 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipOval(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                child: Ink(
                  decoration: fill,
                  child: Center(
                    child: IconTheme(
                      data: IconThemeData(color: iconColor),
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FullscreenGalleryIndicator extends StatelessWidget {
  const _FullscreenGalleryIndicator({
    super.key,
    required this.currentIndex,
    required this.imageCount,
    required this.isDark,
    required this.scheme,
  });

  final int currentIndex;
  final int imageCount;
  final bool isDark;
  final ColorScheme scheme;

  static const double _dot = 5.5;
  static const double _pill = 18;
  static const double _h = 5.5;

  @override
  Widget build(BuildContext context) {
    final safe = currentIndex.clamp(0, imageCount - 1);
    final activeColor = isDark
        ? AppTheme.editorialAccentColor(scheme).withValues(alpha: 0.92)
        : scheme.primary.withValues(alpha: 0.9);
    final inactiveColor = Colors.white.withValues(alpha: isDark ? 0.34 : 0.38);
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

    final indicator = isDark
        ? DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: Colors.black.withValues(alpha: 0.42),
              border: Border.all(
                color: AppTheme.editorialAccentColor(
                  scheme,
                ).withValues(alpha: 0.22),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              child: track,
            ),
          )
        : track;

    return Semantics(
      label: '${safe + 1} of $imageCount',
      child: SizedBox(
        width: double.infinity,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: indicator,
        ),
      ),
    );
  }
}
