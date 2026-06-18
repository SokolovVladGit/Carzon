import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/theme/theme_mode_cubit.dart';
import '../../../../shared/ui/carzon_icons.dart';
import 'settings_language_row.dart';

/// Dark theme toggle row for [SettingsPage].
class SettingsDarkThemeRow extends StatelessWidget {
  const SettingsDarkThemeRow({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(11, 12.5, 10, 12.5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingsRowIconCapsule(
              icon: CarzonIcons.darkTheme,
              scheme: scheme,
              isDark: isDark,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.profileDarkThemeTitle,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.04,
                        height: 1.28,
                        color: scheme.onSurface.withValues(alpha: 0.94),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.profileDarkThemeSubtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.82),
                        height: 1.32,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            BlocBuilder<ThemeModeCubit, ThemeModeState>(
              builder: (context, state) {
                return Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Switch.adaptive(
                    key: const ValueKey<String>('settings_dark_theme_switch'),
                    value: state.themeMode == ThemeMode.dark,
                    onChanged: (enabled) {
                      context.read<ThemeModeCubit>().setDarkEnabled(enabled);
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
