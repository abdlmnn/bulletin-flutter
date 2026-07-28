import 'package:bulletin/screens/auth/login_screen.dart';
import 'package:bulletin/screens/auth/register_screen.dart';
import 'package:bulletin/screens/posts/create_post_screen.dart';
import 'package:bulletin/screens/posts/post_list_screen.dart';
import 'package:go_router/go_router.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) {
        return PostListScreen();
      },
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) {
        return LoginScreen();
      },
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) {
        return RegisterScreen();
      },
    ),
    GoRoute(
      path: '/post/create',
      builder: (context, state) {
        return CreatePostScreen();
      },
    ),
  ],
);
