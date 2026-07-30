import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommentImageService {
  final SupabaseClient _supabase = Supabase.instance.client;

  static String bucketName = 'comment-images';

  Future<void> uploadImages({
    required int commentId,
    required List<XFile> images,
  }) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw AuthException('You must be logged in to upload images.');
    }

    final existingImages = await _supabase
        .from('comment_images')
        .select('id')
        .eq('comment_id', commentId);

    final remainingSlots = 5 - existingImages.length;

    if (remainingSlots <= 0) {
      throw StateError('This comment already has 5 images.');
    }

    for (final image in images.take(remainingSlots)) {
      final Uint8List bytes = await image.readAsBytes();
      final extension = _getFileExtension(image.name);
      final uniqueName = '${DateTime.now().microsecondsSinceEpoch}.$extension';
      final storagePath = '${user.id}/$uniqueName';

      await _supabase.storage.from(bucketName).uploadBinary(
        storagePath,
        bytes,
        fileOptions: FileOptions(
          contentType: _getContentType(extension),
          upsert: false,
        ),
      );

      final imageUrl = _supabase.storage
          .from(bucketName)
          .getPublicUrl(storagePath);

      await _supabase.from('comment_images').insert({
        'comment_id': commentId,
        'user_id': user.id,
        'storage_path': storagePath,
        'image_url': imageUrl,
      });
    }
  }

  Future<void> deleteImage({
    required int imageId,
    required String storagePath,
  }) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw AuthException('You must be logged in to delete an image.');
    }

    await _supabase.storage.from(bucketName).remove([storagePath]);

    await _supabase
        .from('comment_images')
        .delete()
        .eq('id', imageId)
        .eq('user_id', user.id);
  }

  String _getFileExtension(String fileName) {
    final parts = fileName.split('.');

    if (parts.length < 2) {
      return 'jpg';
    }

    final extension = parts.last.toLowerCase();
    final allowedExtensions = ['jpg', 'jpeg', 'png', 'webp'];

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
      default:
        return 'image/jpeg';
    }
  }
}
