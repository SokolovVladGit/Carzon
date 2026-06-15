import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/ui/carzon_icons.dart';
import '../../domain/constants/chat_attachment_limits.dart';
import '../../domain/entities/chat_attachment_upload.dart';
import '../bloc/conversation_thread_cubit.dart';
import '../bloc/conversation_thread_state.dart';
import '../utils/thread_attachment_mime.dart';
import '../utils/thread_attachment_source.dart';
import '../utils/thread_camera_capture_normalizer.dart';
import '../utils/thread_composer_attachment_draft.dart';
import 'thread_attachment_source_sheet.dart';
import 'thread_camera_capture_sheet.dart';
import 'thread_composer_attachment_preview.dart';

typedef ThreadImagePicker =
    Future<XFile?> Function({
      required ImageSource source,
      double? maxWidth,
      int? imageQuality,
    });

typedef ThreadCameraCapture = Future<XFile?> Function(BuildContext context);

typedef ThreadCameraCaptureNormalizerFn =
    Future<ThreadCameraCaptureNormalized?> Function(XFile file);

/// Thread composer: attachment pick/preview, caption field, send button.
class ThreadComposerBar extends StatefulWidget {
  const ThreadComposerBar({
    super.key,
    required this.conversationId,
    required this.textController,
    required this.onSendSucceeded,
    this.imagePicker,
    this.cameraCapture,
    this.cameraNormalizer,
  });

  final String conversationId;
  final TextEditingController textController;
  final VoidCallback onSendSucceeded;
  final ThreadImagePicker? imagePicker;
  final ThreadCameraCapture? cameraCapture;
  final ThreadCameraCaptureNormalizerFn? cameraNormalizer;

  @override
  State<ThreadComposerBar> createState() => _ThreadComposerBarState();
}

class _ThreadComposerBarState extends State<ThreadComposerBar> {
  final ImagePicker _defaultPicker = ImagePicker();
  ThreadComposerAttachmentDraft? _attachmentDraft;
  bool _pickingAttachment = false;

  static const double _galleryMaxWidth = 1920;
  static const int _galleryImageQuality = 85;

  @override
  void initState() {
    super.initState();
    widget.textController.addListener(_onComposerChanged);
  }

  @override
  void didUpdateWidget(covariant ThreadComposerBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.textController != widget.textController) {
      oldWidget.textController.removeListener(_onComposerChanged);
      widget.textController.addListener(_onComposerChanged);
    }
  }

  @override
  void dispose() {
    widget.textController.removeListener(_onComposerChanged);
    super.dispose();
  }

  void _onComposerChanged() => setState(() {});

  void _clearAttachmentDraft() {
    if (_attachmentDraft == null) return;
    setState(() => _attachmentDraft = null);
  }

  bool get _hasSendableText => widget.textController.text.trim().isNotEmpty;

  Future<void> _showAttachmentSourceSheet() async {
    if (_pickingAttachment) return;
    final source = await showThreadAttachmentSourceSheet(context);
    if (!mounted || source == null) return;

    switch (source) {
      case ThreadAttachmentSource.gallery:
        await _pickGalleryAttachment();
      case ThreadAttachmentSource.camera:
        await _captureCameraAttachment();
    }
  }

  void _applyAttachmentDraft({
    required Uint8List bytes,
    required String mimeType,
    String? filename,
  }) {
    final l10n = context.l10n;
    if (!ChatAttachmentLimits.allowedMimeTypes.contains(mimeType)) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(l10n.messagingAttachmentUnsupportedType)),
      );
      return;
    }
    if (bytes.length > ChatAttachmentLimits.maxBytes) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(l10n.messagingAttachmentTooLarge)),
      );
      return;
    }

    setState(
      () => _attachmentDraft = ThreadComposerAttachmentDraft(
        bytes: bytes,
        mimeType: mimeType,
        filename: filename,
      ),
    );
  }

  Future<void> _pickGalleryAttachment() async {
    if (_pickingAttachment) return;
    setState(() => _pickingAttachment = true);
    final l10n = context.l10n;
    try {
      final picker = widget.imagePicker ?? _defaultPicker.pickImage;
      final picked = await picker(
        source: ImageSource.gallery,
        maxWidth: _galleryMaxWidth,
        imageQuality: _galleryImageQuality,
      );
      if (picked == null || !mounted) return;

      final mimeType = resolveThreadAttachmentMimeType(picked);
      if (mimeType == null) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(content: Text(l10n.messagingAttachmentUnsupportedType)),
        );
        return;
      }

      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      _applyAttachmentDraft(
        bytes: bytes,
        mimeType: mimeType,
        filename: picked.name,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(l10n.imagePickerLoadFailed)),
      );
    } finally {
      if (mounted) setState(() => _pickingAttachment = false);
    }
  }

  Future<void> _captureCameraAttachment() async {
    if (_pickingAttachment) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _pickingAttachment = true);
    final l10n = context.l10n;
    try {
      final capture = widget.cameraCapture ?? showThreadCameraCaptureSheet;
      final captured = await capture(context);
      if (captured == null || !mounted) return;

      final normalizer = widget.cameraNormalizer ?? normalizeThreadCameraCapture;
      final normalized = await normalizer(captured);
      if (!mounted) return;
      if (normalized == null) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(content: Text(l10n.messagingCameraCaptureFailed)),
        );
        return;
      }

      _applyAttachmentDraft(
        bytes: normalized.bytes,
        mimeType: normalized.mimeType,
        filename: normalized.filename,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(l10n.messagingCameraCaptureFailed)),
      );
    } finally {
      if (mounted) setState(() => _pickingAttachment = false);
    }
  }

  void _handleSend() {
    final cubit = context.read<ConversationThreadCubit>();
    final draft = _attachmentDraft;
    if (draft != null) {
      final caption = widget.textController.text.trim();
      cubit.sendMessageWithAttachment(
        ChatAttachmentUpload(
          conversationId: widget.conversationId,
          bytes: draft.bytes,
          mimeType: draft.mimeType,
          caption: caption.isEmpty ? null : caption,
          filename: draft.filename,
        ),
      );
      return;
    }
    cubit.send(widget.textController.text);
  }

  BoxDecoration _composerFooterDecoration(ColorScheme cs) {
    final darkFooter = AppTheme.editorialDarkFilterFooter(cs);
    if (darkFooter != null) return darkFooter;

    return BoxDecoration(
      color: Color.alphaBlend(
        cs.primary.withValues(alpha: 0.035),
        Color.alphaBlend(
          cs.surfaceContainerLow.withValues(alpha: 0.52),
          cs.surface,
        ),
      ),
      border: Border(
        top: BorderSide(
          color: Color.lerp(cs.outlineVariant, cs.primary, 0.16)!
              .withValues(alpha: 0.44),
        ),
      ),
      boxShadow: [
        BoxShadow(
          color: cs.primary.withValues(alpha: 0.045),
          blurRadius: 20,
          offset: const Offset(0, -8),
          spreadRadius: -6,
        ),
        BoxShadow(
          color: cs.shadow.withValues(alpha: 0.055),
          blurRadius: 14,
          offset: const Offset(0, -3),
        ),
      ],
    );
  }

  Color _composerInputFillColor(ColorScheme cs, bool isDark) {
    if (isDark) {
      return Color.alphaBlend(
        cs.primary.withValues(alpha: 0.06),
        cs.surfaceContainerHigh,
      );
    }
    return Color.alphaBlend(
      cs.primary.withValues(alpha: 0.04),
      cs.surfaceContainerLowest,
    );
  }

  static const double _sideActionSize = 46;
  static const double _sideActionGap = 10;

  Widget _sideActionSlot({required Widget child}) {
    return SizedBox(
      width: _sideActionSize,
      height: _sideActionSize,
      child: Center(child: child),
    );
  }

  ButtonStyle _attachButtonStyle(
    ColorScheme cs,
    Color accent,
    bool isDark,
  ) {
    return IconButton.styleFrom(
      minimumSize: const Size(_sideActionSize, _sideActionSize),
      maximumSize: const Size(_sideActionSize, _sideActionSize),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.standard,
      shape: const CircleBorder(),
      backgroundColor: Color.alphaBlend(
        accent.withValues(alpha: isDark ? 0.14 : 0.10),
        isDark ? cs.surfaceContainerHigh : cs.surfaceContainerLow,
      ),
      disabledBackgroundColor: Color.alphaBlend(
        cs.onSurface.withValues(alpha: 0.05),
        cs.surfaceContainerHighest,
      ),
      foregroundColor: cs.onSurfaceVariant.withValues(
        alpha: isDark ? 0.90 : 0.82,
      ),
      disabledForegroundColor: cs.onSurfaceVariant.withValues(
        alpha: isDark ? 0.36 : 0.38,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final accent = AppTheme.editorialAccentColor(cs);

    return BlocListener<ConversationThreadCubit, ConversationThreadState>(
      listenWhen: (p, c) =>
          p.sending && !c.sending && c.lastSendFailureKind == null,
      listener: (_, _) {
        widget.onSendSucceeded();
        _clearAttachmentDraft();
      },
      child: DecoratedBox(
        decoration: _composerFooterDecoration(cs),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_attachmentDraft != null) ...[
              ThreadComposerAttachmentPreview(
                bytes: _attachmentDraft!.bytes,
                removeLabel: l10n.messagingAttachmentRemove,
                onRemove: _clearAttachmentDraft,
              ),
              Divider(
                height: 1,
                indent: 14,
                endIndent: 14,
                color: cs.outlineVariant.withValues(alpha: isDark ? 0.28 : 0.32),
              ),
            ],
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    BlocBuilder<ConversationThreadCubit, ConversationThreadState>(
                      builder: (context, state) {
                        final attachBusy = state.sending || _pickingAttachment;
                        return _sideActionSlot(
                          child: Tooltip(
                            message: l10n.messagingAttachImage,
                            child: IconButton(
                              onPressed: attachBusy
                                  ? null
                                  : _showAttachmentSourceSheet,
                              style: _attachButtonStyle(cs, accent, isDark),
                              icon: Icon(CarzonIcons.attach, size: 20),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: _sideActionGap),
                    Expanded(
                      child: TextField(
                        controller: widget.textController,
                        minLines: 1,
                        maxLines: 5,
                        maxLength: 4000,
                        textInputAction: TextInputAction.newline,
                        style: theme.textTheme.bodyLarge,
                        decoration: InputDecoration(
                          isDense: true,
                          filled: true,
                          fillColor: _composerInputFillColor(cs, isDark),
                          hintText: l10n.messagingComposerHint,
                          hintStyle: theme.textTheme.bodyLarge?.copyWith(
                            color: cs.onSurfaceVariant.withValues(
                              alpha: isDark ? 0.80 : 0.72,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                              color: isDark
                                  ? cs.outlineVariant.withValues(alpha: 0.40)
                                  : Color.lerp(
                                        cs.outlineVariant,
                                        cs.primary,
                                        0.12,
                                      )!
                                      .withValues(alpha: 0.42),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                              color: isDark
                                  ? AppTheme.editorialDarkFieldFocusBorder(cs)
                                  : cs.primary.withValues(alpha: 0.82),
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          counterText: '',
                        ),
                      ),
                    ),
                    const SizedBox(width: _sideActionGap),
                    BlocBuilder<ConversationThreadCubit, ConversationThreadState>(
                      builder: (context, state) {
                        final sending = state.sending;
                        final canSend =
                            (_hasSendableText || _attachmentDraft != null) &&
                            !sending &&
                            !_pickingAttachment;
                        return _sideActionSlot(
                          child: Tooltip(
                            message: l10n.messagingSend,
                            child: FilledButton(
                              onPressed: !canSend ? null : _handleSend,
                              style: FilledButton.styleFrom(
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                minimumSize: const Size(
                                  _sideActionSize,
                                  _sideActionSize,
                                ),
                                maximumSize: const Size(
                                  _sideActionSize,
                                  _sideActionSize,
                                ),
                                padding: EdgeInsets.zero,
                                shape: const CircleBorder(),
                                backgroundColor: accent,
                                foregroundColor: cs.onPrimary,
                                disabledBackgroundColor: Color.alphaBlend(
                                  cs.onSurface.withValues(
                                    alpha: isDark ? 0.08 : 0.06,
                                  ),
                                  isDark
                                      ? cs.surfaceContainerHigh
                                      : cs.surfaceContainerHighest,
                                ),
                                disabledForegroundColor: cs.onSurfaceVariant
                                    .withValues(alpha: isDark ? 0.38 : 0.40),
                                elevation: canSend ? 2 : 0,
                                shadowColor: accent.withValues(alpha: 0.38),
                              ),
                              child: sending
                                  ? SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: accent,
                                      ),
                                    )
                                  : Icon(CarzonIcons.send, size: 20),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
