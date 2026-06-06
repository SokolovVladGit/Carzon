import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Editorial settings surface for notification settings sections.
class NotificationSettingsSectionCard extends StatelessWidget {
  const NotificationSettingsSectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: AppTheme.filterAlertManagementSurface(
        scheme,
        borderRadius: 16,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
