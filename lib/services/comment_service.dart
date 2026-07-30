import 'package:bulletin/models/comment.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommentService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Comment>> getComments({required int postId}) async {
    final response = await _supabase
        .from('comments')
        .select('''
          *,
          profile:profiles!comments_user_id_profiles_fkey (
            display_name
          )
        ''')
        .eq('post_id', postId)
        .order('created_at', ascending: true);

    return response.map<Comment>((json) {
      return Comment.fromJson(json);
    }).toList();
  }

  Future<Comment> createComment({
    required int postId,
    required String content,
  }) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw AuthApiException('You must be logged in to comment.');
    }

    final trimmedContent = content.trim();

    if (trimmedContent.isEmpty) {
      throw ArgumentError('Comment content cannot be empty.');
    }

    final response = await _supabase
        .from('comments')
        .insert({
          'post_id': postId,
          'user_id': user.id,
          'content': trimmedContent,
        })
        .select('''
          *,
          profile:profiles!comments_user_id_profiles_fkey (
            display_name
          )
        ''')
        .single();

    return Comment.fromJson(response);
  }

  Future<Comment> updateComment({
    required int commentId,
    required String content,
  }) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw AuthApiException('You must be logged in to update a comment.');
    }

    final trimmedContent = content.trim();

    if (trimmedContent.isEmpty) {
      throw ArgumentError('Comment content cannot be empty.');
    }

    final response = await _supabase
        .from('comments')
        .update({
          'content': trimmedContent,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', commentId)
        .eq('user_id', user.id)
        .select('''
          *,
          profile:profiles!comments_user_id_profiles_fkey (
            display_name
          )
        ''')
        .single();

    return Comment.fromJson(response);
  }

  Future<void> deleteComment({required int commentId}) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw AuthApiException('You must be logged in to delete a comment.');
    }

    await _supabase
        .from('comments')
        .delete()
        .eq('id', commentId)
        .eq('user_id', user.id);
  }
}
