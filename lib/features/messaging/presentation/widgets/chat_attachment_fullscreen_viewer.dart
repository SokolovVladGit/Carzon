import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Fullscreen private chat image viewer with pinch-zoom.
class ChatAttachmentFullscreenViewer extends StatelessWidget {
  const ChatAttachmentFullscreenViewer({super.key, required this.bytes});

  final Uint8List bytes;

  static Future<void> open(BuildContext context, {required Uint8List bytes}) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => ChatAttachmentFullscreenViewer(bytes: bytes),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: Image.memory(bytes, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
