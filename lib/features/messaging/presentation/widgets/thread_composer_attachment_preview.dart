import 'dart:typed_data';

import 'package:flutter/material.dart';

class ThreadComposerAttachmentPreview extends StatelessWidget {
  const ThreadComposerAttachmentPreview({
    super.key,
    required this.bytes,
    required this.removeLabel,
    required this.onRemove,
  });

  final Uint8List bytes;
  final String removeLabel;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              bytes,
              width: 72,
              height: 72,
              fit: BoxFit.cover,
            ),
          ),
          const Spacer(),
          TextButton(onPressed: onRemove, child: Text(removeLabel)),
        ],
      ),
    );
  }
}
