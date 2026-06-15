import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:carzon/features/messaging/presentation/utils/thread_camera_capture_normalizer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('normalizeThreadCameraCapture downscales and returns JPEG', () async {
    final large = img.Image(width: 3000, height: 1500);
    final raw = Uint8List.fromList(img.encodePng(large));
    final file = XFile.fromData(raw, name: 'capture.png', mimeType: 'image/png');

    final result = await normalizeThreadCameraCapture(file);

    expect(result, isNotNull);
    expect(result!.mimeType, 'image/jpeg');
    expect(result.filename, startsWith('chat_camera_'));
    expect(result.filename, endsWith('.jpg'));

    final decoded = img.decodeImage(result.bytes);
    expect(decoded, isNotNull);
    expect(decoded!.width, 1920);
    expect(decoded.height, 960);
  });

  test('normalizeThreadCameraCapture bakes EXIF orientation before encoding', () async {
    final landscape = img.Image(width: 200, height: 100);
    final jpeg = img.encodeJpg(landscape, quality: 90);
    final exif = img.ExifData();
    exif.imageIfd.orientation = 6;
    final raw = img.injectJpgExif(jpeg, exif);
    expect(raw, isNotNull);

    final result = normalizeThreadCameraBytesInIsolate(
      ThreadCameraNormalizePayload(raw!, 123),
    );

    expect(result, isNotNull);
    final decoded = img.decodeImage(result!.bytes);
    expect(decoded, isNotNull);
    expect(decoded!.width, 100);
    expect(decoded.height, 200);
  });

  test('normalizeThreadCameraCapture returns null for invalid bytes', () async {
    final file = XFile.fromData(
      Uint8List.fromList([1, 2, 3]),
      name: 'bad.bin',
    );

    final result = await normalizeThreadCameraCapture(file);
    expect(result, isNull);
  });
}
