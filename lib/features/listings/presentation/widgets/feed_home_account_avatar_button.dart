import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/l10n/app_localizations_x.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../messaging/presentation/bloc/messaging_unread_summary_cubit.dart';
import '../../../messaging/presentation/bloc/messaging_unread_summary_state.dart';
import '../../../sellers/presentation/bloc/self_seller_visual_cubit.dart';
import '../../../sellers/presentation/widgets/account_private_avatar.dart';

/// Compact account control for the listings masthead: private seller-first
/// avatar, optional unread dot (no count), opens Account/Profile.
class FeedHomeAccountAvatarButton extends StatelessWidget {
  const FeedHomeAccountAvatarButton({super.key});

  static const double avatarDiameter = 34;

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final l10n = context.l10n;

    Widget wrapSignedOut() {
      return Tooltip(
        message: l10n.accountAvatarOpenProfileTooltip,
        child: InkWell(
          customBorder: const CircleBorder(),
          key: const ValueKey('feed_home_account_avatar_button'),
          onTap: () => context.push(AppRoutes.profile),
          child: AccountSignedOutAvatarCircle(
            diameter: avatarDiameter,
            semanticLabel: l10n.accountAvatarOpenProfileTooltip,
          ),
        ),
      );
    }

    if (authState.status != AuthStatus.authenticated ||
        authState.user == null) {
      return wrapSignedOut();
    }

    final user = authState.user!;
    return Tooltip(
      message: l10n.accountAvatarOpenProfileTooltip,
      child: InkWell(
        customBorder: const CircleBorder(),
        key: const ValueKey('feed_home_account_avatar_button'),
        onTap: () => context.push(AppRoutes.profile),
        child: SizedBox(
          width: avatarDiameter + 4,
          height: avatarDiameter + 4,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              BlocBuilder<SelfSellerVisualCubit, SelfSellerVisualState>(
                builder: (context, vis) {
                  return AccountPrivateAvatarCircle(
                    diameter: avatarDiameter,
                    authUser: user,
                    sellerProfilesAvatarUrl: vis.sellerAvatarUrl,
                    sellerDisplayNameForInitialsFallback: vis.sellerDisplayName,
                    semanticLabel: l10n.accountAvatarOpenProfileTooltip,
                  );
                },
              ),
              BlocBuilder<
                MessagingUnreadSummaryCubit,
                MessagingUnreadSummaryState
              >(
                buildWhen: (p, q) =>
                    p.unreadConversationCount != q.unreadConversationCount ||
                    p.phase != q.phase,
                builder: (context, u) {
                  final show = u.shouldShowUnreadIndicator;
                  if (!show) return const SizedBox.shrink();
                  final scheme = Theme.of(context).colorScheme;
                  return Positioned(
                    key: const ValueKey('feed_home_unread_indicator_dot'),
                    right: -1,
                    top: -1,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: scheme.error,
                        shape: BoxShape.circle,
                        border: Border.all(color: scheme.surface, width: 1.5),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
