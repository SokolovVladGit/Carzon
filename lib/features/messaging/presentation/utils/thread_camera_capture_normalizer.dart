import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

/// Normalized JPEG output from an in-chat camera capture.
class ThreadCameraCaptureNormalized {
  const ThreadCameraCaptureNormalized({
    required this.bytes,
    required this.mimeType,
    required this.filename,
  });

  final Uint8List bytes;
  final String mimeType;
  final String filename;
}

const int threadCameraMaxDimension = 1920;
const int threadCameraJpegQuality = 85;

/// Payload for isolate-side camera capture normalization.
class ThreadCameraNormalizePayload {
  const ThreadCameraNormalizePayload(this.rawBytes, this.timestampMs);

  final Uint8List rawBytes;
  final int timestampMs;
}

ThreadCameraCaptureNormalized? normalizeThreadCameraBytesInIsolate(
  ThreadCameraNormalizePayload payload,
) {
  img.Image? decoded;
  try {
    decoded = img.decodeImage(payload.rawBytes);
  } catch (_) {
    return null;
  }
  if (decoded == null) return null;

  final oriented = img.bakeOrientation(decoded);

  img.Image processed = oriented;
  if (oriented.width > threadCameraMaxDimension ||
      oriented.height > threadCameraMaxDimension) {
    if (oriented.width >= oriented.height) {
      processed = img.copyResize(oriented, width: threadCameraMaxDimension);
    } else {
      processed = img.copyResize(oriented, height: threadCameraMaxDimension);
    }
  }

  final jpegBytes = Uint8List.fromList(
    img.encodeJpg(processed, quality: threadCameraJpegQuality),
  );
  return ThreadCameraCaptureNormalized(
    bytes: jpegBytes,
    mimeType: 'image/jpeg',
    filename: 'chat_camera_${payload.timestampMs}.jpg',
  );
}

/// Decodes, optionally downscales, and re-encodes a camera capture as JPEG.
Future<ThreadCameraCaptureNormalized?> normalizeThreadCameraCapture(
  XFile file,
) async {
  final rawBytes = await file.readAsBytes();
  final timestampMs = DateTime.now().millisecondsSinceEpoch;
  return compute(
    normalizeThreadCameraBytesInIsolate,
    ThreadCameraNormalizePayload(rawBytes, timestampMs),
  );
}
