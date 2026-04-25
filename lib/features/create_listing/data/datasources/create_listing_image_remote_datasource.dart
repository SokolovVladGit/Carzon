import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/entities/cover_image_upload.dart';

/// Only this class talks to Supabase Storage for listing cover images.
/// All other layers must receive the final public URL as a plain
/// `String` and remain Supabase-agnostic.
///
/// This datasource is shared between create-listing and edit-listing:
/// both features upload to the same `listing-images` bucket under
/// `listings/<sellerId>/...`. Edit-listing additionally asks for a
/// best-effort cleanup of a previous cover object via
/// [deleteByPublicUrl] when a new cover is uploaded or the cover is
/// removed. Cleanup is strictly scoped to the caller's own folder.
abstract interface class CreateListingImageRemoteDataSource {
  /// Uploads [upload.bytes] to the `listing-images` bucket under
  /// `listings/<sellerId>/...` with a collision-resistant object name,
  /// and returns the resulting public URL.
  Future<String> uploadCover(CoverImageUpload upload);

  /// Best-effort delete of a cover object that was previously uploaded
  /// via [uploadCover]. Only deletes objects that belong to the
  /// caller's own folder (`listings/<sellerId>/...`) inside the
  /// `listing-images` bucket. Any object outside this scope — in
  /// particular arbitrary external URLs or another user's folder —
  /// is silently skipped. Network/Storage errors are swallowed; this
  /// method never throws.
  Future<void> deleteByPublicUrl({
    required String publicUrl,
    required String sellerId,
  });
}

class SupabaseCreateListingImageRemoteDataSource
    implements CreateListingImageRemoteDataSource {
  SupabaseCreateListingImageRemoteDataSource(this._supabase);

  final SupabaseService _supabase;

  static const String _bucket = 'listing-images';
  static const String _rootPrefix = 'listings';

  /// Test seam: allow tests to exercise [deleteByPublicUrl] path
  /// derivation without wiring a live Storage client.
  static String? extractStoragePathFromPublicUrl(
    String publicUrl, {
    String bucket = _bucket,
  }) {
    final Uri uri;
    try {
      uri = Uri.parse(publicUrl);
    } catch (_) {
      return null;
    }
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;
    final segs = uri.pathSegments;
    // Supabase public-URL shape:
    //   /storage/v1/object/public/<bucket>/<object-path...>
    // We locate the `<bucket>` segment and require the preceding
    // segment to be exactly `public`. This rejects signed URLs
    // (`/object/sign/`) and any shape that does not place the bucket
    // directly after the `public` marker — both of which can point at
    // objects that our RLS delete policy would refuse to touch.
    for (var i = 1; i < segs.length; i++) {
      if (segs[i] == bucket && segs[i - 1] == 'public') {
        if (i + 1 >= segs.length) return null;
        final path = segs.sublist(i + 1).join('/');
        // Guard against trailing-slash URLs whose tail segment is an
        // empty string — `join('/')` would produce an empty path,
        // which we must not hand to Storage delete.
        if (path.isEmpty) return null;
        return path;
      }
    }
    return null;
  }

  /// Only two content types are honored in MVP: jpeg and png.
  /// Anything else is normalized to jpeg with a `.jpg` extension — the
  /// storage policy does not care about the extension, it enforces the
  /// owner folder instead, so a fallback is safe.
  static const Map<String, String> _extByContentType = {
    'image/jpeg': 'jpg',
    'image/jpg': 'jpg',
    'image/png': 'png',
  };

  @override
  Future<String> uploadCover(CoverImageUpload upload) async {
    if (upload.sellerId.isEmpty) {
      // Defensive — the cubit already guards on auth state, but we must
      // never produce a path with an empty owner segment because the
      // storage policy would then accept it only for an unauth'd caller.
      throw ServerException('Cannot upload cover without a seller id.');
    }
    if (upload.bytes.isEmpty) {
      throw ServerException('Selected image is empty.');
    }

    final normalizedType = upload.contentType.toLowerCase().trim();
    final ext = _extByContentType[normalizedType] ?? 'jpg';
    final storageContentType =
        _extByContentType.containsKey(normalizedType) ? normalizedType : 'image/jpeg';

    final path = _buildObjectPath(sellerId: upload.sellerId, ext: ext);

    try {
      await _supabase.client.storage.from(_bucket).uploadBinary(
            path,
            upload.bytes,
            fileOptions: sb.FileOptions(
              contentType: storageContentType,
              upsert: false,
            ),
          );
      return _supabase.client.storage.from(_bucket).getPublicUrl(path);
    } on sb.StorageException catch (e, st) {
      // RLS rejection surfaces as StorageException with a 4xx status.
      throw ServerException(e.message, cause: e, stackTrace: st);
    } catch (e, st) {
      throw ServerException('Failed to upload cover image.',
          cause: e, stackTrace: st);
    }
  }

  @override
  Future<void> deleteByPublicUrl({
    required String publicUrl,
    required String sellerId,
  }) async {
    if (sellerId.isEmpty) return;
    final trimmedUrl = publicUrl.trim();
    if (trimmedUrl.isEmpty) return;
    final path = extractStoragePathFromPublicUrl(trimmedUrl);
    if (path == null) return;
    // Only touch objects under the caller's own folder. Storage RLS
    // would also refuse anything else, but enforcing it client-side
    // avoids a needless round-trip and keeps the intent explicit.
    final ownerPrefix = '$_rootPrefix/$sellerId/';
    if (!path.startsWith(ownerPrefix)) return;
    try {
      await _supabase.client.storage.from(_bucket).remove([path]);
    } on sb.StorageException {
      // Best-effort: storage 4xx (e.g. already gone) is not surfaced
      // to the caller — the main DB operation has already succeeded
      // and the orphan object, if any, is an accepted MVP tradeoff.
    } catch (_) {
      // Same as above: swallow any unexpected error from the Storage
      // SDK so cleanup failures can never flip a successful cover
      // update into a user-visible error.
    }
  }

  /// Builds `listings/<sellerId>/<yyyyMMddHHmmssSSS>_<rand>.<ext>`.
  /// The random suffix is 12 hex chars from `dart:math` — enough for
  /// MVP collision safety without pulling in a uuid package.
  static String _buildObjectPath({
    required String sellerId,
    required String ext,
  }) {
    final now = DateTime.now().toUtc();
    final ts = '${_pad4(now.year)}${_pad2(now.month)}${_pad2(now.day)}'
        '${_pad2(now.hour)}${_pad2(now.minute)}${_pad2(now.second)}'
        '${_pad3(now.millisecond)}';
    final rand = _randomHex(12);
    return '$_rootPrefix/$sellerId/${ts}_$rand.$ext';
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
