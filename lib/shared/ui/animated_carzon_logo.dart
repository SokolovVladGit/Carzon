import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'carzon_svg_color_mapper.dart';

/// Split-SVG animated Carzon wordmark (Z-first assembly draft).
class AnimatedCarzonLogo extends StatefulWidget {
  const AnimatedCarzonLogo({
    super.key,
    this.height = 48,
    this.width,
    this.autoplay = true,
    this.repeat = false,
    this.duration = const Duration(milliseconds: 1150),
    this.semanticLabel = 'Carzon',
    this.adaptToBrightness = true,
    this.darkModeTextColor = CarzonSvgColors.darkModeTextReplacement,
    this.replayToken = 0,
  });

  static const double nativeLetterHeight = 170;

  final double height;
  final double? width;
  final bool autoplay;
  final bool repeat;
  final Duration duration;
  final String semanticLabel;
  final bool adaptToBrightness;
  final Color darkModeTextColor;
  final int replayToken;

  @override
  State<AnimatedCarzonLogo> createState() => _AnimatedCarzonLogoState();
}

class _AnimatedCarzonLogoState extends State<AnimatedCarzonLogo>
    with SingleTickerProviderStateMixin {
  static const String _assetC = 'assets/animation/logo_c.svg';
  static const String _assetA = 'assets/animation/logo_a.svg';
  static const String _assetR = 'assets/animation/logo_r.svg';
  static const String _assetO = 'assets/animation/logo_o.svg';
  static const String _assetN = 'assets/animation/logo_n.svg';
  static const String _assetZBottom = 'assets/animation/logo_z_bottom_road.svg';
  static const String _assetZTop = 'assets/animation/logo_z_top_7.svg';

  late final AnimationController _controller;
  late Animation<double> _bottomRoadOpacity;
  late Animation<Offset> _bottomRoadSlide;
  late Animation<double> _topSevenOpacity;
  late Animation<Offset> _topSevenSlide;
  late Animation<double> _zPulseScale;
  late final List<Animation<double>> _letterOpacities;
  late final List<Animation<Offset>> _letterSlides;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _bindAnimations();
    _controller.addStatusListener(_onStatus);
    if (widget.autoplay) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(AnimatedCarzonLogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.duration != oldWidget.duration) {
      _controller.duration = widget.duration;
      _bindAnimations();
    }
    if (widget.replayToken != oldWidget.replayToken && widget.autoplay) {
      _controller.forward(from: 0);
    }
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && widget.repeat && mounted) {
      Future<void>.delayed(const Duration(milliseconds: 450), () {
        if (mounted && widget.repeat) {
          _controller.forward(from: 0);
        }
      });
    }
  }

  void _bindAnimations() {
    final totalMs = widget.duration.inMilliseconds.toDouble();

    Interval interval(double startMs, double endMs, {Curve curve = Curves.linear}) {
      return Interval(
        (startMs / totalMs).clamp(0.0, 1.0),
        (endMs / totalMs).clamp(0.0, 1.0),
        curve: curve,
      );
    }

    _bottomRoadOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: interval(0, 205, curve: Curves.fastOutSlowIn),
      ),
    );
    _bottomRoadSlide = Tween<Offset>(
      begin: const Offset(-0.09, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: interval(0, 205, curve: Curves.fastOutSlowIn),
      ),
    );

    _topSevenOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: interval(125, 355, curve: Curves.easeOut),
      ),
    );
    _topSevenSlide = Tween<Offset>(
      begin: const Offset(0.1, -0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: interval(125, 355, curve: Curves.fastOutSlowIn),
      ),
    );

    _zPulseScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.96, end: 1.04),
        weight: 55,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.04, end: 1.0),
        weight: 45,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: interval(310, 475, curve: Curves.easeInOutCubic),
      ),
    );

    const letterStarts = [390.0, 440.0, 490.0, 630.0, 680.0];
    const letterEnds = [610.0, 660.0, 710.0, 830.0, 870.0];
    _letterOpacities = List<Animation<double>>.generate(5, (index) {
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _controller,
          curve: interval(
            letterStarts[index],
            letterEnds[index],
            curve: Curves.easeOut,
          ),
        ),
      );
    });
    _letterSlides = List<Animation<Offset>>.generate(5, (index) {
      final fromLeft = index < 3;
      return Tween<Offset>(
        begin: Offset(fromLeft ? -0.18 : 0.18, 0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: interval(
            letterStarts[index],
            letterEnds[index],
            curve: Curves.easeOutCubic,
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onStatus);
    _controller.dispose();
    super.dispose();
  }

  ColorMapper? _colorMapper(BuildContext context) {
    if (!widget.adaptToBrightness) {
      return null;
    }
    if (Theme.of(context).brightness != Brightness.dark) {
      return null;
    }
    return CarzonLogoDarkTextColorMapper(widget.darkModeTextColor);
  }

  double _slotWidth(double nativeWidth, double height) {
    return nativeWidth / AnimatedCarzonLogo.nativeLetterHeight * height;
  }

  /// Horizontal gap between letter slots, scaled from [widget.height].
  Widget _letterGap(double factor) => SizedBox(width: widget.height * factor);

  static const double _gapNormal = 0.04;
  static const double _gapAfterA = 0.055;
  static const double _gapAfterO = 0.0675;

  Widget _svgLayer({
    required String asset,
    required double height,
    required double width,
    required ColorMapper? colorMapper,
  }) {
    return SvgPicture.asset(
      asset,
      height: height,
      width: width,
      fit: BoxFit.fill,
      colorMapper: colorMapper,
    );
  }

  Widget _animatedLayer({
    required Widget child,
    required Animation<double> opacity,
    required Animation<Offset> slide,
    required double slideExtent,
    Animation<double>? scale,
  }) {
    return AnimatedBuilder(
      animation: Listenable.merge([opacity, slide, ?scale]),
      builder: (context, _) {
        Widget layered = child;
        if (scale != null) {
          layered = Transform.scale(
            scale: scale.value,
            alignment: Alignment.center,
            child: layered,
          );
        }
        return Opacity(
          opacity: opacity.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(
              slide.value.dx * slideExtent,
              slide.value.dy * widget.height,
            ),
            transformHitTests: false,
            child: layered,
          ),
        );
      },
    );
  }

  Widget _letterSlot({
    required String asset,
    required double nativeWidth,
    required Animation<double> opacity,
    required Animation<Offset> slide,
    required ColorMapper? colorMapper,
  }) {
    final slotWidth = _slotWidth(nativeWidth, widget.height);
    return SizedBox(
      width: slotWidth,
      height: widget.height,
      child: _animatedLayer(
        opacity: opacity,
        slide: slide,
        slideExtent: slotWidth,
        child: _svgLayer(
          asset: asset,
          height: widget.height,
          width: slotWidth,
          colorMapper: colorMapper,
        ),
      ),
    );
  }

  Widget _zSlot(ColorMapper? colorMapper) {
    final slotWidth = _slotWidth(353, widget.height);
    return SizedBox(
      width: slotWidth,
      height: widget.height,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          _animatedLayer(
            opacity: _bottomRoadOpacity,
            slide: _bottomRoadSlide,
            slideExtent: slotWidth,
            child: _svgLayer(
              asset: _assetZBottom,
              height: widget.height,
              width: slotWidth,
              colorMapper: colorMapper,
            ),
          ),
          _animatedLayer(
            opacity: _topSevenOpacity,
            slide: _topSevenSlide,
            slideExtent: slotWidth,
            scale: _zPulseScale,
            child: _svgLayer(
              asset: _assetZTop,
              height: widget.height,
              width: slotWidth,
              colorMapper: colorMapper,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorMapper = _colorMapper(context);
    final wordmark = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _letterSlot(
          asset: _assetC,
          nativeWidth: 231,
          opacity: _letterOpacities[0],
          slide: _letterSlides[0],
          colorMapper: colorMapper,
        ),
        _letterGap(_gapNormal),
        _letterSlot(
          asset: _assetA,
          nativeWidth: 245,
          opacity: _letterOpacities[1],
          slide: _letterSlides[1],
          colorMapper: colorMapper,
        ),
        _letterGap(_gapAfterA),
        _letterSlot(
          asset: _assetR,
          nativeWidth: 237,
          opacity: _letterOpacities[2],
          slide: _letterSlides[2],
          colorMapper: colorMapper,
        ),
        _letterGap(_gapNormal),
        _zSlot(colorMapper),
        _letterGap(_gapNormal),
        _letterSlot(
          asset: _assetO,
          nativeWidth: 236,
          opacity: _letterOpacities[3],
          slide: _letterSlides[3],
          colorMapper: colorMapper,
        ),
        _letterGap(_gapAfterO),
        _letterSlot(
          asset: _assetN,
          nativeWidth: 220,
          opacity: _letterOpacities[4],
          slide: _letterSlides[4],
          colorMapper: colorMapper,
        ),
      ],
    );

    Widget content = wordmark;
    if (widget.width != null) {
      content = SizedBox(
        width: widget.width,
        height: widget.height,
        child: FittedBox(
          fit: BoxFit.contain,
          alignment: Alignment.center,
          child: wordmark,
        ),
      );
    } else {
      content = SizedBox(height: widget.height, child: wordmark);
    }

    return Semantics(
      label: widget.semanticLabel,
      image: true,
      child: ExcludeSemantics(child: content),
    );
  }
}
