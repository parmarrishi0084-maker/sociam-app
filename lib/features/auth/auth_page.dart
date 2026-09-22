import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  @override State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  final name = TextEditingController();
  bool signup = false, loading = false;

  Future<void> submit() async {
    final e = email.text.trim();
    final p = password.text;
    if (e.isEmpty || p.length < 6 || (signup && name.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid account details.')),
      );
      return;
    }
    setState(() => loading = true);
    try {
      final auth = Supabase.instance.client.auth;
      if (signup) {
        final result = await auth.signUp(
          email: e,
          password: p,
          data: {'full_name': name.text.trim()},
        );
        if (mounted && result.session == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account created. Check your email if confirmation is enabled.')),
          );
        }
      } else {
        await auth.signInWithPassword(email: e, password: p);
      }
    } on AuthException catch (err) {
      if (mounted) ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(err.message)));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    email.dispose(); password.dispose(); name.dispose(); super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Sociam')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('તમારી દુનિયા, તમારી રીતે.',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(signup ? 'Create your Sociam account' : 'Welcome back'),
        const SizedBox(height: 28),
        if (signup) TextField(
          controller: name,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Full name', border: OutlineInputBorder()),
        ),
        if (signup) const SizedBox(height: 12),
        TextField(
          controller: email,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: password,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Password', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: loading ? null : submit,
          child: Text(loading ? 'Please wait...' : signup ? 'Create account' : 'Login'),
        ),
        TextButton(
          onPressed: loading ? null : () => setState(() => signup = !signup),
          child: Text(signup ? 'Already have an account? Login' : 'Create a new account'),
        ),
      ],
    ),
  );
}
