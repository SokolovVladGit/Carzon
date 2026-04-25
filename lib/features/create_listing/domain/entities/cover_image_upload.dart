import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// Backend-agnostic description of a cover image about to be uploaded.
///
/// Carries raw bytes + content type + owner uid and never exposes any
/// Supabase / XFile / platform types to the domain layer.
class CoverImageUpload extends Equatable {
  const CoverImageUpload({
    required this.sellerId,
    required this.bytes,
    required this.contentType,
    this.originalFileName,
  });

  final String sellerId;
  final Uint8List bytes;
  final String contentType;

  /// Optional — only used as a weak hint for the storage object name.
  /// The data layer must never trust it verbatim.
  final String? originalFileName;

  @override
  List<Object?> get props => [sellerId, bytes.length, contentType, originalFileName];
}
