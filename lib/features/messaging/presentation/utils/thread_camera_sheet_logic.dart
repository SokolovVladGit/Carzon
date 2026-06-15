import 'package:camera/camera.dart';

/// Picks the initial camera, preferring rear lens when available.
CameraDescription threadCameraPickInitial(List<CameraDescription> cameras) {
  return cameras.firstWhere(
    (c) => c.lensDirection == CameraLensDirection.back,
    orElse: () => cameras.first,
  );
}

/// Returns the opposite lens direction when switching is meaningful.
CameraLensDirection? threadCameraOtherLensDirection(
  CameraLensDirection current,
) {
  return switch (current) {
    CameraLensDirection.back => CameraLensDirection.front,
    CameraLensDirection.front => CameraLensDirection.back,
    _ => null,
  };
}

/// Finds a camera description for [lens], or null when unavailable.
CameraDescription? threadCameraDescriptionForLens(
  List<CameraDescription> cameras,
  CameraLensDirection lens,
) {
  for (final camera in cameras) {
    if (camera.lensDirection == lens) return camera;
  }
  return null;
}

/// True when both the active lens and its opposite exist on the device.
bool threadCameraCanSwitchLens(
  List<CameraDescription> cameras,
  CameraDescription? active,
) {
  if (cameras.length < 2 || active == null) return false;
  final otherLens = threadCameraOtherLensDirection(active.lensDirection);
  if (otherLens == null) return false;
  return threadCameraDescriptionForLens(cameras, otherLens) != null;
}

/// Heuristic for showing the flash control before [setFlashMode] is attempted.
bool threadCameraFlashLikelySupported(CameraDescription camera) {
  return camera.lensDirection == CameraLensDirection.back;
}
