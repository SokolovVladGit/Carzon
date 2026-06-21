import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/ui/carzon_icons.dart';
import '../utils/thread_camera_sheet_logic.dart';

/// Fraction of viewport height used by the in-chat camera sheet.
const double kThreadCameraSheetHeightFactor = 0.58;

enum _ThreadCameraSheetError { permissionDenied, unavailable, captureFailed }

/// Opens a partial-height in-chat camera capture sheet.
Future<XFile?> showThreadCameraCaptureSheet(BuildContext context) {
  FocusManager.instance.primaryFocus?.unfocus();
  return showModalBottomSheet<XFile?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => const ThreadCameraCaptureSheet(),
  );
}

class ThreadCameraCaptureSheet extends StatefulWidget {
  const ThreadCameraCaptureSheet({super.key});

  @override
  State<ThreadCameraCaptureSheet> createState() =>
      _ThreadCameraCaptureSheetState();
}

class _ThreadCameraCaptureSheetState extends State<ThreadCameraCaptureSheet>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  CameraDescription? _activeCamera;
  bool _initializing = true;
  bool _capturing = false;
  bool _flashOn = false;
  bool _flashSupported = false;
  _ThreadCameraSheetError? _error;
  int _initGeneration = 0;

  static const double _overlayControlSize = 44;
  static const double _shutterSize = 72;

  bool get _controlsLocked =>
      _initializing ||
      _capturing ||
      _error != null ||
      _controller == null ||
      !_controller!.value.isInitialized;

  bool get _canSwitchCamera =>
      threadCameraCanSwitchLens(_cameras, _activeCamera);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeController();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      if (state == AppLifecycleState.resumed && _error == null) {
        _initCamera();
      }
      return;
    }

    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _disposeController();
        if (mounted) {
          setState(() => _initializing = true);
        }
      case AppLifecycleState.resumed:
        _initCamera();
    }
  }

  Future<void> _disposeController() async {
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      await controller.dispose();
    }
  }

  bool _isPermissionDenied(CameraException error) {
    return error.code == 'CameraAccessDenied' ||
        error.code == 'CameraAccessDeniedWithoutPrompt';
  }

  CameraDescription _resolveCamera(
    List<CameraDescription> cameras, {
    CameraDescription? preferred,
  }) {
    if (preferred != null &&
        cameras.any((camera) => camera.name == preferred.name)) {
      return preferred;
    }
    if (_activeCamera != null &&
        cameras.any((camera) => camera.name == _activeCamera!.name)) {
      return _activeCamera!;
    }
    return threadCameraPickInitial(cameras);
  }

  Future<void> _applyFlashMode(CameraController controller) async {
    if (!_flashSupported) {
      _flashOn = false;
      return;
    }
    try {
      await controller.setFlashMode(
        _flashOn ? FlashMode.always : FlashMode.off,
      );
    } on CameraException {
      _flashSupported = false;
      _flashOn = false;
    }
  }

  Future<void> _initCamera({CameraDescription? preferred}) async {
    final generation = ++_initGeneration;
    if (mounted) {
      setState(() {
        _initializing = true;
        _error = null;
      });
    }

    await _disposeController();
    if (!mounted || generation != _initGeneration) return;

    try {
      final cameras = await availableCameras();
      if (!mounted || generation != _initGeneration) return;

      if (cameras.isEmpty) {
        setState(() {
          _cameras = [];
          _activeCamera = null;
          _flashSupported = false;
          _flashOn = false;
          _initializing = false;
          _error = _ThreadCameraSheetError.unavailable;
        });
        return;
      }

      final camera = _resolveCamera(cameras, preferred: preferred);
      final switchingLens =
          preferred != null &&
          _activeCamera?.lensDirection != camera.lensDirection;

      _cameras = cameras;
      _activeCamera = camera;
      if (switchingLens || !threadCameraFlashLikelySupported(camera)) {
        _flashOn = false;
      }
      _flashSupported = threadCameraFlashLikelySupported(camera);

      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();
      if (!mounted || generation != _initGeneration) {
        await controller.dispose();
        return;
      }

      await _applyFlashMode(controller);

      setState(() {
        _controller = controller;
        _initializing = false;
        _error = null;
      });
    } on CameraException catch (e) {
      if (!mounted || generation != _initGeneration) return;
      setState(() {
        _initializing = false;
        _error = _isPermissionDenied(e)
            ? _ThreadCameraSheetError.permissionDenied
            : _ThreadCameraSheetError.unavailable;
      });
    } catch (_) {
      if (!mounted || generation != _initGeneration) return;
      setState(() {
        _initializing = false;
        _error = _ThreadCameraSheetError.unavailable;
      });
    }
  }

  Future<void> _switchCamera() async {
    if (!_canSwitchCamera || _controlsLocked) return;
    final active = _activeCamera;
    if (active == null) return;

    final otherLens = threadCameraOtherLensDirection(active.lensDirection);
    if (otherLens == null) return;

    final other = threadCameraDescriptionForLens(_cameras, otherLens);
    if (other == null) return;

    await _initCamera(preferred: other);
  }

  Future<void> _toggleFlash() async {
    if (!_flashSupported || _controlsLocked) return;

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    final nextFlashOn = !_flashOn;
    try {
      await controller.setFlashMode(
        nextFlashOn ? FlashMode.always : FlashMode.off,
      );
      if (!mounted) return;
      setState(() => _flashOn = nextFlashOn);
    } on CameraException {
      if (!mounted) return;
      setState(() {
        _flashSupported = false;
        _flashOn = false;
      });
    }
  }

  Future<void> _takePicture() async {
    final controller = _controller;
    if (_capturing ||
        _initializing ||
        controller == null ||
        !controller.value.isInitialized ||
        controller.value.isTakingPicture) {
      return;
    }

    setState(() => _capturing = true);
    try {
      if (_flashSupported && _flashOn) {
        await controller.setFlashMode(FlashMode.always);
      }
      final file = await controller.takePicture();
      if (!mounted) return;
      Navigator.of(context).pop(file);
    } on CameraException catch (_) {
      if (!mounted) return;
      setState(() {
        _capturing = false;
        _error = _ThreadCameraSheetError.captureFailed;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _capturing = false;
        _error = _ThreadCameraSheetError.captureFailed;
      });
    }
  }

  String _errorMessage(AppLocalizations l10n) {
    return switch (_error) {
      _ThreadCameraSheetError.permissionDenied =>
        l10n.messagingCameraPermissionDenied,
      _ThreadCameraSheetError.unavailable => l10n.messagingCameraUnavailable,
      _ThreadCameraSheetError.captureFailed =>
        l10n.messagingCameraCaptureFailed,
      null => '',
    };
  }

  ButtonStyle _overlayIconButtonStyle({bool highlighted = false}) {
    return IconButton.styleFrom(
      minimumSize: const Size(_overlayControlSize, _overlayControlSize),
      maximumSize: const Size(_overlayControlSize, _overlayControlSize),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: EdgeInsets.zero,
      shape: const CircleBorder(),
      backgroundColor: highlighted
          ? Colors.white.withValues(alpha: 0.28)
          : Colors.black.withValues(alpha: 0.42),
      disabledBackgroundColor: Colors.black.withValues(alpha: 0.22),
      foregroundColor: Colors.white,
      disabledForegroundColor: Colors.white.withValues(alpha: 0.42),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final accent = AppTheme.editorialAccentColor(cs);
    final sheetHeight =
        MediaQuery.sizeOf(context).height * kThreadCameraSheetHeightFactor;

    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          color: Colors.transparent,
          child: Container(
            height: sheetHeight,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: cs.shadow.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(child: _buildPreviewBody(l10n, theme)),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.62),
                            Colors.black.withValues(alpha: 0.18),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.55, 1.0],
                        ),
                      ),
                      child: const SizedBox(height: 132),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildCancelControl(l10n),
                      Expanded(
                        child: Center(child: _buildShutterButton(accent, cs)),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildFlashControl(accent),
                          const SizedBox(height: 10),
                          _buildSwitchControl(),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCancelControl(AppLocalizations l10n) {
    return TextButton(
      onPressed: _capturing ? null : () => Navigator.of(context).pop(),
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.white.withValues(alpha: 0.45),
        backgroundColor: Colors.black.withValues(alpha: 0.42),
        disabledBackgroundColor: Colors.black.withValues(alpha: 0.22),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(
        l10n.commonCancel,
        maxLines: 1,
        softWrap: false,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          height: 1.0,
        ),
      ),
    );
  }

  Widget _buildShutterButton(Color accent, ColorScheme cs) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
      ),
      child: FilledButton(
        onPressed: _controlsLocked ? null : _takePicture,
        style: FilledButton.styleFrom(
          minimumSize: const Size(_shutterSize, _shutterSize),
          maximumSize: const Size(_shutterSize, _shutterSize),
          padding: EdgeInsets.zero,
          shape: const CircleBorder(),
          backgroundColor: accent,
          foregroundColor: cs.onPrimary,
          disabledBackgroundColor: accent.withValues(alpha: 0.45),
          disabledForegroundColor: cs.onPrimary.withValues(alpha: 0.72),
          elevation: 0,
        ),
        child: _capturing
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: cs.onPrimary,
                ),
              )
            : Icon(CarzonIcons.addPhoto, size: 28),
      ),
    );
  }

  Widget _buildFlashControl(Color accent) {
    if (!_flashSupported) {
      return const SizedBox(
        width: _overlayControlSize,
        height: _overlayControlSize,
      );
    }

    return IconButton(
      onPressed: _controlsLocked ? null : _toggleFlash,
      style: _overlayIconButtonStyle(highlighted: _flashOn).copyWith(
        foregroundColor: WidgetStatePropertyAll(
          _flashOn ? accent.withValues(alpha: 0.98) : Colors.white,
        ),
      ),
      icon: Icon(
        _flashOn ? CarzonIcons.flashOn : CarzonIcons.flashOff,
        size: 22,
      ),
    );
  }

  Widget _buildSwitchControl() {
    if (!_canSwitchCamera) {
      return const SizedBox(
        width: _overlayControlSize,
        height: _overlayControlSize,
      );
    }

    return IconButton(
      onPressed: _controlsLocked ? null : _switchCamera,
      style: _overlayIconButtonStyle(),
      icon: Icon(CarzonIcons.switchCamera, size: 22),
    );
  }

  Widget _buildPreviewBody(AppLocalizations l10n, ThemeData theme) {
    if (_initializing) {
      return ColoredBox(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: Colors.white.withValues(alpha: 0.92),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.messagingCameraInitializing,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.88),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return ColoredBox(
        color: Colors.black,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _errorMessage(l10n),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ),
        ),
      );
    }

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return ColoredBox(
        color: Colors.black,
        child: Center(
          child: Text(
            l10n.messagingCameraUnavailable,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.88),
            ),
          ),
        ),
      );
    }

    return _buildCameraPreviewCover(controller);
  }

  /// Matches [CameraPreview]'s portrait vs landscape aspect handling.
  double _effectivePreviewAspectRatio(CameraController controller) {
    final rawAspectRatio = controller.value.aspectRatio;
    return _isPreviewLandscape(controller)
        ? rawAspectRatio
        : (1 / rawAspectRatio);
  }

  bool _isPreviewLandscape(CameraController controller) {
    final orientation = controller.value.isRecordingVideo
        ? controller.value.recordingOrientation!
        : (controller.value.previewPauseOrientation ??
              controller.value.lockedCaptureOrientation ??
              controller.value.deviceOrientation);
    return orientation == DeviceOrientation.landscapeLeft ||
        orientation == DeviceOrientation.landscapeRight;
  }

  /// Full-bleed cover preview: uniform scale preserves aspect ratio and crops overflow.
  Widget _buildCameraPreviewCover(CameraController controller) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final previewAspectRatio = _effectivePreviewAspectRatio(controller);
        final containerAspectRatio =
            constraints.maxWidth / constraints.maxHeight;

        final scale = containerAspectRatio > previewAspectRatio
            ? containerAspectRatio / previewAspectRatio
            : previewAspectRatio / containerAspectRatio;

        return ClipRect(
          child: Center(
            child: Transform.scale(
              scale: scale,
              child: CameraPreview(controller),
            ),
          ),
        );
      },
    );
  }
}
