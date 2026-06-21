/// Report reason values accepted by `report_user` RPC.
enum UserReportReason {
  harassment,
  spam,
  scam,
  inappropriate,
  other;

  /// Postgres `user_reports.reason` value.
  String toDbValue() => name;
}

/// Maximum note length enforced client-side and on the server.
const int kUserReportNoteMaxLength = 1000;
