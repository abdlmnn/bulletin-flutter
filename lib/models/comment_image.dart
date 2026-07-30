class CommentImage {
  final int id;
  final int commentId;
  final String userId;
  final String storagePath;
  final String imageUrl;
  final DateTime createdAt;

  const CommentImage({
    required this.id,
    required this.commentId,
    required this.userId,
    required this.storagePath,
    required this.imageUrl,
    required this.createdAt,
  });

  factory CommentImage.fromJson(Map<String, dynamic> json) {
    return CommentImage(
      id: (json['id'] as num).toInt(),
      commentId: (json['comment_id'] as num).toInt(),
      userId: json['user_id'] as String,
      storagePath: json['storage_path'] as String,
      imageUrl: json['image_url'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
