import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const url = String.fromEnvironment('SUPABASE_URL');
  const key = String.fromEnvironment('SUPABASE_ANON_KEY');

  if (url.isEmpty || key.isEmpty) {
    runApp(const SociamApp(configurationMissing: true));
    return;
  }

  try {
    await Supabase.initialize(
      url: url,
      anonKey: key,
    );

    runApp(const SociamApp());
  } catch (e) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text(
              'Supabase connection error:\n$e',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
