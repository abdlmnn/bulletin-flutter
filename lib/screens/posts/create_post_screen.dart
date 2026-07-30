import 'package:bulletin/providers/post_provider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'dart:typed_data';
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
        _selectedImages.addAll(images);
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
      spacing: 12,
      runSpacing: 12,
      children: List.generate(_selectedImages.length, (index) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: FutureBuilder<Uint8List>(
                future: _selectedImages[index].readAsBytes(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      width: 120,
                      height: 120,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snapshot.hasError || !snapshot.hasData) {
                    return Container(
                      width: 120,
                      height: 120,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border.all(),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.broken_image_outlined),
                    );
                  }

                  return Image.memory(
                    snapshot.data!,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  );
                },
              ),
            ),

            Positioned(
              top: -10,
              right: -10,
              child: IconButton.filled(
                tooltip: 'Remove image',
                onPressed: () => _removeSelectedImage(index),
                icon: Icon(Icons.close, size: 18),
              ),
            ),
          ],
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final postProvider = context.watch<PostProvider>();
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          tooltip: 'Back to posts',
          onPressed: () {
            context.go('/');
          },
        ),
        title: Text('Create a post'),
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
                    child: OutlinedButton.icon(
                      onPressed: _selectedImages.length >= 5
                          ? null
                          : _pickImages,
                      icon: Icon(Icons.add_photo_alternate_outlined),
                      label: Text('Add images ${_selectedImages.length}/5'),
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
