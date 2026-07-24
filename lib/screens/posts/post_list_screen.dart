import "package:flutter/material.dart";
import 'package:go_router/go_router.dart';

class PostListScreen extends StatelessWidget {
  const PostListScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bulletin'),
        actions: [
          TextButton(
            onPressed: () {
              context.go('/login');
            },
            child: Text('Login'),
          ),
        ],
      ),
      body: Center(
        child: Text(
          'Public posts will apear here.',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
