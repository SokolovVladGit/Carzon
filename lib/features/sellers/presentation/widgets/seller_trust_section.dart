import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/l10n/app_localizations_x.dart';
import '../../domain/usecases/get_seller_public_profile.dart';
import '../bloc/seller_trust_cubit.dart';
import '../bloc/seller_trust_state.dart';
import 'seller_trust_card.dart';

/// Loads public seller summary for listing details — hides itself on failure/null.
class SellerTrustSection extends StatelessWidget {
  const SellerTrustSection({super.key, required this.sellerId});

  final String sellerId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          SellerTrustCubit(sl<GetSellerPublicProfile>())..load(sellerId),
      child: BlocBuilder<SellerTrustCubit, SellerTrustState>(
        builder: (context, state) {
          switch (state.status) {
            case SellerTrustUiStatus.loading:
            case SellerTrustUiStatus.hidden:
              return const SizedBox.shrink();
            case SellerTrustUiStatus.ready:
              final profile = state.profile!;
              final theme = Theme.of(context);
              final l10n = context.l10n;
              final isDark = theme.brightness == Brightness.dark;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.sellerSectionTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.1,
                      color: isDark
                          ? theme.colorScheme.onSurface.withValues(alpha: 0.96)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SellerTrustCard(
                    profile: profile,
                    tooltipMessage: l10n.sellerViewProfile,
                    onTap: () =>
                        context.push(AppRoutes.sellerProfilePath(sellerId)),
                  ),
                  const SizedBox(height: 24),
                ],
              );
          }
        },
      ),
    );
  }
}
