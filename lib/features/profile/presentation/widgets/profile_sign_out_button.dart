import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../shared/ui/carzon_icons.dart';

class ProfileSignOutButton extends StatelessWidget {
  const ProfileSignOutButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return OutlinedButton.icon(
      key: const ValueKey('profileSignOutButton'),
      onPressed: onPressed,
      icon: const Icon(CarzonIcons.signOut),
      label: Text(l10n.profileSignOut),
    );
  }
}
