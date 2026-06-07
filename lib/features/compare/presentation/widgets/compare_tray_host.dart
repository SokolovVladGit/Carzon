import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../cubit/compare_cubit.dart';
import '../cubit/compare_state.dart';
import '../utils/compare_navigation.dart';
import '../utils/compare_tray_layout.dart';
import '../utils/compare_tray_visual_policy.dart';
import 'compare_floating_tray.dart';
import 'compare_fly_to_tray_controller.dart';
import 'compare_fly_to_tray_layer.dart' show CompareFlyToTrayOverlaySlot;
import 'compare_tray_dock_shield.dart' show CompareTrayCapsuleBackplate;
import 'compare_tray_feedback_controller.dart';
import 'compare_tray_feedback_scope.dart';
import 'compare_tray_limit_feedback.dart';

/// Root overlay that shows the floating compare tray above routed content.
class CompareTrayHost extends StatefulWidget {
  const CompareTrayHost({
    super.key,
    required this.router,
    required this.child,
    this.flyController,
    this.feedbackController,
    this.visualPolicy = CompareTrayVisualPolicy.production,
  });

  final GoRouter router;
  final Widget? child;

  /// Optional override for tests; production uses [sl].
  final CompareFlyToTrayController? flyController;

  /// Optional override for tests; production uses [sl].
  final CompareTrayFeedbackController? feedbackController;

  /// Audit toggles (fly off / solid thumbs). Production uses [CompareTrayVisualPolicy.production].
  final CompareTrayVisualPolicy visualPolicy;

  @override
  State<CompareTrayHost> createState() => _CompareTrayHostState();
}

class _CompareTrayHostState extends State<CompareTrayHost> {
  late String _location;
  bool _trayWasVisible = false;

  CompareFlyToTrayController _flyController() =>
      widget.flyController ?? sl<CompareFlyToTrayController>();

  @override
  void initState() {
    super.initState();
    _location = _readLocation();
    widget.router.routerDelegate.addListener(_onRouteChanged);
  }

  @override
  void dispose() {
    widget.router.routerDelegate.removeListener(_onRouteChanged);
    super.dispose();
  }

  void _onRouteChanged() {
    final next = _readLocation();
    if (next == _location) return;
    _location = next;
    _flyController().cancel();
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  void _onCompareStateChanged(CompareState state) {
    final hiddenByRoute = compareTrayHiddenForRoute(_readLocation());
    final trayVisible = state.count >= 1 && !hiddenByRoute;
    if (_trayWasVisible && !trayVisible) {
      _flyController().cancel();
    }
    _trayWasVisible = trayVisible;
  }

  String _readLocation() {
    final configuration = widget.router.routerDelegate.currentConfiguration;
    if (configuration.matches.isEmpty) {
      return configuration.uri.toString();
    }
    final lastMatch = configuration.last;
    final uri = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches.uri
        : configuration.uri;
    return uri.toString();
  }

  @override
  Widget build(BuildContext context) {
    final flyController = _flyController();
    final feedbackController =
        widget.feedbackController ?? sl<CompareTrayFeedbackController>();
    final policy = widget.visualPolicy;
    final location = _readLocation();

    return CompareTrayFeedbackScope(
      controller: feedbackController,
      child: BlocListener<CompareCubit, CompareState>(
        listener: (context, state) => _onCompareStateChanged(state),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (widget.child != null) widget.child!,
            _CompareTrayOverlay(
              location: location,
              flyController: flyController,
              feedbackController: feedbackController,
              visualPolicy: policy,
              onOpenCompare: () => openCompareFromTray(widget.router),
            ),
            if (policy.renderFlyOverlay)
              CompareFlyToTrayOverlaySlot(controller: flyController),
          ],
        ),
      ),
    );
  }
}

class _CompareTrayOverlay extends StatelessWidget {
  const _CompareTrayOverlay({
    required this.location,
    required this.flyController,
    required this.feedbackController,
    required this.visualPolicy,
    required this.onOpenCompare,
  });

  final String location;
  final CompareFlyToTrayController flyController;
  final CompareTrayFeedbackController feedbackController;
  final CompareTrayVisualPolicy visualPolicy;
  final VoidCallback onOpenCompare;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: feedbackController,
      builder: (context, _) {
        return BlocBuilder<CompareCubit, CompareState>(
          buildWhen: (previous, current) =>
              previous.items != current.items ||
              previous.count != current.count,
          builder: (context, state) {
            final hiddenByRoute = compareTrayHiddenForRoute(location);
            final hasItems = state.count >= 1;
            final showMaxLimit = feedbackController.isShowingMaxLimit;
            final showNormalTray = hasItems && !hiddenByRoute && !showMaxLimit;
            final showLimitAtTray = showMaxLimit && hasItems && !hiddenByRoute;
            final showPositioned = showNormalTray || showLimitAtTray;

            if (!showPositioned) {
              return const SizedBox.shrink();
            }

            final theme = Theme.of(context);
            final scheme = theme.colorScheme;
            final isDark = theme.brightness == Brightness.dark;
            final bottom = compareTrayBottomInset(context, location);
            final surface = isDark ? scheme.surfaceContainerHigh : Colors.white;
            final shadowColor = isDark
                ? Colors.black.withValues(alpha: 0.38)
                : Colors.black.withValues(alpha: 0.08);

            final capsuleChild = showLimitAtTray
                ? const CompareTrayLimitFeedback()
                : CompareFloatingTray(
                    items: state.items,
                    onOpenCompare: onOpenCompare,
                    solidThumbnails: visualPolicy.solidTrayThumbnails,
                    showDropShadow: false,
                  );

            return Positioned(
              left: CompareFloatingTray.horizontalMargin,
              right: CompareFloatingTray.horizontalMargin,
              bottom: bottom,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: shadowColor,
                      blurRadius: 12,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CompareTrayCapsuleBackplate(
                  surfaceColor: surface,
                  child: KeyedSubtree(
                    key: flyController.trayFlyTargetKey,
                    child: capsuleChild,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
