import 'package:bulletin/models/post_image.dart';

class Post {
  final int id;
  final String? userId;
  final String email;
  final String title;
  final String content;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<PostImage> images;

  const Post({
    required this.id,
    required this.userId,
    required this.email,
    required this.title,
    required this.content,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.images,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    final rawImages = json['post_images'] as List<dynamic>? ?? [];
    return Post(
      id: json['id'] as int,
      userId: json['user_id'] as String?,
      email: json['email'] as String? ?? 'Unknown email',
      title: json['title'] as String,
      content: json['content'] as String,
      imageUrl: json['image_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      images: rawImages.map((image) {
        return PostImage.fromJson(image as Map<String, dynamic>);
      }).toList(),
    );
  }
}
