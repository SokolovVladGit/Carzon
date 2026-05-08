import 'package:flutter/material.dart';

import '../../../auth/domain/entities/auth_user.dart';
import '../utils/seller_initial_labels.dart';

/// Private account visuals: prefers seller avatar URL from [sellerProfilesAvatarUrl],
/// then [AuthUser.avatarUrl], then initials, then generic icon.
///
/// Seller URL must come from authenticated `seller_profiles` only via repository/cubit —
/// never expose email publicly.
class AccountPrivateAvatarCircle extends StatelessWidget {
  const AccountPrivateAvatarCircle({
    super.key,
    required this.diameter,
    required this.authUser,
    this.sellerProfilesAvatarUrl,
    this.sellerDisplayNameForInitialsFallback,
    this.semanticLabel,
  });

  final double diameter;
  final AuthUser authUser;

  /// `seller_profiles.avatar_url` trimmed; null/absent skips.
  final String? sellerProfilesAvatarUrl;

  /// Public seller display name for initials when no image URL works.
  final String? sellerDisplayNameForInitialsFallback;

  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sellerUrl = sellerProfilesAvatarUrl?.trim();
    final authUrl = authUser.avatarUrl?.trim();
    final resolvedUrl = (sellerUrl != null && sellerUrl.isNotEmpty)
        ? sellerUrl
        : (authUrl != null && authUrl.isNotEmpty ? authUrl : null);

    final initials = _privateAccountInitials(
      sellerDisplayNameForInitialsFallback,
      authUser.fullName,
      authUser.email,
    );

    Widget placeholder() {
      return Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: scheme.surfaceContainerHighest,
          border: Border.all(
            color: scheme.outline.withValues(alpha: 0.14),
          ),
        ),
        alignment: Alignment.center,
        child: initials.isNotEmpty
            ? Text(
                initials,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.9),
                    ),
              )
            : Icon(
                Icons.person_rounded,
                size: diameter * 0.46,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
              ),
      );
    }

    Widget base = placeholder();
    if (resolvedUrl != null) {
      base = ClipOval(
        child: Image.network(
          resolvedUrl,
          width: diameter,
          height: diameter,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => placeholder(),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return placeholder();
          },
        ),
      );
    }

    return Semantics(
      label: semanticLabel,
      child: base,
    );
  }
}

String _privateAccountInitials(
  String? sellerDisplayName,
  String? authFullName,
  String email,
) {
  final fromSeller = sellerInitialsFromDisplayName(sellerDisplayName);
  if (fromSeller.isNotEmpty) return fromSeller;
  final fromAuth = sellerInitialsFromDisplayName(authFullName);
  if (fromAuth.isNotEmpty) return fromAuth;
  final e = email.trim();
  if (e.isEmpty) return '';
  return e.substring(0, 1).toUpperCase();
}

/// Generic signed-out account glyph (no external fetch).
class AccountSignedOutAvatarCircle extends StatelessWidget {
  const AccountSignedOutAvatarCircle({
    super.key,
    required this.diameter,
    this.semanticLabel,
  });

  final double diameter;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: semanticLabel,
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: scheme.surfaceContainerHighest,
          border: Border.all(
            color: scheme.outline.withValues(alpha: 0.14),
          ),
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.person_rounded,
          size: diameter * 0.46,
          color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
        ),
      ),
    );
  }
}
