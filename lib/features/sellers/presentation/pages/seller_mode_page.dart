import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/auth_required_prompt.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../shared/ui/carzon_icons.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/entities/seller_type.dart';
import '../bloc/seller_mode_cubit.dart';
import '../bloc/seller_mode_state.dart';

class SellerModePage extends StatelessWidget {
  const SellerModePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, auth) {
        if (auth.status != AuthStatus.authenticated || auth.user == null) {
          return const SellerModeSignedOutChrome();
        }
        return BlocProvider(
          create: (_) => sl<SellerModeCubit>()..load(),
          child: const SellerModeChrome(),
        );
      },
    );
  }
}

@visibleForTesting
class SellerModeSignedOutChrome extends StatelessWidget {
  const SellerModeSignedOutChrome({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _SellerModeScaffold(
      body: AuthRequiredPrompt(
        icon: const Icon(CarzonIcons.sellerMode, size: 48),
        message: l10n.profileSignInRequired,
        primaryButtonLabel: l10n.commonSignIn,
        onPrimaryPressed: () => context.go(AppRoutes.signIn),
      ),
    );
  }
}

@visibleForTesting
Widget sellerModeTestHarness({
  required SellerModeCubit cubit,
  required Widget child,
}) {
  return BlocProvider<SellerModeCubit>.value(value: cubit, child: child);
}

@visibleForTesting
class SellerModeChrome extends StatelessWidget {
  const SellerModeChrome({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _SellerModeScaffold(
      body: BlocConsumer<SellerModeCubit, SellerModeState>(
        listenWhen: (prev, curr) => curr.saveFailed && !prev.saveFailed,
        listener: (context, state) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(l10n.sellerModeSaveFailed)));
        },
        builder: (context, state) {
          return switch (state.status) {
            SellerModeStatus.initial ||
            SellerModeStatus.loading => const LoadingView(),
            SellerModeStatus.error => ErrorView(
              message: l10n.sellerModeLoadFailed,
              onRetry: () => context.read<SellerModeCubit>().load(),
            ),
            SellerModeStatus.ready ||
            SellerModeStatus.saving => _SellerModeBody(state: state),
          };
        },
      ),
    );
  }
}

class _SellerModeScaffold extends StatelessWidget {
  const _SellerModeScaffold({required this.body});

  final Widget body;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: AppTheme.showroomPageBackground(scheme),
      appBar: AppBar(
        leading: const AppBackButton(fallback: AppRoutes.profile),
        title: Text(l10n.sellerModeTitle),
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

class _SellerModeBody extends StatelessWidget {
  const _SellerModeBody({required this.state});

  final SellerModeState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final saving = state.status == SellerModeStatus.saving;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        if (state.showVerified) ...[
          _VerifiedCallout(label: l10n.sellerModeVerified),
          const SizedBox(height: 16),
        ],
        _ModeOptionCard(
          optionKey: const ValueKey<String>('seller_mode_option_private'),
          title: l10n.sellerModePrivateTitle,
          body: l10n.sellerModePrivateBody,
          selected: state.draftType == SellerType.private,
          enabled: !saving,
          onTap: () =>
              context.read<SellerModeCubit>().select(SellerType.private),
        ),
        const SizedBox(height: 12),
        _ModeOptionCard(
          optionKey: const ValueKey<String>('seller_mode_option_professional'),
          title: l10n.sellerModeProfessionalTitle,
          body: l10n.sellerModeProfessionalBody,
          selected: state.draftType == SellerType.dealer,
          enabled: !saving,
          onTap: () =>
              context.read<SellerModeCubit>().select(SellerType.dealer),
        ),
        const SizedBox(height: 24),
        FilledButton(
          key: const ValueKey<String>('seller_mode_save'),
          onPressed: saving || !state.isDirty
              ? null
              : () => context.read<SellerModeCubit>().save(),
          child: Text(l10n.commonSave),
        ),
      ],
    );
  }
}

class _VerifiedCallout extends StatelessWidget {
  const _VerifiedCallout({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: AppTheme.softCardSurface(scheme),
        border: Border.all(color: AppTheme.softCardBorderColor(scheme)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Text(
          label,
          key: const ValueKey<String>('seller_mode_verified'),
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _ModeOptionCard extends StatelessWidget {
  const _ModeOptionCard({
    required this.optionKey,
    required this.title,
    required this.body,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final Key optionKey;
  final String title;
  final String body;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    return Material(
      key: optionKey,
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(26),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: AppTheme.softCardGroupedGradient(scheme),
            border: Border.all(
              color: selected
                  ? scheme.primary.withValues(alpha: isDark ? 0.46 : 0.34)
                  : AppTheme.softCardBorderColor(scheme),
              width: selected ? 1.4 : 1,
            ),
            boxShadow: AppTheme.softCardShadow(scheme),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: selected ? scheme.primary : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        body,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
