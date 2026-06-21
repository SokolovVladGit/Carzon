import '../../domain/entities/user_report_reason.dart';

/// Returns true when trimmed [note] exceeds [kUserReportNoteMaxLength].
bool isUserReportNoteTooLong(String? note) {
  final trimmed = note?.trim() ?? '';
  return trimmed.length > kUserReportNoteMaxLength;
}

/// Normalizes optional report note for RPC submit.
String? normalizeUserReportNote(String? note) {
  final trimmed = note?.trim() ?? '';
  if (trimmed.isEmpty) return null;
  return trimmed;
}
