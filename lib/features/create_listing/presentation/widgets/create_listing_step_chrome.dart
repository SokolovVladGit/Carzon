import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../models/create_listing_step.dart';
import 'create_listing_compose_layout.dart';
import 'create_listing_vin_card.dart';
import 'premium_listing_controls.dart';

/// Stable Create Listing chrome. Title and progress stay put across steps.
/// The portrait background is painted behind the whole page, not here.
class CreateListingFlowShell extends StatelessWidget {
  const CreateListingFlowShell({
    super.key,
    required this.step,
    required this.submitting,
    required this.onStepBack,
    required this.onIdentityBack,
  });

  static const Key imageKey = ValueKey('create_listing_flow_hero_image');

  /// Portrait source, 941×1672. Subject in the top, ivory falloff below.
  static const String backgroundAsset = 'assets/bg/listing.png';

  /// Night leather portrait. Same crop family as [backgroundAsset].
  static const String darkBackgroundAsset = 'assets/bg/dark_bg.png';

  static const Color lightScaffoldFallback = Color(0xFFF3EBE3);
  static const Color darkScaffoldFallback = Color(0xFF14110F);

  static String backgroundAssetFor(Brightness brightness) {
    return brightness == Brightness.dark
        ? darkBackgroundAsset
        : backgroundAsset;
  }

  static Color scaffoldFallback(Brightness brightness) {
    return brightness == Brightness.dark
        ? darkScaffoldFallback
        : lightScaffoldFallback;
  }

  final CreateListingStep step;
  final bool submitting;
  final VoidCallback onStepBack;
  final VoidCallback onIdentityBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final top = MediaQuery.paddingOf(context).top;
    final screen = MediaQuery.sizeOf(context).height;
    // The fob and leather tag sit in the upper right. Start the title
    // just below that mass, on the seat's lighter falloff.
    final lead = (screen * 0.235).clamp(top + 96.0, top + 208.0);
    final light = theme.brightness == Brightness.light;
    final ink = light ? const Color(0xFF2C261F) : const Color(0xFFF3EBE3);
    final support = light ? const Color(0xFF514A43) : const Color(0xFFC4B5A4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: lead,
          child: Padding(
            padding: EdgeInsets.only(top: top, left: 4),
            child: Align(
              alignment: Alignment.topLeft,
              child: IconTheme(
                data: IconThemeData(color: ink),
                child: step == CreateListingStep.identity
                    ? IconButton(
                        key: CreateListingVinCard.backKey,
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).backButtonTooltip,
                        onPressed: submitting ? null : onIdentityBack,
                        icon: const BackButtonIcon(),
                      )
                    : IconButton(
                        key: const ValueKey('create_listing_step_back'),
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).backButtonTooltip,
                        onPressed: submitting ? null : onStepBack,
                        icon: const BackButtonIcon(),
                      ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 2),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (light)
                const Positioned(
                  left: -28,
                  right: -28,
                  top: -36,
                  bottom: -18,
                  child: IgnorePointer(
                    child: CustomPaint(
                      key: ValueKey('create_listing_upper_haze'),
                      painter: _UpperHazePainter(),
                      child: SizedBox.expand(),
                    ),
                  ),
                ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.createListingFlowTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: ink,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.35,
                      height: 1.15,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.createListingHeaderSubtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: support,
                      height: 1.3,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: CreateListingStepProgress(step: step),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class CreateListingStepProgress extends StatefulWidget {
  const CreateListingStepProgress({super.key, required this.step});

  final CreateListingStep step;

  @override
  State<CreateListingStepProgress> createState() =>
      _CreateListingStepProgressState();
}

class _CreateListingStepProgressState extends State<CreateListingStepProgress>
    with SingleTickerProviderStateMixin {
  static const Duration _duration = Duration(milliseconds: 420);

  late final AnimationController _motion;
  late final CurvedAnimation _curved;
  late double _from;

  @override
  void initState() {
    super.initState();
    _from = widget.step.index.toDouble();
    _motion = AnimationController(vsync: this, duration: _duration, value: 1);
    _curved = CurvedAnimation(parent: _motion, curve: Curves.easeInOutCubic);
  }

  @override
  void didUpdateWidget(CreateListingStepProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.step == widget.step) return;
    final displayed = _from + (oldWidget.step.index - _from) * _curved.value;
    _from = displayed;
    _motion.forward(from: 0);
  }

  double get _cursor {
    final end = widget.step.index.toDouble();
    return _from + (end - _from) * _curved.value;
  }

  @override
  void dispose() {
    _curved.dispose();
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AnimatedBuilder(
      animation: _curved,
      builder: (context, _) {
        final cursor = _cursor;
        return Column(
          children: [
            SizedBox(
              height: 32,
              child: CustomPaint(
                painter: _StepConnectorPainter(
                  cursor: cursor,
                  done: const Color(0xFF8F7D6A),
                  pending: Theme.of(context).brightness == Brightness.light
                      ? const Color(0xFFE6D9CC)
                      : const Color(0xFF6E6256),
                ),
                child: Row(
                  children: [
                    for (final step in CreateListingStep.values)
                      Expanded(
                        child: Center(
                          child: _StepMarker(
                            step: step,
                            cursor: cursor,
                            current: step == widget.step,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                for (final step in CreateListingStep.values)
                  Expanded(
                    child: _StepLabel(
                      text: _label(l10n, step),
                      active: step.index <= widget.step.index,
                      current: step == widget.step,
                      closing: step == CreateListingStep.review,
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  String _label(AppLocalizations l10n, CreateListingStep step) {
    return switch (step) {
      CreateListingStep.identity => l10n.createListingStepVin,
      CreateListingStep.photos => l10n.createListingStepPhotos,
      CreateListingStep.offer => l10n.createListingStepDeal,
      CreateListingStep.characteristics => l10n.createListingStepData,
      CreateListingStep.contact => l10n.createListingStepContacts,
      CreateListingStep.review => l10n.createListingStepDone,
    };
  }
}

class _StepMarker extends StatelessWidget {
  const _StepMarker({
    required this.step,
    required this.cursor,
    required this.current,
  });

  final CreateListingStep step;
  final double cursor;
  final bool current;

  static const _rose = Color(0xFF8C5E52);
  static const _blush = Color(0xFFF7E6DE);
  static const _ivory = Color(0xFFFFFCF8);
  static const _check = Color(0xFFFFFCF8);
  static const _capsuleRadius = 13.0;

  /// Line leads. The marker settles only after most of the connector is full.
  static const _settle = 0.68;

  @override
  Widget build(BuildContext context) {
    final index = step.index;
    final done = cursor >= index + _settle;
    final playhead = cursor < cursor.floor() + _settle
        ? cursor.floor()
        : cursor.ceil();
    final active = !done && index == playhead;
    final width = active ? 40.0 : 36.0;
    final height = active ? 24.0 : 22.0;

    final light = Theme.of(context).brightness == Brightness.light;
    return SizedBox(
      key: current
          ? const ValueKey('create_listing_step_marker_current')
          : ValueKey('create_listing_step_marker_${step.name}'),
      width: 40,
      height: 26,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeInOutCubic,
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_capsuleRadius),
            gradient: done
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFC9B59E), Color(0xFF8F7D6A)],
                  )
                : null,
            color: done
                ? null
                : active
                ? (light ? _blush : const Color(0xFF3A332C))
                : (light ? _ivory : const Color(0xFF2A2622)),
            border: Border.all(
              color: done
                  ? const Color(0xFF8F7D6A)
                  : active
                  ? (light ? const Color(0xFFD4B5A6) : const Color(0xFFC4B5A4))
                  : (light ? const Color(0xFFE7DDD2) : const Color(0xFF8F7D6A)),
              width: 1,
            ),
            boxShadow: done
                ? const [
                    BoxShadow(
                      color: Color(0x408F7D6A),
                      blurRadius: 12,
                      spreadRadius: 0.2,
                    ),
                  ]
                : active && light
                ? const [
                    BoxShadow(
                      color: Color(0x40D4B5A6),
                      blurRadius: 10,
                      spreadRadius: 0.3,
                    ),
                  ]
                : null,
          ),
          child: done
              ? const Icon(Icons.check_rounded, size: 13, color: _check)
              : active
              ? Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1,
                      fontWeight: FontWeight.w600,
                      color: light ? _rose : const Color(0xFFF3EBE3),
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

class _StepLabel extends StatelessWidget {
  const _StepLabel({
    required this.text,
    required this.active,
    required this.current,
    required this.closing,
  });

  final String text;
  final bool active;
  final bool current;
  final bool closing;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final light = Theme.of(context).brightness == Brightness.light;
    final color = light
        ? (closing
              ? (current ? const Color(0xFF241F1A) : const Color(0xFF362C24))
              : current
              ? const Color(0xFF2C261F)
              : active
              ? const Color(0xFF64584A)
              : const Color(0xFF453E37))
        : (closing
              ? (current ? const Color(0xFFF7F1EA) : const Color(0xFFD8CBBC))
              : current
              ? const Color(0xFFF3EBE3)
              : active
              ? const Color(0xFFE4D5C6)
              : const Color(0xFFC4B5A4));
    return SizedBox(
      height: scaler.scale(14),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          text,
          maxLines: 1,
          softWrap: false,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: closing ? 12 : 11,
            height: 1.1,
            fontWeight: closing
                ? FontWeight.w700
                : current
                ? FontWeight.w600
                : FontWeight.w500,
            letterSpacing: closing ? 0.15 : 0.1,
            color: color,
            shadows: [
              Shadow(
                color: light
                    ? const Color(0x2EFFF8F2)
                    : const Color(0x66140F0C),
                blurRadius: light ? 2 : 2.5,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepConnectorPainter extends CustomPainter {
  const _StepConnectorPainter({
    required this.cursor,
    required this.done,
    required this.pending,
  });

  final double cursor;
  final Color done;
  final Color pending;

  @override
  void paint(Canvas canvas, Size size) {
    const count = 6;
    final slot = size.width / count;
    final y = size.height / 2;
    final paint = Paint()
      ..strokeWidth = 1.15
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < count - 1; i++) {
      final start = slot * i + slot / 2 + 22;
      final end = slot * (i + 1) + slot / 2 - 22;
      if (end - start < 2) continue;
      paint.color = pending;
      canvas.drawLine(Offset(start, y), Offset(end, y), paint);
      final t = (cursor - i).clamp(0.0, 1.0);
      if (t <= 0) continue;
      paint.color = done;
      canvas.drawLine(
        Offset(start, y),
        Offset(start + (end - start) * t, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StepConnectorPainter oldDelegate) {
    return oldDelegate.cursor != cursor ||
        oldDelegate.done != done ||
        oldDelegate.pending != pending;
  }
}

/// Faint ivory mist under the title and subtitle.
/// Kept off the right side so the last progress label is not washed out.
class _UpperHazePainter extends CustomPainter {
  const _UpperHazePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final body = Paint()
      ..color = const Color(0x38FFF8F2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 26);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.34, size.height * 0.28),
        width: size.width * 0.72,
        height: size.height * 0.52,
      ),
      body,
    );
  }

  @override
  bool shouldRepaint(_UpperHazePainter oldDelegate) => false;
}

class CreateListingStepFooter extends StatelessWidget {
  const CreateListingStepFooter({
    super.key,
    required this.step,
    required this.submitting,
    this.continueBusy = false,
    required this.onContinue,
    required this.onPublish,
    required this.l10n,
    required this.theme,
  });

  final CreateListingStep step;
  final bool submitting;
  final bool continueBusy;
  final VoidCallback onContinue;
  final VoidCallback onPublish;
  final AppLocalizations l10n;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final review = step == CreateListingStep.review;
    return Material(
      type: MaterialType.transparency,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 6, 16, bottom + 10),
        child: review
            ? PremiumPublishActionButton(
                theme: theme,
                l10n: l10n,
                submitting: submitting,
                onPressed: onPublish,
              )
            : FilledButton(
                key: const ValueKey('create_listing_step_continue'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: kCreateListingActiveFill,
                  foregroundColor: kCreateListingActiveForeground,
                  side: theme.brightness == Brightness.dark
                      ? const BorderSide(color: Color(0x47C4B5A4))
                      : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      kCreateListingPublishRadius,
                    ),
                  ),
                ),
                onPressed: submitting || continueBusy ? null : onContinue,
                child: continueBusy
                    ? Row(
                        key: const ValueKey(
                          'create_listing_step_continue_pending',
                        ),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: kCreateListingActiveForeground,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              l10n.createListingSmartFillLoading,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      )
                    : Text(l10n.createListingStepContinue),
              ),
      ),
    );
  }
}
