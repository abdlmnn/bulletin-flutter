import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PostImageService {
  final SupabaseClient _supabase = Supabase.instance.client;

  static const String _bucketName = 'post-images';

  Future<void> deleteImage({
    required int imageId,
    required String storagePath,
  }) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw const AuthException('You must be logged in to delete an image.');
    }

    await _supabase.storage.from(_bucketName).remove([storagePath]);

    await _supabase
        .from('post_images')
        .delete()
        .eq('id', imageId)
        .eq('user_id', user.id);
  }

  Future<void> uploadImages({
    required int postId,
    required List<XFile> images,
  }) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw const AuthException('You must be logged in to upload images.');
    }

    for (final image in images) {
      final Uint8List bytes = await image.readAsBytes();
      final extension = _getFileExtension(image.name);
      final uniqueName = '${DateTime.now().microsecondsSinceEpoch}.$extension';
      final storagePath = '${user.id}/$uniqueName';

      await _supabase.storage
          .from(_bucketName)
          .uploadBinary(
            storagePath,
            bytes,
            fileOptions: FileOptions(
              contentType: _getContentType(extension),
              upsert: false,
            ),
          );

      final imageUrl = _supabase.storage
          .from(_bucketName)
          .getPublicUrl(storagePath);

      await _supabase.from('post_images').insert({
        'post_id': postId,
        'user_id': user.id,
        'storage_path': storagePath,
        'image_url': imageUrl,
      });
    }
  }

  String _getFileExtension(String fileName) {
    final parts = fileName.split('.');

    if (parts.length < 2) {
      return 'jpg';
    }

    final extension = parts.last.toLowerCase();

    const allowedExtensions = ['jpg', 'jpeg', 'png', 'webp'];

    if (!allowedExtensions.contains(extension)) {
      return 'jpg';
    }

    return extension;
  }

  String _getContentType(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }
}
