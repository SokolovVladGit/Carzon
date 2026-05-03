import 'dart:typed_data';

/// Local staging row for listing photos before upload (presentation only).
final class CreateListingPhotoDraft {
  const CreateListingPhotoDraft({
    required this.bytes,
    required this.contentType,
    this.fileName,
  });

  final Uint8List bytes;
  final String contentType;
  final String? fileName;
}
