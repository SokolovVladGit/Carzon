import 'package:flutter/material.dart';

import 'compare_fly_to_tray_controller.dart';
import 'compare_fly_to_tray_overlay.dart';

/// Full-screen slot for the fly animation, painted above the compare tray.
class CompareFlyToTrayOverlaySlot extends StatefulWidget {
  const CompareFlyToTrayOverlaySlot({super.key, required this.controller});

  final CompareFlyToTrayController controller;

  @override
  State<CompareFlyToTrayOverlaySlot> createState() =>
      _CompareFlyToTrayOverlaySlotState();
}

class _CompareFlyToTrayOverlaySlotState
    extends State<CompareFlyToTrayOverlaySlot> {
  final GlobalKey _layerKey = GlobalKey(debugLabel: 'compare_fly_layer');

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final payload = widget.controller.active;
    if (payload == null) {
      return const SizedBox.shrink();
    }

    final gen = widget.controller.generation;

    return Positioned.fill(
      child: IgnorePointer(
        child: ClipRect(
          child: Stack(
            key: _layerKey,
            clipBehavior: Clip.hardEdge,
            children: [
              CompareFlyToTrayOverlay(
                key: ValueKey<int>(gen),
                layerKey: _layerKey,
                payload: payload,
                onComplete: () => widget.controller.complete(gen),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
