import 'package:bulletin/models/comment.dart';
import 'package:bulletin/providers/auth_provider.dart';
import 'package:bulletin/providers/comment_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CommentsSection extends StatefulWidget {
  final int postId;

  const CommentsSection({super.key, required this.postId});

  @override
  State<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<CommentsSection> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      if (mounted) {
        context.read<CommentProvider>().fetchComments(postId: widget.postId);
      }
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _createComment() async {
    FocusScope.of(context).unfocus();

    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      return;
    }

    final commentProvider = context.read<CommentProvider>();

    final success = await commentProvider.createComment(
      postId: widget.postId,
      content: _commentController.text,
    );

    if (!mounted) {
      return;
    }

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            commentProvider.errorMessage ?? 'Unable to add comment.',
          ),
        ),
      );

      return;
    }

    _commentController.clear();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Comment added successfully.')));
  }

  Future<void> _editComment(Comment comment) async {
    String editedContent = comment.content;
    final editController = TextEditingController(text: editedContent);

    final updatedContent = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Edit comment'),
          content: TextField(
            controller: editController,
            minLines: 2,
            maxLines: 5,
            maxLength: 1000,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Update your comment...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final content = editController.text.trim();

                if (content.isEmpty) {
                  return;
                }

                Navigator.of(dialogContext).pop(content);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );

    editController.dispose();

    if (updatedContent == null || !mounted) {
      return;
    }

    if (updatedContent == comment.content.trim()) {
      return;
    }

    final commentProvider = context.read<CommentProvider>();

    final success = await commentProvider.updateComment(
      commentId: comment.id,
      content: updatedContent,
    );

    if (!mounted) {
      return;
    }

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            commentProvider.errorMessage ?? 'Unable to update comment.',
          ),
        ),
      );

      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Comment updated successfully.')));
  }

  Future<void> _confirmDeleteComment(Comment comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Delete comment?'),
          content: Text('This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final commentProvider = context.read<CommentProvider>();

    final success = await commentProvider.deleteComment(commentId: comment.id);

    if (!mounted) {
      return;
    }

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            commentProvider.errorMessage ?? 'Unable to delete comment.',
          ),
        ),
      );

      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Comment deleted successfully.')));
  }

  Future<void> _refreshComments() async {
    await context.read<CommentProvider>().fetchComments(postId: widget.postId);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final commentProvider = context.watch<CommentProvider>();

    final user = authProvider.currentUser;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(height: 48),

        Text('Comments', style: Theme.of(context).textTheme.titleLarge),

        if (user != null) ...[
          SizedBox(height: 16),
          _buildCommentForm(commentProvider),
        ],

        SizedBox(height: 24),

        _buildComments(commentProvider),
      ],
    );
  }

  Widget _buildCommentForm(CommentProvider commentProvider) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TextFormField(
            controller: _commentController,
            enabled: !commentProvider.isSubmitting,
            minLines: 2,
            maxLines: 5,
            maxLength: 1000,
            decoration: InputDecoration(
              hintText: 'Write a comment...',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              final content = value?.trim() ?? '';

              if (content.isEmpty) {
                return 'Comment cannot be empty.';
              }

              return null;
            },
          ),

          SizedBox(height: 8),

          FilledButton.icon(
            onPressed: commentProvider.isSubmitting ? null : _createComment,
            icon: commentProvider.isSubmitting
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.send),
            label: Text(
              commentProvider.isSubmitting ? 'Posting...' : 'Post comment',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComments(CommentProvider commentProvider) {
    if (commentProvider.isLoading) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (commentProvider.errorMessage != null &&
        commentProvider.comments.isEmpty) {
      return Center(
        child: Column(
          children: [
            Text(commentProvider.errorMessage!),

            SizedBox(height: 12),

            FilledButton(onPressed: _refreshComments, child: Text('Try again')),
          ],
        ),
      );
    }

    if (commentProvider.comments.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(24),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text('No comments yet.'),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: commentProvider.comments.length,
      separatorBuilder: (_, _) => SizedBox(height: 12),
      itemBuilder: (context, index) {
        final comment = commentProvider.comments[index];

        return _buildCommentCard(comment, commentProvider);
      },
    );
  }

  Widget _buildCommentCard(Comment comment, CommentProvider commentProvider) {
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.currentUser?.id;

    final isOwner = currentUserId == comment.userId;

    // final wasEdited =
    //     comment.updatedAt.difference(comment.createdAt).inSeconds > 1;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(child: Icon(Icons.person)),

                SizedBox(width: 10),

                Expanded(
                  child: Text(
                    isOwner ? 'You' : comment.displayName,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),

                Text(
                  _formatDate(comment.createdAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),

                if (isOwner)
                  PopupMenuButton<String>(
                    enabled: !commentProvider.isSubmitting,
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editComment(comment);
                      }

                      if (value == 'delete') {
                        _confirmDeleteComment(comment);
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

            SizedBox(height: 12),

            Text(comment.content),

            // if (wasEdited) ...[
            //   SizedBox(height: 8),
            //   Text('Edited', style: Theme.of(context).textTheme.bodySmall),
            // ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final localDate = date.toLocal();

    final year = localDate.year.toString();
    final month = localDate.month.toString().padLeft(2, '0');
    final day = localDate.day.toString().padLeft(2, '0');

    final hour = localDate.hour.toString().padLeft(2, '0');
    final minute = localDate.minute.toString().padLeft(2, '0');

    return '$year-$month-$day $hour:$minute';
  }
}
