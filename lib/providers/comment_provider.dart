import 'package:bulletin/models/comment.dart';
import 'package:bulletin/services/comment_service.dart';
import 'package:flutter/material.dart';

class CommentProvider extends ChangeNotifier {
  final CommentService _commentService = CommentService();

  final List<Comment> _comments = [];

  bool _isLoading = false;
  bool _isSubmitting = false;

  String? _errorMessage;

  List<Comment> get comments => List.unmodifiable(_comments);

  bool get isLoading => _isLoading;

  bool get isSubmitting => _isSubmitting;

  String? get errorMessage => _errorMessage;

  Future<void> fetchComments({required int postId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final comments = await _commentService.getComments(postId: postId);

      _comments
        ..clear()
        ..addAll(comments);
    } catch (error, stackTrace) {
      debugPrint('Fetch comments error: $error');

      debugPrintStack(stackTrace: stackTrace);

      _errorMessage = 'Unable to load comments.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createComment({
    required int postId,
    required String content,
  }) async {
    if (_isSubmitting) {
      return false;
    }

    final trimmedContent = content.trim();

    if (trimmedContent.isEmpty) {
      _errorMessage = 'Comment cannot be empty.';
      notifyListeners();

      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final comment = await _commentService.createComment(
        postId: postId,
        content: trimmedContent,
      );

      _comments.add(comment);

      return true;
    } catch (error, stackTrace) {
      debugPrint('Create comment error: $error');

      debugPrintStack(stackTrace: stackTrace);

      _errorMessage = 'Unable to create comment.';

      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> updateComment({
    required int commentId,
    required String content,
  }) async {
    if (_isSubmitting) {
      return false;
    }

    final trimmedContent = content.trim();

    if (trimmedContent.isEmpty) {
      _errorMessage = 'Comment cannot be empty.';
      notifyListeners();

      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedComment = await _commentService.updateComment(
        commentId: commentId,
        content: trimmedContent,
      );

      final commentIndex = _comments.indexWhere(
        (comment) => comment.id == commentId,
      );

      if (commentIndex != -1) {
        _comments[commentIndex] = updatedComment;
      }

      return true;
    } catch (error, stackTrace) {
      debugPrint('Update comment error: $error');

      debugPrintStack(stackTrace: stackTrace);

      _errorMessage = 'Unable to update comment.';

      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> deleteComment({required int commentId}) async {
    if (_isSubmitting) {
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _commentService.deleteComment(commentId: commentId);

      _comments.removeWhere((comment) => comment.id == commentId);

      return true;
    } catch (error, stackTrace) {
      debugPrint('Delete comment error: $error');

      debugPrintStack(stackTrace: stackTrace);

      _errorMessage = 'Unable to delete comment.';

      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void clearComments() {
    _comments.clear();
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
