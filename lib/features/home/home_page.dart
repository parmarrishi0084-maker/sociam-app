import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../create/create_post_page.dart';
import '../discover/discover_page.dart';
import '../connect/connect_page.dart';
import '../profile/profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int index = 0;

  final pages = const [
    FeedPage(),
    DiscoverPage(),
    CreatePostPage(),
    ConnectPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FC),
      body: SafeArea(
        child: pages[index],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        elevation: 8,
        selectedIndex: index,
        onDestinationSelected: (value) {
          setState(() {
            index = value;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Discover',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_box_outlined),
            selectedIcon: Icon(Icons.add_box),
            label: 'Create',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Connect',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Me',
          ),
        ],
      ),
    );
  }
}

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  Future<List<Map<String, dynamic>>> loadPosts() async {
    final data = await Supabase.instance.client
        .from('posts')
        .select(
          'id, content, image_url, video_url, created_at, '
          'profiles(username, full_name, avatar_url)',
        )
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> refreshFeed() async {
    setState(() {});
    await loadPosts();
  }

  String formatDate(String? value) {
    if (value == null) return '';

    final date = DateTime.tryParse(value);

    if (date == null) return '';

    final difference = DateTime.now().difference(date);

    if (difference.inSeconds < 60) {
      return 'Just now';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours}h';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays}d';
    }

    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: refreshFeed,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _buildHeader(),
          ),
          SliverToBoxAdapter(
            child: _buildFeedTabs(),
          ),
          SliverToBoxAdapter(
            child: _buildQuickCreate(),
          ),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: loadPosts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (snapshot.hasError) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Feed error:\n${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              }

              final posts = snapshot.data ?? [];

              if (posts.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(30),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.dynamic_feed_outlined,
                            size: 64,
                            color: Color(0xFF5B6FA6),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No posts yet',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Create the first post on Sociam.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return _PostCard(
                      post: posts[index],
                      timeText: formatDate(
                        posts[index]['created_at']?.toString(),
                      ),
                    );
                  },
                  childCount: posts.length,
                ),
              );
            },
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sociam',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'તમારી દુનિયા, તમારી રીતે.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          _CircleButton(
            icon: Icons.search,
            onTap: () {},
          ),
          const SizedBox(width: 8),
          _CircleButton(
            icon: Icons.notifications_none,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildFeedTabs() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEDEFFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _FeedTab(
            title: 'For You',
            selected: true,
          ),
          _FeedTab(
            title: 'Following',
            selected: false,
          ),
          _FeedTab(
            title: 'Nearby',
            selected: false,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickCreate() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 23,
            backgroundColor: Color(0xFFE0E7FF),
            child: Icon(
              Icons.person,
              color: Color(0xFF4F64A0),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'What are you thinking?',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 15,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CreatePostPage(),
                ),
              ).then((_) {
                if (mounted) {
                  setState(() {});
                }
              });
            },
            icon: const Icon(Icons.add_circle),
            color: const Color(0xFF536AA3),
          ),
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final String timeText;

  const _PostCard({
    required this.post,
    required this.timeText,
  });

  @override
  Widget build(BuildContext context) {
    final profile = post['profiles'] as Map<String, dynamic>?;

    final fullName = profile?['full_name']?.toString().trim();
    final username = profile?['username']?.toString().trim();

    final displayName =
        (fullName != null && fullName.isNotEmpty)
            ? fullName
            : (username != null && username.isNotEmpty)
                ? username
                : 'User';

    final content = post['content']?.toString() ?? '';
    final avatarUrl = profile?['avatar_url']?.toString();

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 6, 20, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _Avatar(
                  avatarUrl: avatarUrl,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        timeText,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.more_horiz),
                ),
              ],
            ),

            if (content.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                content,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.45,
                ),
              ),
            ],

            if (post['image_url'] != null &&
                post['image_url'].toString().isNotEmpty) ...[
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  post['image_url'].toString(),
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return Container(
                      height: 180,
                      color: const Color(0xFFEDEFFC),
                      child: const Center(
                        child: Icon(Icons.broken_image_outlined),
                      ),
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 14),

            const Divider(height: 1),

            const SizedBox(height: 8),

            Row(
              children: [
                _ActionButton(
                  icon: Icons.favorite_border,
                  label: 'Like',
                  onTap: () {},
                ),
                _ActionButton(
                  icon: Icons.chat_bubble_outline,
                  label: 'Comment',
                  onTap: () {},
                ),
                _ActionButton(
                  icon: Icons.share_outlined,
                  label: 'Share',
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? avatarUrl;

  const _Avatar({
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundImage: NetworkImage(avatarUrl!),
      );
    }

    return const CircleAvatar(
      radius: 24,
      backgroundColor: Color(0xFFE0E7FF),
      child: Icon(
        Icons.person,
        color: Color(0xFF4F64A0),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon),
        ),
      ),
    );
  }
}

class _FeedTab extends StatelessWidget {
  final String title;
  final bool selected;

  const _FeedTab({
    required this.title,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 5,
                  ),
                ]
              : null,
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            color: selected ? const Color(0xFF4F64A0) : Colors.grey,
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: Colors.grey.shade700,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
