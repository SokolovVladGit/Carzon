import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/seller_public_profile.dart';
import '../utils/seller_initial_labels.dart';

/// Read-only seller avatar: network image or initials / icon fallback.
class SellerAvatarBadge extends StatelessWidget {
  const SellerAvatarBadge({
    super.key,
    required this.profile,
    required this.diameter,
    this.showEditorialRing = false,
  });

  final SellerPublicProfile profile;
  final double diameter;

  /// Subtle steel-blue ring on the profile header avatar (dark mode only).
  final bool showEditorialRing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final ring = showEditorialRing && isDark;
    final initials = sellerInitialsFromDisplayName(profile.displayName);
    final trimmedUrl = profile.avatarUrl?.trim();
    final hasUrl = trimmedUrl != null && trimmedUrl.isNotEmpty;

    final placeholder = CircleAvatar(
      radius: diameter / 2,
      backgroundColor: ring
          ? Color.alphaBlend(
              scheme.primary.withValues(alpha: 0.10),
              scheme.surfaceContainerHigh,
            )
          : scheme.surfaceContainerHighest.withValues(alpha: 0.9),
      foregroundColor: scheme.onSurfaceVariant.withValues(
        alpha: ring ? 0.92 : 1,
      ),
      child: initials.isEmpty
          ? Icon(Icons.person_rounded, size: diameter * 0.48)
          : Text(
              initials,
              style: TextStyle(
                fontSize: diameter * 0.34,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
    );

    Widget avatar = placeholder;
    if (hasUrl) {
      avatar = ClipOval(
        child: SizedBox(
          width: diameter,
          height: diameter,
          child: Image.network(
            trimmedUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => placeholder,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Center(
                child: SizedBox(
                  width: diameter * 0.42,
                  height: diameter * 0.42,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.editorialAccentColor(
                      scheme,
                    ).withValues(alpha: 0.72),
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    if (!ring) return avatar;

    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppTheme.editorialAccentColor(scheme).withValues(alpha: 0.30),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.14),
            blurRadius: 14,
            spreadRadius: -2,
          ),
        ],
      ),
      child: avatar,
    );
  }
}
