import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/auth_required_prompt.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/floating_capsule_nav.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/top_level_scaffold.dart';
import '../../../../shared/ui/carzon_icons.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../sellers/domain/entities/seller_type.dart';
import '../../domain/entities/seller_analytics_period.dart';
import '../bloc/seller_analytics_cubit.dart';
import '../bloc/seller_analytics_state.dart';
import '../widgets/dealer_statistics_content.dart';
import '../widgets/private_statistics_content.dart';
import '../widgets/statistics_period_selector.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        if (authState.status != AuthStatus.authenticated ||
            authState.user == null) {
          return const StatisticsSignedOutChrome();
        }
        return BlocProvider(
          create: (_) => sl<SellerAnalyticsCubit>()..load(),
          child: const StatisticsChrome(),
        );
      },
    );
  }
}

@visibleForTesting
class StatisticsSignedOutChrome extends StatelessWidget {
  const StatisticsSignedOutChrome({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _StatisticsScaffold(
      body: AuthRequiredPrompt(
        icon: const Icon(CarzonIcons.statistics, size: 48),
        message: l10n.statisticsSignInRequired,
        primaryButtonLabel: l10n.commonSignIn,
        onPrimaryPressed: () => context.go(AppRoutes.signIn),
      ),
    );
  }
}

@visibleForTesting
Widget statisticsTestHarness({
  required SellerAnalyticsCubit cubit,
  required Widget child,
}) {
  return BlocProvider<SellerAnalyticsCubit>.value(value: cubit, child: child);
}

@visibleForTesting
class StatisticsChrome extends StatelessWidget {
  const StatisticsChrome({super.key});

  @override
  Widget build(BuildContext context) {
    return _StatisticsScaffold(
      body: BlocBuilder<SellerAnalyticsCubit, SellerAnalyticsState>(
        builder: (context, state) {
          return switch (state.status) {
            SellerAnalyticsStatus.initial ||
            SellerAnalyticsStatus.loading => const LoadingView(),
            SellerAnalyticsStatus.error => ErrorView(
              message: context.l10n.statisticsLoadFailed,
              onRetry: () => context.read<SellerAnalyticsCubit>().retry(),
            ),
            SellerAnalyticsStatus.loaded => _StatisticsBody(state: state),
          };
        },
      ),
    );
  }
}

class _StatisticsScaffold extends StatelessWidget {
  const _StatisticsScaffold({required this.body});

  final Widget body;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return TopLevelScaffold(
      destination: TopLevelDestination.menu,
      backgroundColor: AppTheme.showroomPageBackground(scheme),
      appBar: AppBar(
        title: Text(l10n.statisticsTitle),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        systemOverlayStyle: scheme.brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      body: body,
    );
  }
}

class _StatisticsBody extends StatelessWidget {
  const _StatisticsBody({required this.state});

  final SellerAnalyticsState state;

  @override
  Widget build(BuildContext context) {
    if (state.isEmptySeller) {
      return _StatisticsEmpty(period: state.period);
    }
    return _StatisticsDashboard(state: state);
  }
}

class _StatisticsEmpty extends StatelessWidget {
  const _StatisticsEmpty({required this.period});

  final SellerAnalyticsPeriod period;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        kFloatingCapsuleNavClearance,
      ),
      children: [
        StatisticsPeriodSelector(
          selected: period,
          onChanged: (next) =>
              context.read<SellerAnalyticsCubit>().selectPeriod(next),
        ),
        const SizedBox(height: 28),
        EmptyStateView(
          expand: false,
          icon: CarzonIcons.inventoryEmpty,
          title: l10n.statisticsEmptyTitle,
          body: l10n.statisticsEmptyBody,
          primaryAction: EmptyStateAction(
            label: l10n.statisticsEmptyCta,
            onPressed: () => context.go(AppRoutes.createListing),
          ),
        ),
      ],
    );
  }
}

class _StatisticsDashboard extends StatelessWidget {
  const _StatisticsDashboard({required this.state});

  final SellerAnalyticsState state;

  @override
  Widget build(BuildContext context) {
    return switch (state.summary!.sellerType) {
      SellerType.dealer => DealerStatisticsContent(state: state),
      SellerType.private => PrivateStatisticsContent(state: state),
    };
  }
}
