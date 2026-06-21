import 'dart:async';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/ui/carzon_icons.dart';
import '../../../profile/presentation/widgets/profile_grouped_card.dart';
import 'settings_language_row.dart';

/// Compact About block for [SettingsPage]: app name and version/build label.
class SettingsAboutSection extends StatefulWidget {
  const SettingsAboutSection({
    super.key,
    @visibleForTesting this.initialVersionLabel,
    @visibleForTesting this.loadVersionLabel,
  });

  /// When set, skips async [PackageInfo] lookup (widget tests).
  @visibleForTesting
  final String? initialVersionLabel;

  /// Optional loader override for tests.
  @visibleForTesting
  final Future<String> Function(AppLocalizations l10n)? loadVersionLabel;

  @override
  State<SettingsAboutSection> createState() => _SettingsAboutSectionState();
}

class _SettingsAboutSectionState extends State<SettingsAboutSection> {
  String? _versionLabel;

  @override
  void initState() {
    super.initState();
    final preset = widget.initialVersionLabel;
    if (preset != null) {
      _versionLabel = preset;
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_resolveVersionLabel());
      }
    });
  }

  Future<void> _resolveVersionLabel() async {
    final l10n = context.l10n;
    try {
      final label = widget.loadVersionLabel != null
          ? await widget.loadVersionLabel!(l10n)
          : await loadSettingsVersionLabel(l10n);
      if (!mounted) return;
      setState(() => _versionLabel = label);
    } catch (_) {
      if (!mounted) return;
      setState(() => _versionLabel = l10n.settingsAboutVersionUnavailable);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final versionLabel = _versionLabel;

    return ProfileGroupedCard(
      title: l10n.settingsSectionAbout,
      childPadding: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(11, 12.5, 10, 12.5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SettingsRowIconCapsule(
                icon: CarzonIcons.settings,
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
                        l10n.settingsAboutAppName,
                        key: const ValueKey<String>('settings_about_app_name'),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.04,
                          height: 1.28,
                          color: scheme.onSurface.withValues(alpha: 0.94),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        versionLabel ?? l10n.settingsAboutVersionLoading,
                        key: const ValueKey<String>(
                          'settings_about_version_label',
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Loads a localized version/build label from platform [PackageInfo].
Future<String> loadSettingsVersionLabel(AppLocalizations l10n) async {
  final info = await PackageInfo.fromPlatform();
  return formatSettingsVersionLabel(
    l10n,
    version: info.version,
    build: info.buildNumber,
  );
}

/// Formats the About version line for display and tests.
String formatSettingsVersionLabel(
  AppLocalizations l10n, {
  required String version,
  required String build,
}) {
  return l10n.settingsAboutVersion(version, build);
}
