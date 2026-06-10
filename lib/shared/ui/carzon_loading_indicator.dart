import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'carzon_svg_color_mapper.dart';

/// Official branded RoadPulse Z loader for app loading states.
///
/// Intended to replace generic [CircularProgressIndicator] usage over time.
class CarzonLoadingIndicator extends StatefulWidget {
  const CarzonLoadingIndicator({
    super.key,
    this.size = 36,
    this.duration = const Duration(milliseconds: 1200),
    this.semanticLabel = 'Loading',
    this.autoplay = true,
    this.adaptToBrightness = true,
    this.darkModeTextColor = CarzonSvgColors.darkModeTextReplacement,
  });

  static const double nativeHeight = 170;
  static const double nativeWidth = 353;

  final double size;
  final Duration duration;
  final String semanticLabel;
  final bool autoplay;
  final bool adaptToBrightness;
  final Color darkModeTextColor;

  @override
  State<CarzonLoadingIndicator> createState() => _CarzonLoadingIndicatorState();
}

class _CarzonLoadingIndicatorState extends State<CarzonLoadingIndicator>
    with SingleTickerProviderStateMixin {
  static const String _assetZBottom = 'assets/animation/logo_z_bottom_road.svg';
  static const String _assetZTop = 'assets/animation/logo_z_top_7.svg';

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    if (widget.autoplay) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(CarzonLoadingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.duration != oldWidget.duration) {
      _controller.duration = widget.duration;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _slotWidth =>
      widget.size * CarzonLoadingIndicator.nativeWidth /
      CarzonLoadingIndicator.nativeHeight;

  double _px(double base) => base * (widget.size / 36.0);

  ColorMapper? _colorMapper(BuildContext context) {
    if (!widget.adaptToBrightness) {
      return null;
    }
    if (Theme.of(context).brightness != Brightness.dark) {
      return null;
    }
    return CarzonLogoDarkTextColorMapper(widget.darkModeTextColor);
  }

  Widget _svg(String asset, ColorMapper? colorMapper) {
    return SvgPicture.asset(
      asset,
      height: widget.size,
      width: _slotWidth,
      fit: BoxFit.fill,
      colorMapper: colorMapper,
    );
  }

  Widget _staticZ(ColorMapper? colorMapper) {
    return SizedBox(
      width: _slotWidth,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.hardEdge,
        children: [
          _svg(_assetZBottom, colorMapper),
          _svg(_assetZTop, colorMapper),
        ],
      ),
    );
  }

  Widget _animatedZ(ColorMapper? colorMapper) {
    return SizedBox(
      width: _slotWidth,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => _buildRoadPulse(colorMapper),
      ),
    );
  }

  double _loopValue({
    required double start,
    required double peak,
    required double startMs,
    required double peakMs,
    required double endMs,
    Curve curve = Curves.easeInOutCubic,
  }) {
    final t = _controller.value * widget.duration.inMilliseconds;
    if (t <= peakMs) {
      final local = (t - startMs) / (peakMs - startMs);
      return start + (peak - start) * curve.transform(local.clamp(0.0, 1.0));
    }
    final local = (t - peakMs) / (endMs - peakMs);
    return peak + (start - peak) * curve.transform(local.clamp(0.0, 1.0));
  }

  Widget _buildRoadPulse(ColorMapper? colorMapper) {
    final half = widget.duration.inMilliseconds / 2.0;
    final end = widget.duration.inMilliseconds.toDouble();
    final roadOpacity = _loopValue(
      start: 0.75,
      peak: 1.0,
      startMs: 0,
      peakMs: half,
      endMs: end,
    );
    final roadX = _loopValue(
      start: -1.0,
      peak: 1.0,
      startMs: 0,
      peakMs: half,
      endMs: end,
    );
    final roadY = _loopValue(
      start: 0.0,
      peak: 0.5,
      startMs: 0,
      peakMs: half,
      endMs: end,
    );
    final topOpacity = _loopValue(
      start: 0.92,
      peak: 1.0,
      startMs: 0,
      peakMs: half,
      endMs: end,
      curve: Curves.easeInOut,
    );
    final topScale = _loopValue(
      start: 0.985,
      peak: 1.015,
      startMs: 0,
      peakMs: half,
      endMs: end,
      curve: Curves.easeInOut,
    );

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.hardEdge,
      children: [
        Opacity(
          opacity: roadOpacity.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(_px(2.0) * roadX, _px(1.0) * roadY),
            transformHitTests: false,
            child: _svg(_assetZBottom, colorMapper),
          ),
        ),
        Opacity(
          opacity: topOpacity.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: topScale,
            alignment: Alignment.center,
            child: _svg(_assetZTop, colorMapper),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final animationsEnabled = !MediaQuery.disableAnimationsOf(context);
    final colorMapper = _colorMapper(context);

    final mark = animationsEnabled
        ? _animatedZ(colorMapper)
        : _staticZ(colorMapper);

    return Semantics(
      label: widget.semanticLabel,
      image: true,
      child: ExcludeSemantics(
        child: KeyedSubtree(
          key: Key(
            animationsEnabled
                ? 'carzonLoadingIndicatorAnimated'
                : 'carzonLoadingIndicatorStatic',
          ),
          child: mark,
        ),
      ),
    );
  }
}
