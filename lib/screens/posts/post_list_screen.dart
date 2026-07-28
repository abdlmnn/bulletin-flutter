import 'package:bulletin/providers/auth_provider.dart';
import 'package:bulletin/providers/post_provider.dart';
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
        title: Text(
          user == null ? 'Bulletin' : user.email ?? 'Bulletin',
          style: TextStyle(fontSize: 18),
        ),
        actions: [
          if (user == null)
            TextButton(
              onPressed: () {
                context.go('/login');
              },
              child: Text('Login'),
            )
            
          else
            Row(
              children: [
                TextButton(
                  onPressed: () => context.go('/post/create'),
                  child: authProvider.isLoading
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('Create a post'),
                ),

                TextButton(
                  onPressed: authProvider.isLoading ? null : () => _logout(),
                  child: authProvider.isLoading
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('Logout'),
                ),
              ],
            ),
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
      child: ListView.separated(
        padding: EdgeInsets.all(16),
        itemCount: postProvider.posts.length,
        separatorBuilder: (_, _) => SizedBox(height: 12),

        itemBuilder: (context, index) {
          final post = postProvider.posts[index];

          return Card(
            child: ListTile(
              title: Text(post.title),
              subtitle: Text(
                post.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/post/${post.id}'),
            ),
          );
        },
      ),
    );
  }
}
