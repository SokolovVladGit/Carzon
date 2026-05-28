import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';

/// Localized date line for thread message groups (today / yesterday / other).
String threadDateSeparatorLabel(DateTime dayStart, AppLocalizations l10n) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  if (dayStart == today) {
    return l10n.messagingDateToday;
  }
  if (dayStart == yesterday) {
    return l10n.messagingDateYesterday;
  }
  return DateFormat('d MMMM y', l10n.localeName).format(dayStart);
}
