import 'package:bulletin/models/comment_image.dart';

class Comment {
  final int id;
  final int postId;
  final String userId;
  final String content;
  final String email;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<CommentImage> images;

  const Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.content,
    required this.email,
    required this.createdAt,
    required this.updatedAt,
    required this.images,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    final rawImages = json['comment_images'] as List<dynamic>? ?? [];

    return Comment(
      id: json['id'] as int,
      postId: json['post_id'] as int,
      userId: json['user_id'] as String,
      content: json['content'] as String,
      email: json['email'] as String? ?? 'Unknown email',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      images: rawImages.map((image) {
        return CommentImage.fromJson(image as Map<String, dynamic>);
      }).toList(),
    );
  }
}
