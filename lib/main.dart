import 'package:bulletin/providers/auth_provider.dart';
import 'package:bulletin/providers/comment_provider.dart';
import 'package:bulletin/providers/post_provider.dart';
import 'package:bulletin/router.dart';
import 'package:bulletin/supabase.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  SupabaseConfig.validate();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PostProvider()),
        ChangeNotifierProvider(create: (_) => CommentProvider()),
      ],
      child: const BulletinApp(),
    ),
  );
}

class BulletinApp extends StatelessWidget {
  const BulletinApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Bulletin',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      theme: ThemeData(
        appBarTheme: AppBarTheme(
          actionsPadding: EdgeInsets.only(right: 8),
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
    );
  }
}
