import 'package:flutter/material.dart';

import '../../domain/entities/seller_public_profile.dart';
import '../utils/seller_initial_labels.dart';

/// Read-only seller avatar: network image or initials / icon fallback.
class SellerAvatarBadge extends StatelessWidget {
  const SellerAvatarBadge({
    super.key,
    required this.profile,
    required this.diameter,
  });

  final SellerPublicProfile profile;
  final double diameter;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initials = sellerInitialsFromDisplayName(profile.displayName);
    final trimmedUrl = profile.avatarUrl?.trim();
    final hasUrl = trimmedUrl != null && trimmedUrl.isNotEmpty;

    final placeholder = CircleAvatar(
      radius: diameter / 2,
      backgroundColor: scheme.surfaceContainerHighest.withValues(alpha: 0.9),
      foregroundColor: scheme.onSurfaceVariant,
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

    if (!hasUrl) {
      return placeholder;
    }

    return ClipOval(
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
                  color: scheme.outline.withValues(alpha: 0.45),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
