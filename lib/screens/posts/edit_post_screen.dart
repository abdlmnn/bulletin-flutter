import 'package:bulletin/providers/post_provider.dart';
import 'package:bulletin/services/post_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:bulletin/models/post.dart';

class EditPostScreen extends StatefulWidget {
  final int id;
  const EditPostScreen({super.key, required this.id});
  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final PostService _postService = PostService();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  Post? _post;
  bool _isLoadingPost = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadPost();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadPost() async {
    try {
      final post = await _postService.getPostById(widget.id);

      if (!mounted) {
        return;
      }

      setState(() {
        _post = post;
        _titleController.text = post.title;
        _contentController.text = post.content;
      });
    } catch (error, stackTrace) {
      debugPrint('Load post for editing error: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) {
        return;
      }

      setState(() {
        _loadError = 'Unable to load this post.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPost = false;
        });
      }
    }
  }

  Future<void> _updatePost() async {
    FocusScope.of(context).unfocus();

    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      return;
    }

    final postProvider = context.read<PostProvider>();

    final success = await postProvider.updatePost(
      id: widget.id,
      title: _titleController.text,
      content: _contentController.text,
    );

    if (!mounted) {
      return;
    }

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(postProvider.errorMessage ?? "Unable to update post."),
        ),
      );
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Post updated successfully.')));

    context.pop(true);
    return;
  }

  @override
  Widget build(BuildContext context) {
    final postProvider = context.watch<PostProvider>();

    if (_isLoadingPost) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_loadError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit post')),
        body: Center(child: Text(_loadError!)),
      );
    }

    if (_post == null) {
      return const Scaffold(body: Center(child: Text('Post not found.')));
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          tooltip: 'Back to post details',
          onPressed: () {
            context.push('/post/${widget.id}');
          },
        ),
        title: Text('Update a post'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Center(
          child: SizedBox(
            width: 500,
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final title = value?.trim() ?? '';

                      if (title.isEmpty) {
                        return 'Title is required.';
                      }

                      if (title.length < 3) {
                        return 'Title must contain at least 3 characters.';
                      }

                      return null;
                    },
                  ),

                  SizedBox(height: 16),
                  TextFormField(
                    controller: _contentController,
                    minLines: 6,
                    maxLines: 10,
                    decoration: InputDecoration(
                      labelText: "What's on your mind?",
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final content = value?.trim() ?? '';

                      if (content.isEmpty) {
                        return 'Content is required.';
                      }

                      if (content.length < 10) {
                        return 'Content must contain at least 10 characters.';
                      }

                      return null;
                    },
                  ),

                  SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: FilledButton(
                      onPressed: postProvider.isLoading ? null : _updatePost,
                      child: postProvider.isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text('Save changes'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
