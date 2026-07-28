import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bulletin/models/post.dart';

class PostService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Post>> getPosts() async {
    final response = await _supabase
        .from('posts')
        .select()
        .order('created_at', ascending: false);

    return response.map<Post>((json) => Post.fromJson(json)).toList();
  }

  Future<void> createPost({
    required String title,
    required String content,
  }) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw AuthApiException('You must logged in to create a post.');
    }

    await _supabase.from('post').insert({
      'user_id': user.id,
      'title': title.trim(),
      'content': content.trim(),
    });
  }
}
