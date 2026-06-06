import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/widgets/auth_required_prompt.dart';
import '../../../../shared/ui/carzon_icons.dart';

class ProfileSignInRequiredPrompt extends StatelessWidget {
  const ProfileSignInRequiredPrompt({super.key, required this.onSignIn});

  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
            child: AuthRequiredPrompt(
              center: false,
              padding: EdgeInsets.zero,
              icon: const Icon(CarzonIcons.user, size: 48),
              message: l10n.profileSignInRequired,
              primaryButtonLabel: l10n.commonSignIn,
              onPrimaryPressed: onSignIn,
              mainAxisAlignment: MainAxisAlignment.center,
            ),
          ),
        ),
      ],
    );
  }
}
