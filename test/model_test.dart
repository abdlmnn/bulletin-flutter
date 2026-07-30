import 'package:bulletin/models/comment.dart';
import 'package:bulletin/models/post.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Post parses multiple images', () {
    final post = Post.fromJson({
      'id': 1,
      'user_id': 'user-1',
      'email': 'author@example.com',
      'title': 'First post',
      'content': 'Post content',
      'created_at': '2026-07-30T10:00:00Z',
      'updated_at': '2026-07-30T10:00:00Z',
      'post_images': [
        {
          'id': 10,
          'post_id': 1,
          'user_id': 'user-1',
          'storage_path': 'user-1/post.jpg',
          'image_url': 'https://example.com/post.jpg',
          'created_at': '2026-07-30T10:00:00Z',
        },
      ],
    });

    expect(post.title, 'First post');
    expect(post.email, 'author@example.com');
    expect(post.images.length, 1);
    expect(post.images.first.postId, 1);
  });

  test('Comment parses email and multiple images', () {
    final comment = Comment.fromJson({
      'id': 2,
      'post_id': 1,
      'user_id': 'user-2',
      'content': 'Comment content',
      'email': 'abdul@example.com',
      'created_at': '2026-07-30T11:00:00Z',
      'updated_at': '2026-07-30T11:00:00Z',
      'comment_images': [
        {
          'id': 20,
          'comment_id': 2,
          'user_id': 'user-2',
          'storage_path': 'user-2/comment.jpg',
          'image_url': 'https://example.com/comment.jpg',
          'created_at': '2026-07-30T11:00:00Z',
        },
      ],
    });

    expect(comment.email, 'abdul@example.com');
    expect(comment.images.length, 1);
    expect(comment.images.first.commentId, 2);
  });
}
