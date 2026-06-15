import 'package:camera/camera.dart';
import 'package:carzon/features/messaging/presentation/utils/thread_camera_sheet_logic.dart';
import 'package:flutter_test/flutter_test.dart';

CameraDescription _camera(
  String name,
  CameraLensDirection lens,
) {
  return CameraDescription(
    name: name,
    lensDirection: lens,
    sensorOrientation: 90,
  );
}

void main() {
  test('threadCameraPickInitial prefers rear camera', () {
    final cameras = [
      _camera('front', CameraLensDirection.front),
      _camera('back', CameraLensDirection.back),
    ];

    expect(
      threadCameraPickInitial(cameras).lensDirection,
      CameraLensDirection.back,
    );
  });

  test('threadCameraCanSwitchLens is true when front and rear exist', () {
    final cameras = [
      _camera('front', CameraLensDirection.front),
      _camera('back', CameraLensDirection.back),
    ];
    final active = cameras[1];

    expect(threadCameraCanSwitchLens(cameras, active), isTrue);
    expect(
      threadCameraDescriptionForLens(cameras, CameraLensDirection.front)?.name,
      'front',
    );
  });

  test('threadCameraCanSwitchLens is false with only one lens', () {
    final cameras = [_camera('back', CameraLensDirection.back)];

    expect(
      threadCameraCanSwitchLens(cameras, cameras.single),
      isFalse,
    );
  });

  test('threadCameraFlashLikelySupported is false for front camera', () {
    expect(
      threadCameraFlashLikelySupported(
        _camera('front', CameraLensDirection.front),
      ),
      isFalse,
    );
  });

  test('threadCameraFlashLikelySupported is true for rear camera', () {
    expect(
      threadCameraFlashLikelySupported(
        _camera('back', CameraLensDirection.back),
      ),
      isTrue,
    );
  });
}
