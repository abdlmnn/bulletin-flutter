import 'package:bulletin/providers/post_provider.dart';
import 'package:bulletin/services/post_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bulletin/models/post.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:bulletin/widgets/comments_section.dart';

class PostDetailScreen extends StatefulWidget {
  final int id;

  const PostDetailScreen({super.key, required this.id});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final PostService _postService = PostService();

  Post? _post;

  bool _isLoading = true;

  String? _errorMessage;

  String? get _currentUserId {
    return Supabase.instance.client.auth.currentUser?.id;
  }

  @override
  void initState() {
    super.initState();

    _loadPost();
  }

  Future<void> _loadPost() async {
    setState(() {
      _isLoading = true;

      _errorMessage = null;
    });

    try {
      final post = await _postService.getPostById(widget.id);

      if (!mounted) {
        return;
      }

      setState(() {
        _post = post;
      });
    } catch (error, stackTrace) {
      debugPrint('Load post detail error: $error');

      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Unable to load this post.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    final localDate = date.toLocal();
    final period = localDate.hour >= 12 ? 'PM' : 'AM';
    final hour = localDate.hour % 12 == 0 ? 12 : localDate.hour % 12;

    return '${localDate.month}/${localDate.day}/${localDate.year} '
        '$hour:${localDate.minute.toString().padLeft(2, '0')} $period';
  }

  Future<void> _confirmDeletePost() async {
    final post = _post;

    if (post == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Delete post?'),
          content: Text('This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text('Cancel'),
            ),

            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final postProvider = context.read<PostProvider>();

    final success = await postProvider.deletePost(post.id);

    if (!mounted) {
      return;
    }

    if (!success) {
      final errorMessage =
          postProvider.errorMessage ?? 'Unable to delete post.';

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));

      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Post deleted successfully.')));

    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 64,
        titleSpacing: 24,
        leading: Padding(
          padding: EdgeInsets.only(left: 8),
          child: IconButton(
            icon: Icon(Icons.arrow_back_ios),
            tooltip: 'Back to posts',
            onPressed: () {
              context.go('/');
            },
          ),
        ),
        title: Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: EdgeInsets.only(right: 16),
            child: Text('View Post'),
          ),
        ),
      ),

      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),

          child: Column(
            mainAxisSize: MainAxisSize.min,

            children: [
              Text(_errorMessage!, textAlign: TextAlign.center),

              const SizedBox(height: 16),

              FilledButton(
                onPressed: _loadPost,

                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    final post = _post;

    if (post == null) {
      return Center(child: Text('Post not found.'));
    }

    final isOwner = _currentUserId == post.userId;

    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Center(
        child: SizedBox(
          width: 700,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      post.title,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  if (isOwner)
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          context.go('/post/${post.id}/edit');
                        }

                        if (value == 'delete') {
                          _confirmDeletePost();
                        }
                      },
                      itemBuilder: (context) {
                        return [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline),
                                SizedBox(width: 8),
                                Text('Delete'),
                              ],
                            ),
                          ),
                        ];
                      },
                    ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                post.email,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 2),
              Text(
                _formatDate(post.createdAt),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              SizedBox(height: 24),
              Text(post.content, style: Theme.of(context).textTheme.bodyLarge),
              if (post.images.isNotEmpty) ...[
                SizedBox(height: 24),
                _buildPostImages(post),
              ],
              CommentsSection(postId: post.id),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostImages(Post post) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: post.images.map((postImage) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            postImage.imageUrl,
            width: 220,
            height: 180,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) {
                return child;
              }

              return SizedBox(
                width: 220,
                height: 180,
                child: Center(child: CircularProgressIndicator()),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 220,
                height: 180,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.broken_image_outlined, size: 40),
              );
            },
          ),
        );
      }).toList(),
    );
  }
}
