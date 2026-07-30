class PostImage {
  final int id;
  final int postId;
  final String userId;
  final String storagePath;
  final String imageUrl;
  final DateTime createdAt;

  const PostImage({
    required this.id,
    required this.postId,
    required this.userId,
    required this.storagePath,
    required this.imageUrl,
    required this.createdAt,
  });

  factory PostImage.fromJson(Map<String, dynamic> json) {
    return PostImage(
      id: (json['id'] as num).toInt(),
      postId: (json['post_id'] as num).toInt(),
      userId: json['user_id'] as String,
      storagePath: json['storage_path'] as String,
      imageUrl: json['image_url'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
