import 'dart:math';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/constants/chat_attachment_limits.dart';

/// Supabase Storage I/O for private `chat-attachments` bucket only.
abstract interface class ChatAttachmentRemoteDataSource {
  /// Current authenticated user id, or throws [ServerException].
  String currentUserIdOrThrow();

  /// Uploads [bytes] and returns the storage object path (not a public URL).
  Future<String> uploadChatAttachment({
    required String conversationId,
    required String uploaderId,
    required Uint8List bytes,
    required String mimeType,
    String? originalFileName,
  });

  /// Best-effort delete; never throws.
  Future<void> deleteByStoragePathBestEffort(String storagePath);

  /// Authenticated download of a private attachment object.
  Future<Uint8List> downloadBytes(String storagePath);
}

class SupabaseChatAttachmentRemoteDataSource
    implements ChatAttachmentRemoteDataSource {
  SupabaseChatAttachmentRemoteDataSource(this._supabase);

  final SupabaseService _supabase;

  static const String _bucket = ChatAttachmentLimits.storageBucket;
  static const String _rootPrefix = 'conversations';

  static const Map<String, String> _extByMimeType = {
    'image/jpeg': 'jpg',
    'image/png': 'png',
  };

  @override
  String currentUserIdOrThrow() {
    final id = _supabase.client.auth.currentUser?.id;
    if (id == null || id.isEmpty) {
      throw ServerException('Not authenticated.');
    }
    return id;
  }

  @override
  Future<String> uploadChatAttachment({
    required String conversationId,
    required String uploaderId,
    required Uint8List bytes,
    required String mimeType,
    String? originalFileName,
  }) async {
    if (uploaderId.isEmpty) {
      throw ServerException('Cannot upload attachment without a user id.');
    }
    if (bytes.isEmpty) {
      throw ServerException('Attachment image is empty.');
    }

    final normalizedType = mimeType.toLowerCase().trim();
    final ext = _extByMimeType[normalizedType];
    if (ext == null) {
      throw ServerException('Unsupported attachment mime type.');
    }

    final path = buildStoragePath(
      conversationId: conversationId,
      uploaderId: uploaderId,
      ext: ext,
      originalFileName: originalFileName,
    );

    try {
      await _supabase.client.storage
          .from(_bucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: sb.FileOptions(
              contentType: normalizedType,
              upsert: false,
            ),
          );
      return path;
    } on sb.StorageException catch (e, st) {
      throw ServerException(e.message, cause: e, stackTrace: st);
    } catch (e, st) {
      throw ServerException(
        'Failed to upload chat attachment.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<void> deleteByStoragePathBestEffort(String storagePath) async {
    final path = storagePath.trim();
    if (path.isEmpty) return;
    if (path.contains('..')) return;
    if (!path.startsWith('$_rootPrefix/')) return;
    try {
      await _supabase.client.storage.from(_bucket).remove([path]);
    } on sb.StorageException {
      // Best-effort orphan cleanup.
    } catch (_) {}
  }

  @override
  Future<Uint8List> downloadBytes(String storagePath) async {
    final path = storagePath.trim();
    if (path.isEmpty) {
      throw ServerException('Attachment storage path is required.');
    }
    if (path.contains('..') || !path.startsWith('$_rootPrefix/')) {
      throw ServerException('Invalid attachment storage path.');
    }
    try {
      return await _supabase.client.storage.from(_bucket).download(path);
    } on sb.StorageException catch (e, st) {
      throw ServerException(e.message, cause: e, stackTrace: st);
    } catch (e, st) {
      throw ServerException(
        'Failed to download chat attachment.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// `conversations/<conversationId>/<uploaderId>/<timestamp>_<rand>.<ext>`
  static String buildStoragePath({
    required String conversationId,
    required String uploaderId,
    required String ext,
    String? originalFileName,
  }) {
    final safeName = _sanitizeFilenameHint(originalFileName, ext: ext);
    if (safeName != null) {
      return '$_rootPrefix/$conversationId/$uploaderId/$safeName';
    }
    final now = DateTime.now().toUtc();
    final ts =
        '${_pad4(now.year)}${_pad2(now.month)}${_pad2(now.day)}'
        '${_pad2(now.hour)}${_pad2(now.minute)}${_pad2(now.second)}'
        '${_pad3(now.millisecond)}';
    final rand = _randomHex(12);
    return '$_rootPrefix/$conversationId/$uploaderId/${ts}_$rand.$ext';
  }

  static String? _sanitizeFilenameHint(String? raw, {required String ext}) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    final base = trimmed.split('/').last.split('\\').last;
    if (base.isEmpty || base.contains('..')) return null;
    final lower = base.toLowerCase();
    if (lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png')) {
      return base.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    }
    return '${base.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_')}.$ext';
  }

  static String _pad2(int n) => n.toString().padLeft(2, '0');
  static String _pad3(int n) => n.toString().padLeft(3, '0');
  static String _pad4(int n) => n.toString().padLeft(4, '0');

  static String _randomHex(int chars) {
    final rng = Random.secure();
    final buf = StringBuffer();
    for (var i = 0; i < chars; i++) {
      buf.write(rng.nextInt(16).toRadixString(16));
    }
    return buf.toString();
  }
}
