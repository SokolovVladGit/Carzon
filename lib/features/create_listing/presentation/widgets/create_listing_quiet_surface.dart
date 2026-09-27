import 'package:flutter/material.dart';

import 'create_listing_compose_layout.dart';

/// Compact bordered surface for Create Listing. No icon header.
class CreateListingQuietSurface extends StatelessWidget {
  const CreateListingQuietSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(12, 10, 12, 10),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: createListingSectionSurfaceDecoration(Theme.of(context)),
      child: Padding(padding: padding, child: child),
    );
  }
}

TextStyle? createListingQuietTitleStyle(ThemeData theme) {
  return theme.textTheme.titleSmall?.copyWith(
    fontWeight: FontWeight.w600,
    fontSize: 15,
    letterSpacing: -0.2,
    height: 1.15,
  );
}
