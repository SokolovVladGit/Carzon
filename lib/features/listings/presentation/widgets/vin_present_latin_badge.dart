import 'package:flutter/material.dart';

/// Compact “VIN” mark: Latin [V] in green (check-like), tight [IN] — not verification.
class VinPresentLatinBadge extends StatelessWidget {
  const VinPresentLatinBadge({
    super.key,
    this.heroSize = false,
    this.compact = false,
    this.cardStamp = false,
  });

  /// Buyer VIN report hero / sheet header.
  final bool heroSize;

  /// Legacy alias — maps to [VinLatinMarkScale.detail].
  final bool compact;

  /// Feed listing-card corner stamp.
  final bool cardStamp;

  static const Color vinPresentGreen = Color(0xFF1F9D57);
  static const Color vinPresentGreenDark = Color(0xFF3DB87A);

  VinLatinMarkScale get _scale {
    if (cardStamp) return VinLatinMarkScale.card;
    if (heroSize) return VinLatinMarkScale.report;
    return VinLatinMarkScale.detail;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final green = isDark ? vinPresentGreenDark : vinPresentGreen;
    return _VinPresentLatinMark(green: green, isDark: isDark, scale: _scale);
  }
}

/// Neutral VIN mark for non-success states (not verification).
class VinNeutralLatinBadge extends StatelessWidget {
  const VinNeutralLatinBadge({super.key, this.heroSize = false});

  final bool heroSize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scale = heroSize
        ? VinLatinMarkScale.report
        : VinLatinMarkScale.detail;
    return _VinNeutralLatinMark(scheme: scheme, isDark: isDark, scale: scale);
  }
}

/// Shared size tokens for the unified “VIN” mark.
enum VinLatinMarkScale { card, detail, report }

class _VinLatinMarkMetrics {
  const _VinLatinMarkMetrics({
    required this.vSize,
    required this.inSize,
    required this.padLeft,
    required this.padRight,
    required this.padTop,
    required this.padBottom,
    required this.radius,
    required this.fillAlphaLight,
    required this.fillAlphaDark,
    required this.borderAlphaLight,
    required this.borderAlphaDark,
    required this.inAlphaLight,
    required this.inAlphaDark,
    required this.vLetterSpacing,
    required this.inLetterSpacing,
  });

  final double vSize;
  final double inSize;
  final double padLeft;
  final double padRight;
  final double padTop;
  final double padBottom;
  final double radius;
  final double fillAlphaLight;
  final double fillAlphaDark;
  final double borderAlphaLight;
  final double borderAlphaDark;
  final double inAlphaLight;
  final double inAlphaDark;
  final double vLetterSpacing;
  final double inLetterSpacing;

  static const card = _VinLatinMarkMetrics(
    vSize: 12.5,
    inSize: 8.5,
    padLeft: 5.5,
    padRight: 6,
    padTop: 2.5,
    padBottom: 2.5,
    radius: 7,
    fillAlphaLight: 0.07,
    fillAlphaDark: 0.10,
    borderAlphaLight: 0.20,
    borderAlphaDark: 0.24,
    inAlphaLight: 0.72,
    inAlphaDark: 0.78,
    vLetterSpacing: -0.7,
    inLetterSpacing: -0.2,
  );

  static const detail = _VinLatinMarkMetrics(
    vSize: 14.5,
    inSize: 9.5,
    padLeft: 7,
    padRight: 8,
    padTop: 4,
    padBottom: 4,
    radius: 8,
    fillAlphaLight: 0.09,
    fillAlphaDark: 0.12,
    borderAlphaLight: 0.24,
    borderAlphaDark: 0.28,
    inAlphaLight: 0.76,
    inAlphaDark: 0.82,
    vLetterSpacing: -0.85,
    inLetterSpacing: -0.28,
  );

  static const report = _VinLatinMarkMetrics(
    vSize: 16.5,
    inSize: 11,
    padLeft: 9,
    padRight: 10,
    padTop: 5,
    padBottom: 5,
    radius: 10,
    fillAlphaLight: 0.10,
    fillAlphaDark: 0.13,
    borderAlphaLight: 0.26,
    borderAlphaDark: 0.30,
    inAlphaLight: 0.80,
    inAlphaDark: 0.86,
    vLetterSpacing: -1.0,
    inLetterSpacing: -0.32,
  );

  static _VinLatinMarkMetrics forScale(VinLatinMarkScale scale) =>
      switch (scale) {
        VinLatinMarkScale.card => card,
        VinLatinMarkScale.detail => detail,
        VinLatinMarkScale.report => report,
      };
}

class _VinPresentLatinMark extends StatelessWidget {
  const _VinPresentLatinMark({
    required this.green,
    required this.isDark,
    required this.scale,
  });

  final Color green;
  final bool isDark;
  final VinLatinMarkScale scale;

  @override
  Widget build(BuildContext context) {
    final m = _VinLatinMarkMetrics.forScale(scale);
    final inGreen = green.withValues(
      alpha: isDark ? m.inAlphaDark : m.inAlphaLight,
    );

    return DecoratedBox(
      key: const ValueKey('vin_present_latin_badge'),
      decoration: BoxDecoration(
        color: green.withValues(
          alpha: isDark ? m.fillAlphaDark : m.fillAlphaLight,
        ),
        borderRadius: BorderRadius.circular(m.radius),
        border: Border.all(
          color: green.withValues(
            alpha: isDark ? m.borderAlphaDark : m.borderAlphaLight,
          ),
          width: 0.75,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          m.padLeft,
          m.padTop,
          m.padRight,
          m.padBottom,
        ),
        child: Text.rich(
          TextSpan(
            style: const TextStyle(height: 1),
            children: [
              WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: Text(
                  'V',
                  key: const ValueKey('vin_present_latin_badge_v'),
                  style: TextStyle(
                    fontSize: m.vSize,
                    fontWeight: FontWeight.w900,
                    letterSpacing: m.vLetterSpacing,
                    color: green,
                    height: 1,
                  ),
                ),
              ),
              TextSpan(
                text: 'IN',
                style: TextStyle(
                  fontSize: m.inSize,
                  fontWeight: FontWeight.w800,
                  letterSpacing: m.inLetterSpacing,
                  color: inGreen,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VinNeutralLatinMark extends StatelessWidget {
  const _VinNeutralLatinMark({
    required this.scheme,
    required this.isDark,
    required this.scale,
  });

  final ColorScheme scheme;
  final bool isDark;
  final VinLatinMarkScale scale;

  @override
  Widget build(BuildContext context) {
    final m = _VinLatinMarkMetrics.forScale(scale);
    final muted = scheme.onSurfaceVariant.withValues(alpha: 0.58);
    final inMuted = muted.withValues(alpha: 0.82);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh.withValues(
          alpha: isDark ? 0.38 : 0.32,
        ),
        borderRadius: BorderRadius.circular(m.radius),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: isDark ? 0.30 : 0.34),
          width: 0.75,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          m.padLeft,
          m.padTop,
          m.padRight,
          m.padBottom,
        ),
        child: Text.rich(
          TextSpan(
            style: const TextStyle(height: 1),
            children: [
              TextSpan(
                text: 'V',
                style: TextStyle(
                  fontSize: m.vSize,
                  fontWeight: FontWeight.w800,
                  letterSpacing: m.vLetterSpacing,
                  color: muted,
                  height: 1,
                ),
              ),
              TextSpan(
                text: 'IN',
                style: TextStyle(
                  fontSize: m.inSize,
                  fontWeight: FontWeight.w700,
                  letterSpacing: m.inLetterSpacing,
                  color: inMuted,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
