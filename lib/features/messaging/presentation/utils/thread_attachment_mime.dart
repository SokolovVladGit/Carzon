import 'package:image_picker/image_picker.dart';

import '../../domain/constants/chat_attachment_limits.dart';

/// Resolves chat attachment MIME from [XFile] metadata or file name.
String? resolveThreadAttachmentMimeType(XFile file) {
  final reported = file.mimeType?.trim().toLowerCase();
  if (reported != null &&
      reported.isNotEmpty &&
      ChatAttachmentLimits.allowedMimeTypes.contains(reported)) {
    return reported;
  }
  final name = file.name.toLowerCase();
  if (name.endsWith('.png')) return 'image/png';
  if (name.endsWith('.jpg') || name.endsWith('.jpeg')) return 'image/jpeg';
  return null;
}
