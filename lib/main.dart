import 'dart:io';

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
    final result = await InternetAddress.lookup(
      'djscbctzxwzcnolyraes.supabase.co',
    );

    if (result.isEmpty) {
      throw const SocketException('DNS lookup returned no address');
    }

    await Supabase.initialize(
      url: url,
      anonKey: key,
    );

    runApp(const SociamApp());
  } catch (e) {
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Sociam Network Test Failed:\n\n$e',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
