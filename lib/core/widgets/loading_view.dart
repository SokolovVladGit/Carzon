import 'package:flutter/material.dart';

import '../../shared/ui/carzon_loading_indicator.dart';

/// Centered full-area loading state using the branded RoadPulse Z loader.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CarzonLoadingIndicator());
  }
}
