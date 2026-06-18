import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/config/env.dart';
import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/l10n/app_locale_cubit.dart';
import '../../../../core/l10n/app_locale_preference.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/ui/carzon_icons.dart';
import '../../../notifications/services/push_notification_registration_service.dart';
import '../../../profile/presentation/widgets/profile_settings_navigation_row.dart';

/// App language picker row (RU / RO) for [SettingsPage].
class SettingsLanguageRow extends StatelessWidget {
  const SettingsLanguageRow({super.key});

  static String currentLanguageLabel(
    AppLocalizations l10n,
    AppLocalePreference preference,
  ) {
    return switch (preference) {
      AppLocalePreference.ru => l10n.profileLanguageCurrentRussian,
      AppLocalePreference.ro => l10n.profileLanguageCurrentRomanian,
    };
  }

  Future<void> _syncPushTokenLocaleAfterChange() async {
    if (!Env.pushNotificationsEnabled) {
      return;
    }
    unawaited(
      sl<PushNotificationRegistrationService>()
          .syncTokenWithBackendIfEligible(),
    );
  }

  Future<void> _showLanguageSheet(BuildContext context) async {
    final l10n = context.l10n;
    final cubit = context.read<AppLocaleCubit>();
    final selected = cubit.state.preference;
    final scheme = Theme.of(context).colorScheme;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                key: const ValueKey('settings_language_option_ru'),
                title: Text(l10n.profileLanguageOptionRussian),
                trailing: selected == AppLocalePreference.ru
                    ? Icon(Icons.check, color: scheme.primary)
                    : null,
                onTap: () async {
                  await cubit.setPreference(AppLocalePreference.ru);
                  await _syncPushTokenLocaleAfterChange();
                  if (sheetContext.mounted) {
                    Navigator.of(sheetContext).pop();
                  }
                },
              ),
              ListTile(
                key: const ValueKey('settings_language_option_ro'),
                title: Text(l10n.profileLanguageOptionRomanian),
                trailing: selected == AppLocalePreference.ro
                    ? Icon(Icons.check, color: scheme.primary)
                    : null,
                onTap: () async {
                  await cubit.setPreference(AppLocalePreference.ro);
                  await _syncPushTokenLocaleAfterChange();
                  if (sheetContext.mounted) {
                    Navigator.of(sheetContext).pop();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return BlocBuilder<AppLocaleCubit, AppLocaleState>(
      builder: (context, localeState) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: const ValueKey('settings_language_row'),
              borderRadius: BorderRadius.circular(18),
              splashFactory: InkRipple.splashFactory,
              splashColor: scheme.onSurface.withValues(alpha: 0.038),
              highlightColor: Colors.transparent,
              onTap: () => _showLanguageSheet(context),
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(11, 12.5, 6, 12.5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SettingsRowIconCapsule(
                        icon: Icons.language_outlined,
                        scheme: scheme,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.profileLanguageTitle,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.04,
                                height: 1.28,
                                color: scheme.onSurface.withValues(alpha: 0.94),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currentLanguageLabel(
                                l10n,
                                localeState.preference,
                              ),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant.withValues(
                                  alpha: 0.82,
                                ),
                                height: 1.32,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: SizedBox(
                          width: 26,
                          height: 32,
                          child: Icon(
                            CarzonIcons.chevronRight,
                            size: 18,
                            color: scheme.onSurfaceVariant.withValues(
                              alpha: isDark ? 0.56 : 0.42,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Shared icon capsule for settings rows (matches profile settings styling).
class SettingsRowIconCapsule extends StatelessWidget {
  const SettingsRowIconCapsule({
    super.key,
    required this.icon,
    required this.scheme,
    required this.isDark,
  });

  final IconData icon;
  final ColorScheme scheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Color.alphaBlend(
          scheme.primary.withValues(alpha: isDark ? 0.14 : 0.085),
          scheme.surfaceContainerLowest,
        ),
        border: Border.all(
          color: scheme.primary.withValues(alpha: isDark ? 0.26 : 0.18),
        ),
        boxShadow: isDark
            ? const <BoxShadow>[]
            : [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Icon(
        icon,
        size: 19,
        color: scheme.primary.withValues(alpha: isDark ? 0.90 : 0.84),
      ),
    );
  }
}
