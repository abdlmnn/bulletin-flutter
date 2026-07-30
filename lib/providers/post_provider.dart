import 'package:bulletin/models/post.dart';
import 'package:bulletin/services/post_service.dart';
import 'package:flutter/foundation.dart';

class PostProvider extends ChangeNotifier {
  final PostService _postService = PostService();

  List<Post> _posts = [];

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;
  final int pageSize = 5;

  List<Post> get posts => _posts;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;

  Future<bool> deletePost(int id) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _postService.deletePost(id);

      _posts.removeWhere((post) => post.id == id);

      return true;
    } catch (error, stackTrace) {
      debugPrint('Delete post error: $error');
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

      _posts = await _postService.getPosts(from: 0, limit: pageSize);
      _hasMore = _posts.length == pageSize;

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

  Future<int?> createPost({
    required String title,
    required String content,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final id = await _postService.createPost(title: title, content: content);

      return id;
    } catch (error, stackTrace) {
      debugPrint('Create post error: $error');
      debugPrintStack(stackTrace: stackTrace);

      _errorMessage = error.toString();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchPosts() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _posts = await _postService.getPosts(from: 0, limit: pageSize);
      _hasMore = _posts.length == pageSize;
    } catch (error, stackTrace) {
      debugPrint('Fetch posts error: $error');
      debugPrintStack(stackTrace: stackTrace);

      _errorMessage = error.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadMorePosts() async {
    if (_isLoading || _isLoadingMore || !_hasMore) {
      return;
    }

    _isLoadingMore = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newPosts = await _postService.getPosts(
        from: _posts.length,
        limit: pageSize,
      );

      _posts.addAll(newPosts);
      _hasMore = newPosts.length == pageSize;
    } catch (error, stackTrace) {
      debugPrint('Load more posts error: $error');
      debugPrintStack(stackTrace: stackTrace);

      _errorMessage = error.toString();
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
