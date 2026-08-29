enum ListingReportReason {
  scam,
  spam,
  inappropriate,
  misleading,
  prohibited,
  other,
}

const int kListingReportNoteMaxLength = 1000;

extension ListingReportReasonDbValue on ListingReportReason {
  String toDbValue() => name;
}
