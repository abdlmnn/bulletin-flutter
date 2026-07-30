import 'package:bulletin/providers/post_provider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:bulletin/services/post_image_service.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});
  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();
  final PostImageService _postImageService = PostImageService();
  final List<XFile> _selectedImages = [];
  bool _isUploading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    const maximumImages = 5;

    final remainingSlots = maximumImages - _selectedImages.length;

    if (remainingSlots <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can only add up to 5 images.')),
      );

      return;
    }

    try {
      final images = await _imagePicker.pickMultiImage(
        imageQuality: 85,
        limit: remainingSlots,
      );

      if (images.isEmpty || !mounted) {
        return;
      }

      setState(() {
        _selectedImages.addAll(images.take(remainingSlots));
      });
    } catch (error, stackTrace) {
      debugPrint('Pick images error: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unable to select images.')));
    }
  }

  void _removeSelectedImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _createPost() async {
    FocusScope.of(context).unfocus();

    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid || _isUploading) {
      return;
    }

    setState(() {
      _isUploading = true;
    });

    final postProvider = context.read<PostProvider>();

    try {
      final postId = await postProvider.createPost(
        title: _titleController.text,
        content: _contentController.text,
      );

      if (!mounted) {
        return;
      }

      if (postId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              postProvider.errorMessage ?? "Unable to create post.",
            ),
          ),
        );

        return;
      }

      if (_selectedImages.isNotEmpty) {
        await _postImageService.uploadImages(
          postId: postId,
          images: _selectedImages,
        );
      }

      await postProvider.fetchPosts();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Post created successfully.')));

      context.go('/');
    } catch (error, stackTrace) {
      debugPrint('Post image upload error: $error');
      debugPrintStack(stackTrace: stackTrace);

      await postProvider.fetchPosts();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The post was created, but an image failed to upload.'),
        ),
      );

      context.go('/');
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Widget _buildSelectedImages() {
    if (_selectedImages.isEmpty) {
      return SizedBox.shrink();
    }

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
            _removeSelectedImage(index);
          },
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final postProvider = context.watch<PostProvider>();
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
            child: Text('Create Post'),
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

                  SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        IconButton.outlined(
                          tooltip: 'Add images (maximum 5)',
                          onPressed: _selectedImages.length >= 5
                              ? null
                              : _pickImages,
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

                  if (_selectedImages.isNotEmpty) ...[
                    SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _buildSelectedImages(),
                    ),
                  ],

                  SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: FilledButton(
                      onPressed: postProvider.isLoading || _isUploading
                          ? null
                          : _createPost,
                      child: _isUploading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Publish post'),
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
