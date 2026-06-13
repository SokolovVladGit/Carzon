import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// Local composer selection before upload/send.
class ThreadComposerAttachmentDraft extends Equatable {
  const ThreadComposerAttachmentDraft({
    required this.bytes,
    required this.mimeType,
    this.filename,
  });

  final Uint8List bytes;
  final String mimeType;
  final String? filename;

  @override
  List<Object?> get props => [bytes.length, mimeType, filename];
}
