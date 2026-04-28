import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/ui/carzon_icons.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/favorites_cubit.dart';
import '../bloc/favorites_state.dart';

class FavoriteToggleButton extends StatelessWidget {
  const FavoriteToggleButton({super.key, required this.listingId});

  final String listingId;

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
    context.read<FavoritesCubit>().toggle(listingId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<FavoritesCubit, FavoritesState>(
      listenWhen: (prev, curr) =>
          prev.lastError != curr.lastError && curr.lastError != null,
      listener: (context, state) {
        final err = state.lastError;
        if (err == null) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_favoritesErrorMessage(l10n, err.kind))),
        );
      },
      buildWhen: (prev, curr) =>
          prev.isFavorite(listingId) != curr.isFavorite(listingId) ||
          prev.isPending(listingId) != curr.isPending(listingId),
      builder: (context, state) {
        final isFav = state.isFavorite(listingId);
        final pending = state.isPending(listingId);
        return IconButton(
          tooltip: isFav ? l10n.favoriteRemove : l10n.favoriteAdd,
          onPressed: pending ? null : () => _handleTap(context),
          icon: pending
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : _FavoriteIcon(isFav: isFav),
        );
      },
    );
  }
}

/// Heart glyph that plays a quick pop-up pulse (1.0 → 1.15 → 1.0) the
/// moment [isFav] flips.
///
/// The pulse runs **locally** — the cubit/toggle call path is
/// untouched, so there is no delay between the user's tap and the
/// repository mutation. The animation is purely perceptual polish
/// and gets discarded if [isFav] never changes (inherits the
/// previous static `Icon` render path).
class _FavoriteIcon extends StatefulWidget {
  const _FavoriteIcon({required this.isFav});

  final bool isFav;

  @override
  State<_FavoriteIcon> createState() => _FavoriteIconState();
}

class _FavoriteIconState extends State<_FavoriteIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 160),
  );

  // Scale curve: 0 → 1 interpolates from `baseScale` (1.0) through
  // `peakScale` (1.15) and back. `easeOutBack` on the first half
  // gives the brief's "slight overshoot" feel; `easeIn` on the
  // return settles without a second bounce.
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(begin: 1.0, end: 1.15)
          .chain(CurveTween(curve: Curves.easeOutBack)),
      weight: 55,
    ),
    TweenSequenceItem(
      tween: Tween(begin: 1.15, end: 1.0)
          .chain(CurveTween(curve: Curves.easeIn)),
      weight: 45,
    ),
  ]).animate(_ctrl);

  @override
  void didUpdateWidget(covariant _FavoriteIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isFav != widget.isFav) {
      _ctrl
        ..stop()
        ..value = 0
        ..forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Icon(
        widget.isFav ? CarzonIcons.heartFilled : CarzonIcons.heartOutline,
        color: widget.isFav ? Colors.red : null,
      ),
    );
  }
}

String _favoritesErrorMessage(AppLocalizations l10n, FavoritesFailureKind kind) {
  return switch (kind) {
    FavoritesFailureKind.loadFailed => l10n.favoritesLoadFailed,
    FavoritesFailureKind.toggleFailed => l10n.favoriteToggleFailed,
  };
}
