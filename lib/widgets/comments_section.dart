import 'package:bulletin/models/comment.dart';
import 'package:bulletin/models/comment_image.dart';
import 'package:bulletin/providers/auth_provider.dart';
import 'package:bulletin/providers/comment_provider.dart';
import 'package:bulletin/services/comment_image_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  final ImagePicker _imagePicker = ImagePicker();
  final CommentImageService _commentImageService = CommentImageService();
  final List<XFile> _selectedImages = [];
  int? _editingImagesCommentId;

  final int maximumImages = 5;

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

    final commentId = await commentProvider.createComment(
      postId: widget.postId,
      content: _commentController.text,
    );

    if (!mounted) {
      return;
    }

    if (commentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            commentProvider.errorMessage ?? 'Unable to add comment.',
          ),
        ),
      );

      return;
    }

    if (_selectedImages.isNotEmpty) {
      try {
        await _commentImageService.uploadImages(
          commentId: commentId,
          images: _selectedImages,
        );

        await commentProvider.fetchComments(postId: widget.postId);
      } catch (error, stackTrace) {
        debugPrint('Upload comment images error: $error');
        debugPrintStack(stackTrace: stackTrace);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'The comment was posted, but an image failed to upload.',
              ),
            ),
          );
        }
      }
    }

    if (!mounted) {
      return;
    }

    _commentController.clear();
    setState(() {
      _selectedImages.clear();
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Comment added successfully.')));
  }

  Future<List<XFile>> _pickImages(int currentImageCount) async {
    final remainingSlots = maximumImages - currentImageCount;

    if (remainingSlots <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You can only add up to 5 images.')),
      );

      return [];
    }

    try {
      return await _imagePicker.pickMultiImage(
        imageQuality: 85,
        limit: remainingSlots,
      );
    } catch (error, stackTrace) {
      debugPrint('Pick comment images error: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Unable to select images.')));
      }

      return [];
    }
  }

  Future<void> _pickNewCommentImages() async {
    final images = await _pickImages(_selectedImages.length);

    if (!mounted || images.isEmpty) {
      return;
    }

    setState(() {
      final remainingSlots = maximumImages - _selectedImages.length;
      _selectedImages.addAll(images.take(remainingSlots));
    });
  }

  Future<void> _addImagesToComment(Comment comment) async {
    final images = await _pickImages(comment.images.length);

    if (!mounted || images.isEmpty) {
      return;
    }

    final commentProvider = context.read<CommentProvider>();

    try {
      final remainingSlots = maximumImages - comment.images.length;

      await _commentImageService.uploadImages(
        commentId: comment.id,
        images: images.take(remainingSlots).toList(),
      );

      await commentProvider.fetchComments(postId: widget.postId);
    } catch (error, stackTrace) {
      debugPrint('Add comment images error: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to add images to this comment.')),
        );
      }
    }
  }

  Future<void> _deleteCommentImage(CommentImage image) async {
    final commentProvider = context.read<CommentProvider>();

    try {
      await _commentImageService.deleteImage(
        imageId: image.id,
        storagePath: image.storagePath,
      );

      await commentProvider.fetchComments(postId: widget.postId);
    } catch (error, stackTrace) {
      debugPrint('Delete comment image error: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to delete this image.')),
        );
      }
    }
  }

  Future<void> _editComment(Comment comment) async {
    String editedContent = comment.content;

    final updatedContent = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Edit comment'),
          content: TextFormField(
            initialValue: comment.content,
            onChanged: (value) {
              editedContent = value;
            },
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
                final content = editedContent.trim();

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

          Row(
            children: [
              IconButton.outlined(
                tooltip: 'Add images (maximum 5)',
                onPressed: _selectedImages.length >= maximumImages
                    ? null
                    : _pickNewCommentImages,
                icon: Icon(Icons.add_photo_alternate_outlined),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Maximum 5 images',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              IconButton.filled(
                tooltip: 'Post comment',
                onPressed: commentProvider.isSubmitting
                    ? null
                    : _createComment,
                icon: commentProvider.isSubmitting
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.send),
              ),
            ],
          ),

          if (_selectedImages.isNotEmpty) ...[
            SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: _buildSelectedImages(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectedImages() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(_selectedImages.length, (index) {
        return InputChip(
          avatar: Icon(Icons.image_outlined),
          label: Text(
            _selectedImages[index].name,
            overflow: TextOverflow.ellipsis,
          ),
          onDeleted: () {
            setState(() {
              _selectedImages.removeAt(index);
            });
          },
        );
      }),
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
    final isEditingImages = _editingImagesCommentId == comment.id;

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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.email,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 2),
                      Text(
                        _formatDate(comment.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                if (isOwner)
                  PopupMenuButton<String>(
                    enabled: !commentProvider.isSubmitting,
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editComment(comment);
                      }

                      if (value == 'edit_images') {
                        setState(() {
                          _editingImagesCommentId = comment.id;
                        });
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
                          value: 'edit_images',
                          child: Row(
                            children: [
                              Icon(Icons.photo_library_outlined),
                              SizedBox(width: 8),
                              Text('Edit images'),
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

            if (comment.images.isNotEmpty) ...[
              SizedBox(height: 12),
              _buildCommentImages(comment, isOwner && isEditingImages),
            ],

            if (isOwner && isEditingImages) ...[
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  if (comment.images.length < maximumImages)
                    IconButton(
                      tooltip: 'Add images (maximum 5)',
                      onPressed: commentProvider.isSubmitting
                          ? null
                          : () {
                              _addImagesToComment(comment);
                            },
                      icon: Icon(Icons.add_photo_alternate_outlined),
                    ),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _editingImagesCommentId = null;
                      });
                    },
                    icon: Icon(Icons.check),
                    label: Text('Done editing'),
                  ),
                ],
              ),
            ],

            // if (wasEdited) ...[
            //   SizedBox(height: 8),
            //   Text('Edited', style: Theme.of(context).textTheme.bodySmall),
            // ],
          ],
        ),
      ),
    );
  }

  Widget _buildCommentImages(Comment comment, bool showRemoveButton) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: comment.images.map((image) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                image.imageUrl,
                width: 110,
                height: 100,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 110,
                    height: 100,
                    alignment: Alignment.center,
                    child: Icon(Icons.broken_image_outlined),
                  );
                },
              ),
            ),
            if (showRemoveButton)
              Positioned(
                top: -10,
                right: -10,
                child: IconButton.filled(
                  onPressed: () {
                    _deleteCommentImage(image);
                  },
                  icon: Icon(Icons.close, size: 16),
                ),
              ),
          ],
        );
      }).toList(),
    );
  }

  String _formatDate(DateTime date) {
    final localDate = date.toLocal();

    final year = localDate.year.toString();
    final month = localDate.month.toString().padLeft(2, '0');
    final day = localDate.day.toString().padLeft(2, '0');

    final period = localDate.hour >= 12 ? 'PM' : 'AM';
    final hour = localDate.hour % 12 == 0 ? 12 : localDate.hour % 12;
    final minute = localDate.minute.toString().padLeft(2, '0');

    return '$year-$month-$day $hour:$minute $period';
  }
}
