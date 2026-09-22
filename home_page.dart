import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../create/create_post_page.dart';
import '../discover/discover_page.dart';
import '../connect/connect_page.dart';
import '../profile/profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> {
  int index = 0;
  final pages = const [
    FeedPage(), DiscoverPage(), CreatePostPage(), ConnectPage(), ProfilePage()
  ];
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Sociam')),
    body: pages[index],
    bottomNavigationBar: NavigationBar(
      selectedIndex: index,
      onDestinationSelected: (v) => setState(() => index = v),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.explore_outlined), label: 'Discover'),
        NavigationDestination(icon: Icon(Icons.add_box_outlined), label: 'Create'),
        NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: 'Connect'),
        NavigationDestination(icon: Icon(Icons.person_outline), label: 'Me'),
      ],
    ),
  );
}

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});
  @override State<FeedPage> createState() => _FeedPageState();
}
class _FeedPageState extends State<FeedPage> {
  Future<List<Map<String, dynamic>>> load() async {
    final data = await Supabase.instance.client
      .from('posts')
      .select('id,content,image_url,created_at,profiles(username,full_name,avatar_url)')
      .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }
  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: load(),
    builder: (context, snap) {
      if (snap.connectionState == ConnectionState.waiting)
        return const Center(child: CircularProgressIndicator());
      if (snap.hasError)
        return Center(child: Text('Feed error: ${snap.error}'));
      final posts = snap.data ?? <Map<String, dynamic>>[];
      if (posts.isEmpty)
        return const Center(child: Text('No posts yet. Create the first post!'));
      return RefreshIndicator(
        onRefresh: () async => setState(() {}),
        child: ListView.builder(
          itemCount: posts.length,
          itemBuilder: (context, i) {
            final p = posts[i];
            final profile = p['profiles'] as Map<String, dynamic>?;
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(profile?['full_name'] ?? profile?['username'] ?? 'User'),
                subtitle: Text(p['content'] ?? ''),
              ),
            );
          },
        ),
      );
    },
  );
}
