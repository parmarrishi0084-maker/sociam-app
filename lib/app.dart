import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/auth/auth_page.dart';
import 'features/home/home_page.dart';

class SociamApp extends StatelessWidget {
  final bool configurationMissing;
  const SociamApp({super.key, this.configurationMissing = false});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Sociam',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF2563EB)),
    home: configurationMissing ? const _ConfigPage() : const _AuthGate(),
  );
}

class _ConfigPage extends StatelessWidget {
  const _ConfigPage();
  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(
      child: Text('Sociam\nSupabase configuration is missing.',
        textAlign: TextAlign.center),
    ),
  );
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();
  @override
  Widget build(BuildContext context) {
    final auth = Supabase.instance.client.auth;
    return StreamBuilder<AuthState>(
      stream: auth.onAuthStateChange,
      builder: (context, snapshot) =>
          auth.currentSession == null ? const AuthPage() : const HomePage(),
    );
  }
}
