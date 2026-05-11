import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/favorites_cubit.dart';
import '../bloc/favorites_state.dart';

class FavoriteToggleButton extends StatefulWidget {
  const FavoriteToggleButton({super.key, required this.listingId});

  final String listingId;

  @override
  State<FavoriteToggleButton> createState() => _FavoriteToggleButtonState();
}

class _FavoriteToggleButtonState extends State<FavoriteToggleButton>
    with TickerProviderStateMixin {
  bool? _optimisticFavorite;

  late final AnimationController _haloCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );

  late final AnimationController _pulseCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  );

  late final Animation<double> _pulseScale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: 1.1,
      ).chain(CurveTween(curve: Curves.easeOutCubic)),
      weight: 42,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.1,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 58,
    ),
  ]).animate(_pulseCtrl);

  @override
  void dispose() {
    _haloCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _clearOptimistic() {
    if (mounted) setState(() => _optimisticFavorite = null);
  }

  void _triggerPulse() {
    _pulseCtrl
      ..stop()
      ..value = 0
      ..forward();
  }

  Color _favoriteFillColor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final err = scheme.error;
    return err.withValues(alpha: isDark ? 0.92 : 0.88);
  }

  Color _outlineColor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return scheme.onSurface.withValues(alpha: 0.92);
  }

  void _handleTap(BuildContext context) {
    final auth = context.read<AuthCubit>().state;
    final l10n = context.l10n;
    if (auth.status != AuthStatus.authenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.favoriteSignInRequired),
          action: SnackBarAction(
            label: l10n.commonSignIn,
            onPressed: () => context.go(AppRoutes.signIn),
          ),
        ),
      );
      return;
    }

    final cubit = context.read<FavoritesCubit>();
    if (cubit.state.isPending(widget.listingId)) return;

    final was = cubit.state.isFavorite(widget.listingId);

    setState(() => _optimisticFavorite = !was);
    _triggerPulse();

    _haloCtrl
      ..stop()
      ..value = 0;
    if (!was) {
      _haloCtrl.forward();
    }

    cubit.toggle(widget.listingId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return MultiBlocListener(
      listeners: [
        BlocListener<FavoritesCubit, FavoritesState>(
          listenWhen: (prev, curr) =>
              prev.lastError != curr.lastError && curr.lastError != null,
          listener: (context, state) {
            final err = state.lastError;
            if (err == null || !context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(_favoritesErrorMessage(l10n, err.kind))),
            );
          },
        ),
        BlocListener<FavoritesCubit, FavoritesState>(
          listenWhen: (prev, curr) =>
              prev.isPending(widget.listingId) &&
              !curr.isPending(widget.listingId),
          listener: (context, state) => _clearOptimistic(),
        ),
      ],
      child: BlocBuilder<FavoritesCubit, FavoritesState>(
        builder: (context, state) {
          final pending = state.isPending(widget.listingId);
          final cubitFavorite = state.isFavorite(widget.listingId);
          final displayFavorite = pending && _optimisticFavorite != null
              ? _optimisticFavorite!
              : cubitFavorite;

          final fillCol = _favoriteFillColor(context);
          final outlineCol = _outlineColor(context);
          final iconColor = displayFavorite ? fillCol : outlineCol;

          return IconButton(
            tooltip: displayFavorite ? l10n.favoriteRemove : l10n.favoriteAdd,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            padding: EdgeInsets.zero,
            style: IconButton.styleFrom(
              foregroundColor: iconColor,
              disabledForegroundColor: iconColor.withValues(
                alpha: iconColor.a * 0.88,
              ),
            ),
            onPressed: pending ? null : () => _handleTap(context),
            icon: _FavoriteAnimatedIcon(
              pulseScale: _pulseScale,
              haloAnimation: _haloCtrl,
              displayFavorite: displayFavorite,
              fillColor: fillCol,
              outlineColor: outlineCol,
              pendingOpacity: pending ? 0.86 : 1.0,
            ),
          );
        },
      ),
    );
  }
}

class _FavoriteAnimatedIcon extends StatelessWidget {
  const _FavoriteAnimatedIcon({
    required this.pulseScale,
    required this.haloAnimation,
    required this.displayFavorite,
    required this.fillColor,
    required this.outlineColor,
    required this.pendingOpacity,
  });

  final Animation<double> pulseScale;
  final Animation<double> haloAnimation;
  final bool displayFavorite;
  final Color fillColor;
  final Color outlineColor;
  final double pendingOpacity;

  static const double _iconSize = 20;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      opacity: pendingOpacity,
      child: SizedBox(
        width: _iconSize + 14,
        height: _iconSize + 14,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            IgnorePointer(
              child: AnimatedBuilder(
                animation: haloAnimation,
                builder: (context, _) {
                  final raw = haloAnimation.value;
                  if (raw <= 0.008) return const SizedBox.shrink();
                  final t = (1 - Curves.easeOutCubic.transform(raw)).clamp(
                    0.0,
                    1.0,
                  );
                  if (t <= 0.01) return const SizedBox.shrink();
                  final blur = 7 + 20 * Curves.easeOut.transform(raw);
                  return SizedBox(
                    width: _iconSize + 32,
                    height: _iconSize + 32,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            blurRadius: blur,
                            spreadRadius: 1.5 * Curves.easeOut.transform(raw),
                            color: fillColor.withValues(alpha: 0.26 * t),
                          ),
                          BoxShadow(
                            blurRadius: blur * 0.5,
                            spreadRadius: 0,
                            color: fillColor.withValues(alpha: 0.12 * t),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            ScaleTransition(
              scale: pulseScale,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeOutCubic,
                transitionBuilder: (child, anim) =>
                    FadeTransition(opacity: anim, child: child),
                child: Icon(
                  displayFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  key: ValueKey<bool>(displayFavorite),
                  size: _iconSize,
                  color: displayFavorite ? fillColor : outlineColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _favoritesErrorMessage(
  AppLocalizations l10n,
  FavoritesFailureKind kind,
) {
  return switch (kind) {
    FavoritesFailureKind.loadFailed => l10n.favoritesLoadFailed,
    FavoritesFailureKind.toggleFailed => l10n.favoriteToggleFailed,
  };
}
