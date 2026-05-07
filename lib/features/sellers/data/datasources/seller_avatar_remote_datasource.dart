import 'dart:math';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/supabase_service.dart';

/// Result of uploading a seller avatar object into Storage.
class SellerAvatarUploadPayload {
  const SellerAvatarUploadPayload({
    required this.storagePath,
    required this.publicUrl,
  });

  final String storagePath;
  final String publicUrl;
}

/// Seller avatar uploads for bucket `seller-avatars` under `avatars/<uid>/...`.
///
/// Listing imagery (`listing-images` / `listings/<sellerId>/...`) must never be used here.
abstract interface class SellerAvatarRemoteDataSource {
  Future<SellerAvatarUploadPayload> uploadAvatar({
    required Uint8List bytes,
    required String contentType,
  });

  /// Best-effort delete by exact storage path; never throws.
  Future<void> deleteByStoragePathBestEffort(String? storagePath);
}

class SupabaseSellerAvatarRemoteDataSource
    implements SellerAvatarRemoteDataSource {
  SupabaseSellerAvatarRemoteDataSource(this._supabase);

  final SupabaseService _supabase;

  static const String _bucket = 'seller-avatars';
  static const String _avatarsSegment = 'avatars';

  static const Map<String, String> _extByContentType = {
    'image/jpeg': 'jpg',
    'image/jpg': 'jpg',
    'image/png': 'png',
    'image/webp': 'webp',
  };

  String? _currentUserIdOrNull() {
    final id = _supabase.client.auth.currentUser?.id;
    if (id == null || id.isEmpty) return null;
    return id;
  }

  @override
  Future<SellerAvatarUploadPayload> uploadAvatar({
    required Uint8List bytes,
    required String contentType,
  }) async {
    final uid = _currentUserIdOrNull();
    if (uid == null) {
      throw ServerException('Not authenticated.');
    }
    if (bytes.isEmpty) {
      throw ServerException('Selected image is empty.');
    }

    final normalizedType = contentType.toLowerCase().trim();
    final ext = _extByContentType[normalizedType];
    if (ext == null) {
      throw ServerException('seller_avatar_unsupported_format');
    }
    final storageContentType = normalizedType;

    final path = _buildObjectPath(userId: uid, ext: ext);

    try {
      await _supabase.client.storage
          .from(_bucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: sb.FileOptions(
              contentType: storageContentType,
              upsert: false,
            ),
          );
      final url = _supabase.client.storage.from(_bucket).getPublicUrl(path);
      return SellerAvatarUploadPayload(storagePath: path, publicUrl: url);
    } on sb.StorageException catch (e, st) {
      throw ServerException(e.message, cause: e, stackTrace: st);
    } catch (e, st) {
      throw ServerException(
        'Failed to upload seller avatar.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<void> deleteByStoragePathBestEffort(String? storagePath) async {
    final p = storagePath?.trim();
    if (p == null || p.isEmpty) return;
    final uid = _currentUserIdOrNull();
    if (uid == null) return;
    final prefix = '$_avatarsSegment/$uid/';
    if (!p.startsWith(prefix) || p.contains('..')) return;
    try {
      await _supabase.client.storage.from(_bucket).remove([p]);
    } on sb.StorageException {
      // Best-effort — orphan acceptable for MVP.
    } catch (_) {}
  }

  /// `avatars/<userId>/<yyyyMMddHHmmssSSS>_<rand>.<ext>`
  static String _buildObjectPath({
    required String userId,
    required String ext,
  }) {
    final now = DateTime.now().toUtc();
    final ts =
        '${_pad4(now.year)}${_pad2(now.month)}${_pad2(now.day)}'
        '${_pad2(now.hour)}${_pad2(now.minute)}${_pad2(now.second)}'
        '${_pad3(now.millisecond)}';
    final rand = _randomHex(12);
    return '$_avatarsSegment/$userId/${ts}_$rand.$ext';
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
