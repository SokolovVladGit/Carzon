import 'package:flutter/material.dart';

import '../utils/compare_fly_to_tray_logic.dart';
import 'compare_fly_to_tray_controller.dart';

/// Flying thumbnail rendered above routed content and the compare tray.
class CompareFlyToTrayOverlay extends StatefulWidget {
  const CompareFlyToTrayOverlay({
    super.key,
    required this.layerKey,
    required this.payload,
    required this.onComplete,
  });

  final GlobalKey layerKey;
  final CompareFlyAnimationPayload payload;
  final VoidCallback onComplete;

  static const Duration duration = Duration(milliseconds: 500);

  @override
  State<CompareFlyToTrayOverlay> createState() =>
      _CompareFlyToTrayOverlayState();
}

class _CompareFlyToTrayOverlayState extends State<CompareFlyToTrayOverlay>
    with SingleTickerProviderStateMixin {
  static const int _maxLayerLayoutAttempts = 8;

  late final AnimationController _controller;
  bool _completed = false;
  int _layerLayoutAttempts = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: CompareFlyToTrayOverlay.duration,
    );
    _controller.addListener(_onAnimationTick);
    _controller.addStatusListener(_onStatus);
    _controller.forward();
  }

  void _finishAnimation() {
    if (_completed) return;
    _completed = true;
    if (_controller.isAnimating) {
      _controller.stop();
    }
    widget.onComplete();
    if (mounted) setState(() {});
  }

  void _onAnimationTick() {
    if (_completed) return;
    final t = _controller.value;
    if (t >= 1.0 || compareFlyOpacityAt(t) <= 0) {
      _finishAnimation();
    }
  }

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || _completed) return;
    _finishAnimation();
  }

  @override
  void dispose() {
    _controller.removeListener(_onAnimationTick);
    _controller.removeStatusListener(_onStatus);
    _controller.dispose();
    super.dispose();
  }

  Rect? _layerGlobalOrigin() {
    final box = widget.layerKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  @override
  Widget build(BuildContext context) {
    if (_completed) {
      return const SizedBox.shrink();
    }

    final layerOrigin = _layerGlobalOrigin();
    if (layerOrigin == null) {
      if (_layerLayoutAttempts < _maxLayerLayoutAttempts) {
        _layerLayoutAttempts++;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_completed) setState(() {});
        });
      } else if (!_completed) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_completed) _finishAnimation();
        });
      }
      return const SizedBox.shrink();
    }

    final traySlot = widget.payload.traySlotRect;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        if (compareFlyOpacityAt(t) <= 0) {
          return const SizedBox.shrink();
        }

        final global = compareFlyThumbRectAt(
          start: widget.payload.sourceRect,
          traySlot: traySlot,
          t: t,
        );
        final local = global.shift(-layerOrigin.topLeft);
        final opacity = compareFlyOpacityAt(t);
        if (opacity <= 0 || global.width <= 1 || global.height <= 1) {
          return const SizedBox.shrink();
        }

        return Positioned(
          left: local.left,
          top: local.top,
          width: local.width,
          height: local.height,
          child: Opacity(
            opacity: opacity,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _FlyingThumb(imageUrl: widget.payload.imageUrl),
            ),
          ),
        );
      },
    );
  }
}

/// Fixed-size fly thumbnail (matches tray thumb sizing; no [ListingCoverImage]).
class _FlyingThumb extends StatelessWidget {
  const _FlyingThumb({required this.imageUrl});

  final String? imageUrl;

  static const double size = 44;

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
      width: size,
      height: size,
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
