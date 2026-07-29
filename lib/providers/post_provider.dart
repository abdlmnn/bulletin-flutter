import 'package:bulletin/models/post.dart';
import 'package:bulletin/services/post_service.dart';
import 'package:flutter/foundation.dart';

class PostProvider extends ChangeNotifier {
  final PostService _postService = PostService();

  List<Post> _posts = [];

  bool _isLoading = false;
  String? _errorMessage;

  List<Post> get posts => _posts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> deletePost(int id) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _postService.deletePost(id);

      _posts.removeWhere((post) => post.id == id);

      return true;
    } catch (error, stackTrace) {
      debugPrint('Update post error: $error');
      debugPrintStack(stackTrace: stackTrace);

      _errorMessage = error.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updatePost({
    required int id,
    required String title,
    required String content,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _postService.updatePost(id: id, title: title, content: content);

      _posts = await _postService.getPosts();

      return true;
    } catch (error, stackTrace) {
      debugPrint('Update post error: $error');
      debugPrintStack(stackTrace: stackTrace);

      _errorMessage = error.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createPost({
    required String title,
    required String content,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _postService.createPost(title: title, content: content);

      _posts = await _postService.getPosts();

      return true;
    } catch (error, stackTrace) {
      debugPrint('Create post error: $error');
      debugPrintStack(stackTrace: stackTrace);

      _errorMessage = error.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchPosts() async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _posts = await _postService.getPosts();
    } catch (error, stackTrace) {
      debugPrint('Fetch posts error: $error');
      debugPrintStack(stackTrace: stackTrace);

      _errorMessage = error.toString();
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
