import 'package:flutter/material.dart';

import '../models/create_listing_step.dart';

/// One mounted piece of a step. Several fragments may share a step.
///
/// The stage keeps every fragment mounted. Only the active step is painted,
/// with a short slide/fade while the previous step is still in the tree.
class CreateListingStepFragment extends StatelessWidget {
  const CreateListingStepFragment({
    super.key,
    required this.step,
    required this.child,
  });

  final CreateListingStep step;
  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

class CreateListingStepStage extends StatefulWidget {
  const CreateListingStepStage({
    super.key,
    required this.step,
    required this.revealAll,
    required this.fragments,
  });

  final CreateListingStep step;
  final bool revealAll;
  final List<CreateListingStepFragment> fragments;

  @override
  State<CreateListingStepStage> createState() => _CreateListingStepStageState();
}

class _CreateListingStepStageState extends State<CreateListingStepStage>
    with SingleTickerProviderStateMixin {
  static const Duration _duration = Duration(milliseconds: 320);

  late final AnimationController _motion;
  late final CurvedAnimation _curved;
  late final List<GlobalKey> _paneKeys;
  CreateListingStep? _outgoing;
  int _direction = 1;

  @override
  void initState() {
    super.initState();
    _motion = AnimationController(vsync: this, duration: _duration, value: 1);
    _curved = CurvedAnimation(parent: _motion, curve: Curves.easeInOutCubic);
    _paneKeys = List<GlobalKey>.generate(
      CreateListingStepX.count,
      (_) => GlobalKey(),
    );
    _motion.addStatusListener(_onMotionStatus);
  }

  void _onMotionStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || _outgoing == null) return;
    if (!mounted) return;
    setState(() => _outgoing = null);
  }

  @override
  void didUpdateWidget(CreateListingStepStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.revealAll || oldWidget.step == widget.step) return;
    _outgoing = oldWidget.step;
    _direction = widget.step.index >= oldWidget.step.index ? 1 : -1;
    _motion.forward(from: 0);
  }

  @override
  void dispose() {
    _motion.removeStatusListener(_onMotionStatus);
    _curved.dispose();
    _motion.dispose();
    super.dispose();
  }

  Widget _spaced(List<Widget> parts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < parts.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          parts[i],
        ],
      ],
    );
  }

  List<Widget> _parts(CreateListingStep step) {
    return [
      for (final fragment in widget.fragments)
        if (fragment.step == step) fragment.child,
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (widget.revealAll) {
      return _spaced([for (final fragment in widget.fragments) fragment.child]);
    }

    return AnimatedSize(
      duration: _duration,
      curve: Curves.easeInOutCubic,
      alignment: Alignment.topCenter,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.hardEdge,
        children: [
          for (final step in CreateListingStep.values) _pane(step),
        ],
      ),
    );
  }

  Widget _pane(CreateListingStep step) {
    final active = step == widget.step;
    final exiting = _outgoing == step && step != widget.step;
    final pane = KeyedSubtree(
      key: _paneKeys[step.index],
      child: _spaced(_parts(step)),
    );

    if (!active && !exiting) {
      return Offstage(offstage: true, child: pane);
    }

    if (_outgoing == null) return pane;

    final dx = exiting ? -0.12 * _direction : 0.12 * _direction;
    return AnimatedBuilder(
      animation: _curved,
      builder: (context, child) {
        final t = _curved.value;
        final offset = exiting ? dx * t : dx * (1 - t);
        final opacity = exiting ? (1 - t) : t;
        return IgnorePointer(
          ignoring: exiting,
          child: Opacity(
            opacity: opacity.clamp(0, 1),
            child: FractionalTranslation(
              translation: Offset(offset, 0),
              child: child,
            ),
          ),
        );
      },
      child: pane,
    );
  }
}
