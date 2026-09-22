import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});
  @override State<CreatePostPage> createState() => _CreatePostPageState();
}
class _CreatePostPageState extends State<CreatePostPage> {
  final controller = TextEditingController();
  bool saving = false;
  Future<void> publish() async {
    final content = controller.text.trim();
    if (content.isEmpty) return;
    setState(() => saving = true);
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) throw Exception('Not signed in');
      await Supabase.instance.client.from('posts').insert({
        'user_id': uid, 'content': content
      });
      controller.clear();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post published')),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }
  @override
  void dispose(){ controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Text('Create', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      TextField(controller: controller, maxLines: 7,
        decoration: const InputDecoration(
          hintText: 'What do you want to share?', border: OutlineInputBorder())),
      const SizedBox(height: 12),
      FilledButton.icon(
        onPressed: saving ? null : publish,
        icon: const Icon(Icons.send),
        label: Text(saving ? 'Publishing...' : 'Publish post'),
      ),
      const SizedBox(height: 16),
      const Text('Photo • Short video • Thought • Place • Community post'),
    ],
  );
}
