import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bulletin/models/post.dart';

class PostService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> deletePost(int id) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw const AuthApiException('You must be logged in to delete a post');
    }

    await _supabase.from('posts').delete().eq('id', id).eq('user_id', user.id);
  }

  Future<void> updatePost({
    required int id,
    required String title,
    required String content,
  }) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw const AuthApiException('You must be logged in to update a post');
    }

    await _supabase
        .from('posts')
        .update({
          'title': title.trim(),
          'content': content.trim(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id)
        .eq('user_id', user.id);
  }

  Future<Post> getPostById(int id) async {
    final response = await _supabase
        .from('posts')
        .select('''
                  *,
                  post_images (*)
                ''')
        .eq('id', id)
        .single();

    return Post.fromJson(response);
  }

  Future<List<Post>> getPosts() async {
    final response = await _supabase
        .from('posts')
        .select('''
                *,
                post_images (*)
              ''')
        .order('created_at', ascending: false);

    return response.map<Post>((json) => Post.fromJson(json)).toList();
  }

  Future<int> createPost({
    required String title,
    required String content,
  }) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw AuthApiException('You must logged in to create a post.');
    }

    final response = await _supabase
        .from('posts')
        .insert({
          'user_id': user.id,
          'title': title.trim(),
          'content': content.trim(),
        })
        .select('id')
        .single();

    return (response['id'] as num).toInt();
  }
}
