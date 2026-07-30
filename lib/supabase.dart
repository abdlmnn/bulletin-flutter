import 'package:flutter/services.dart';

class SupabaseConfig {
  static String url = String.fromEnvironment('SUPABASE_URL');

  static String publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  static Future<void> initialize() async {
    if (url.isNotEmpty && publishableKey.isNotEmpty) {
      return;
    }

    final envFile = await rootBundle.loadString('.env');
    final values = <String, String>{};

    for (final line in envFile.split('\n')) {
      final trimmedLine = line.trim();

      if (trimmedLine.isEmpty || trimmedLine.startsWith('#')) {
        continue;
      }

      final separatorIndex = trimmedLine.indexOf('=');

      if (separatorIndex == -1) {
        continue;
      }

      final key = trimmedLine.substring(0, separatorIndex).trim();
      final value = trimmedLine.substring(separatorIndex + 1).trim();

      values[key] = value;
    }

    url = values['SUPABASE_URL'] ?? '';
    publishableKey = values['SUPABASE_PUBLISHABLE_KEY'] ?? '';
  }

  static void validate() {
    if (url.isEmpty || publishableKey.isEmpty) {
      throw StateError(
        'Missing Supabase configuration. '
        'Check that SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY exist in .env.',
      );
    }
  }
}
