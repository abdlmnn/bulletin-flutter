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

    return '${localDate.month}/${localDate.day}/${localDate.year} '
        '${localDate.hour.toString().padLeft(2, '0')}:'
        '${localDate.minute.toString().padLeft(2, '0')}';
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
    final post = _post;

    final isOwner = post != null && _currentUserId == post.userId;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          tooltip: 'Back to posts',
          onPressed: () {
            context.go('/');
          },
        ),
        title: Text('Post Details'),
        actions: [
          if (isOwner) ...[
            IconButton(
              tooltip: 'Edit post',
              icon: Icon(Icons.edit),
              onPressed: () async {
                // edit logic
              },
            ),

            IconButton(
              tooltip: 'Delete post',
              icon: Icon(Icons.delete_outline),
              onPressed: _confirmDeletePost,
            ),
          ],
        ],
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

    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Center(
        child: SizedBox(
          width: 700,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              SizedBox(height: 8),
              Text(
                'Posted ${_formatDate(post.createdAt)}',
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
