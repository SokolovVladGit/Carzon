import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/widgets/auth_required_prompt.dart';
import '../../../../shared/ui/carzon_icons.dart';
import 'profile_grouped_card.dart';

class ProfileSignInRequiredPrompt extends StatelessWidget {
  const ProfileSignInRequiredPrompt({super.key, required this.onSignIn});

  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
            child: AuthRequiredPrompt(
              center: false,
              padding: EdgeInsets.zero,
              icon: _ProfileSignInMedallion(scheme: scheme, isDark: isDark),
              message: l10n.profileSignInRequired,
              primaryButtonLabel: l10n.commonSignIn,
              onPrimaryPressed: onSignIn,
              mainAxisAlignment: MainAxisAlignment.center,
              messageStyle: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.18,
                height: 1.25,
              ),
              contentWrapper: (context, child) {
                final cardFill = profileSoftSurface(scheme, isDark: isDark);
                final shadow = profileCardShadow(scheme, isDark: isDark);
                final radius = BorderRadius.circular(26);
                return DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    boxShadow: shadow,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: radius,
                      side: BorderSide(
                        color: isDark
                            ? scheme.outline.withValues(alpha: 0.28)
                            : scheme.outlineVariant.withValues(alpha: 0.42),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color.alphaBlend(
                              scheme.onSurface.withValues(
                                alpha: isDark ? 0.028 : 0.012,
                              ),
                              cardFill,
                            ),
                            cardFill,
                            Color.alphaBlend(
                              scheme.primary.withValues(
                                alpha: isDark ? 0.035 : 0.018,
                              ),
                              cardFill,
                            ),
                          ],
                          stops: const [0, 0.55, 1],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
                        child: child,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileSignInMedallion extends StatelessWidget {
  const _ProfileSignInMedallion({required this.scheme, required this.isDark});

  final ColorScheme scheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(
              scheme.primary.withValues(alpha: isDark ? 0.22 : 0.13),
              scheme.surfaceContainerHighest,
            ),
            Color.alphaBlend(
              scheme.onSurface.withValues(alpha: isDark ? 0.055 : 0.018),
              scheme.surfaceContainerLow,
            ),
          ],
        ),
        border: Border.all(
          color: scheme.primary.withValues(alpha: isDark ? 0.24 : 0.12),
        ),
        boxShadow: isDark
            ? const <BoxShadow>[]
            : [
                BoxShadow(
                  color: scheme.shadow.withValues(alpha: 0.035),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Icon(
        CarzonIcons.user,
        size: 30,
        color: scheme.onSurfaceVariant.withValues(alpha: 0.92),
      ),
    );
  }
}
