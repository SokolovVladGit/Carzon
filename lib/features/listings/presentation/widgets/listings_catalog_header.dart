import 'package:flutter/material.dart';

import 'feed_home_account_avatar_button.dart';

/// Editorial wordmark header at the top of the feed.
///
/// The wordmark stays centered; mirrored leading width keeps the masthead
/// balanced with the trailing account control.
class ListingsCatalogHeader extends StatelessWidget {
  const ListingsCatalogHeader({super.key});

  static const double _mastheadSideSlot =
      FeedHomeAccountAvatarButton.avatarDiameter + 8;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final wordmark = Text(
      'CARZON',
      textAlign: TextAlign.center,
      style: theme.textTheme.titleSmall?.copyWith(
        color: scheme.onSurface.withValues(alpha: 0.82),
        fontWeight: FontWeight.w700,
        letterSpacing: 4.0,
        height: 1.0,
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 14, 10),
      child: Row(
        children: [
          const SizedBox(width: _mastheadSideSlot),
          Expanded(child: Center(child: wordmark)),
          const SizedBox(
            width: _mastheadSideSlot,
            child: Align(
              alignment: Alignment.centerRight,
              child: FeedHomeAccountAvatarButton(),
            ),
          ),
        ],
      ),
    );
  }
}
