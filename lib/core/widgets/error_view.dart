import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../shared/ui/carzon_icons.dart';

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    // Fall back to the bare retry label when this widget is mounted
    // *before* the app's localization delegates are wired in (e.g. from
    // `StartupErrorApp`, which runs before `MaterialApp.router` is
    // mounted).
    final retryLabel =
        Localizations.of<AppLocalizations>(context, AppLocalizations)
                ?.commonRetry ??
            'Повторить';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CarzonIcons.error, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: Text(retryLabel)),
            ],
          ],
        ),
      ),
    );
  }
}
