import 'package:bulletin/services/post_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bulletin/models/post.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
        title: const Text('Post Details'),
        actions: [
          if (isOwner)
            IconButton(
              tooltip: 'Edit post',

              icon: const Icon(Icons.edit),

              onPressed: () async {
                final updated = await context.push<bool>(
                  '/post/${_post!.id}/edit',
                );

                if (updated == true) {
                  await _loadPost();
                }
              },
            ),
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

                style: Theme.of(context).textTheme.headlineSmall,
              ),

              SizedBox(height: 24),

              Text(
                post.content,

                style: Theme.of(context).textTheme.headlineLarge,
              ),

              SizedBox(height: 32),

              Divider(),

              SizedBox(height: 16),

              Text(
                'Comments',

                style: Theme.of(context).textTheme.headlineLarge,
              ),

              SizedBox(height: 12),

              Text('No comments yet.'),
            ],
          ),
        ),
      ),
    );
  }
}
