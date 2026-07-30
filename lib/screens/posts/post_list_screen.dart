import 'package:bulletin/providers/auth_provider.dart';
import 'package:bulletin/providers/post_provider.dart';
import 'package:bulletin/widgets/post_card.dart';
import "package:flutter/material.dart";
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class PostListScreen extends StatefulWidget {
  const PostListScreen({super.key});
  @override
  State<PostListScreen> createState() => _PostListScreenState();
}

class _PostListScreenState extends State<PostListScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      if (mounted) context.read<PostProvider>().fetchPosts();
    });
  }

  Future<void> _logout() async {
    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.logout();

    if (!mounted) {
      return;
    }

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Logged out successfully.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final postProvider = context.watch<PostProvider>();
    final user = authProvider.currentUser;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 24,
        actionsPadding: EdgeInsets.only(right: 16),
        title: Text('Bulletin'),
        actions: [
          if (user == null)
            TextButton(
              onPressed: () {
                context.go('/login');
              },
              child: Text('Login'),
            )
          else ...[
            IconButton(
              tooltip: 'Create post',
              onPressed: () {
                context.go('/post/create');
              },
              icon: Icon(Icons.add),
            ),
            IconButton(
              tooltip: 'Logout',
              onPressed: authProvider.isLoading ? null : _logout,
              icon: Icon(Icons.logout),
            ),
          ],
        ],
      ),
      body: _buildBody(postProvider),
    );
  }

  Widget _buildBody(PostProvider postProvider) {
    if (postProvider.isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (postProvider.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(postProvider.errorMessage!),
            SizedBox(height: 12),
            FilledButton(
              onPressed: postProvider.fetchPosts,
              child: Text('Try again'),
            ),
          ],
        ),
      );
    }

    if (postProvider.posts.isEmpty) {
      return Center(
        child: Text('No posts yet', style: TextStyle(fontSize: 18)),
      );
    }

    return RefreshIndicator(
      onRefresh: postProvider.fetchPosts,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount:
            postProvider.posts.length + (postProvider.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == postProvider.posts.length) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: FilledButton(
                  onPressed: postProvider.isLoadingMore
                      ? null
                      : postProvider.loadMorePosts,
                  child: postProvider.isLoadingMore
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('Load more posts'),
                ),
              ),
            );
          }

          final post = postProvider.posts[index];

          return Padding(
            padding: EdgeInsets.only(bottom: 20),
            child: PostCard(
              post: post,
              onTap: () {
                context.push('/post/${post.id}');
              },
            ),
          );
        },
      ),
    );
  }
}
