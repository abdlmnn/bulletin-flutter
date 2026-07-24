import 'package:bulletin/router.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const BulletinApp());
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
    );
  }
}
