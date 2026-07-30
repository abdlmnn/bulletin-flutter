import 'package:bulletin/providers/post_provider.dart';
import 'package:bulletin/services/post_service.dart';
import 'package:bulletin/services/post_image_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:bulletin/models/post.dart';

import 'package:image_picker/image_picker.dart';
import 'package:bulletin/models/post_image.dart';

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

  final ImagePicker _imagePicker = ImagePicker();
  final PostImageService _postImageService = PostImageService();
  final List<XFile> _newImages = [];
  final List<PostImage> _existingImages = [];
  final List<PostImage> _imagesToDelete = [];

  Post? _post;

  bool _isSaving = false;
  bool _isLoadingPost = true;

  String? _loadError;

  static const int _maximumImages = 5;

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
    setState(() {
      _isLoadingPost = true;
      _loadError = null;
    });

    try {
      final post = await _postService.getPostById(widget.id);

      if (!mounted) {
        return;
      }

      setState(() {
        _post = post;
        _titleController.text = post.title;
        _contentController.text = post.content;

        _existingImages
          ..clear()
          ..addAll(post.images);

        _imagesToDelete.clear();
        _newImages.clear();
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

  Future<void> _pickNewImages() async {
    final currentImageCount = _existingImages.length + _newImages.length;

    final remainingSlots = _maximumImages - currentImageCount;

    if (remainingSlots <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You can only add up to 5 images.')),
      );

      return;
    }

    try {
      final images = await _imagePicker.pickMultiImage(
        imageQuality: 85,
        limit: remainingSlots,
      );

      if (!mounted || images.isEmpty) {
        return;
      }

      setState(() {
        _newImages.addAll(images.take(remainingSlots));
      });
    } catch (error, stackTrace) {
      debugPrint('Pick new images error: $error');

      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to select images.')));
    }
  }

  void _removeExistingImage(PostImage image) {
    setState(() {
      _existingImages.removeWhere(
        (existingImage) => existingImage.id == image.id,
      );

      final alreadyMarkedForDeletion = _imagesToDelete.any(
        (deletedImage) => deletedImage.id == image.id,
      );

      if (!alreadyMarkedForDeletion) {
        _imagesToDelete.add(image);
      }
    });
  }

  void _restoreExistingImage(PostImage image) {
    setState(() {
      _imagesToDelete.removeWhere(
        (deletedImage) => deletedImage.id == image.id,
      );

      final alreadyRestored = _existingImages.any(
        (existingImage) => existingImage.id == image.id,
      );

      if (!alreadyRestored) {
        _existingImages.add(image);
      }
    });
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
    });
  }

  Future<void> _updatePost() async {
    FocusScope.of(context).unfocus();

    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid || _isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final postProvider = context.read<PostProvider>();

    try {
      final success = await postProvider.updatePost(
        id: widget.id,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
      );

      if (!success) {
        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              postProvider.errorMessage ?? 'Unable to update post.',
            ),
          ),
        );

        return;
      }

      final imagesToDelete = List<PostImage>.from(_imagesToDelete);

      for (final image in imagesToDelete) {
        await _postImageService.deleteImage(
          imageId: image.id,
          storagePath: image.storagePath,
        );

        _imagesToDelete.removeWhere(
          (deletedImage) => deletedImage.id == image.id,
        );
      }

      if (_newImages.isNotEmpty) {
        await _postImageService.uploadImages(
          postId: widget.id,
          images: _newImages,
        );

        _newImages.clear();
      }

      await postProvider.fetchPosts();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Post updated successfully.')));

      context.go('/post/${widget.id}');
    } catch (error, stackTrace) {
      debugPrint('Update post error: $error');

      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'The post was updated, but the remaining changes could not be completed.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _buildExistingImages() {
    if (_existingImages.isEmpty) {
      return SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _existingImages.map((image) {
        return InputChip(
          avatar: Icon(Icons.image_outlined),
          label: Text(
            image.storagePath.split('/').last,
            overflow: TextOverflow.ellipsis,
          ),
          onDeleted: _isSaving
              ? null
              : () {
                  _removeExistingImage(image);
                },
        );
      }).toList(),
    );
  }

  Widget _buildNewImages() {
    if (_newImages.isEmpty) {
      return SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(_newImages.length, (index) {
        final image = _newImages[index];

        return InputChip(
          avatar: Icon(Icons.image_outlined),
          label: Text(image.name, overflow: TextOverflow.ellipsis),
          onDeleted: _isSaving
              ? null
              : () {
                  _removeNewImage(index);
                },
        );
      }),
    );
  }

  Widget _buildImagesMarkedForDeletion() {
    if (_imagesToDelete.isEmpty) {
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 20),
        Text('Images to remove', style: Theme.of(context).textTheme.titleSmall),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _imagesToDelete.map((image) {
            return ActionChip(
              avatar: Icon(Icons.undo, size: 18),
              label: Text(
                'Restore ${image.storagePath.split('/').last}',
                overflow: TextOverflow.ellipsis,
              ),
              onPressed: _isSaving
                  ? null
                  : () {
                      _restoreExistingImage(image);
                    },
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingPost) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_loadError != null) {
      return Scaffold(
        appBar: AppBar(title: Text('Edit post')),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_loadError!),
                SizedBox(height: 16),
                FilledButton(onPressed: _loadPost, child: Text('Try again')),
              ],
            ),
          ),
        ),
      );
    }

    if (_post == null) {
      return Scaffold(body: Center(child: Text('Post not found.')));
    }

    final currentImageCount = _existingImages.length + _newImages.length;

    final hasImages = _existingImages.isNotEmpty || _newImages.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 64,
        titleSpacing: 24,
        leading: Padding(
          padding: EdgeInsets.only(left: 8),
          child: IconButton(
            icon: Icon(Icons.arrow_back_ios_new),
            tooltip: 'Back to post details',
            onPressed: _isSaving
                ? null
                : () {
                    context.go('/post/${widget.id}');
                  },
          ),
        ),
        title: Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: EdgeInsets.only(right: 16),
            child: Text('Edit Post'),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Center(
          child: SizedBox(
            width: 500,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _titleController,
                    enabled: !_isSaving,
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
                    enabled: !_isSaving,
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
                  SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        IconButton.outlined(
                          tooltip: 'Add images (maximum 5)',
                          onPressed:
                              _isSaving ||
                                  currentImageCount >= _maximumImages
                              ? null
                              : _pickNewImages,
                          icon: Icon(Icons.add_photo_alternate_outlined),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Maximum 5 images',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (hasImages) ...[
                    SizedBox(height: 20),
                    _buildExistingImages(),
                    if (_existingImages.isNotEmpty && _newImages.isNotEmpty)
                      SizedBox(height: 12),
                    _buildNewImages(),
                  ],
                  _buildImagesMarkedForDeletion(),
                  SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: FilledButton(
                      onPressed: _isSaving ? null : _updatePost,
                      child: _isSaving
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
