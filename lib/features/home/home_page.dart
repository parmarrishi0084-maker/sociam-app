import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SupabaseClient supabase = Supabase.instance.client;

  late Future<List<Map<String, dynamic>>> postsFuture;

  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    postsFuture = loadPosts();
  }

  Future<List<Map<String, dynamic>>> loadPosts() async {
    final data = await supabase
        .from('posts')
        .select(
          'id, content, image_url, video_url, created_at, '
          'profiles(username, full_name, avatar_url)',
        )
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> refreshFeed() async {
    final future = loadPosts();

    setState(() {
      postsFuture = future;
    });

    await future;
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void navigationTap(int index) {
    setState(() {
      selectedIndex = index;
    });

    if (index == 0) return;

    if (index == 1) {
      showMessage('Discover coming soon');
    } else if (index == 2) {
      showMessage('Create coming soon');
    } else if (index == 3) {
      showMessage('Connect coming soon');
    } else if (index == 4) {
      showMessage('Profile coming soon');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sociam',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: refreshFeed,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: () {
              showMessage('Notifications coming soon');
            },
            icon: const Icon(Icons.notifications_none),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: refreshFeed,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: postsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 150),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 50,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Feed load failed',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          snapshot.error.toString(),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: refreshFeed,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            final posts = snapshot.data ?? [];

            if (posts.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 180),
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.photo_library_outlined,
                          size: 60,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No posts yet',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Create the first post on Sociam.',
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(
                top: 8,
                bottom: 90,
              ),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                return PostCard(
                  key: ValueKey(posts[index]['id']),
                  post: posts[index],
                );
              },
            );
          },
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: navigationTap,
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
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
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

class PostCard extends StatefulWidget {
  final Map<String, dynamic> post;

  const PostCard({
    super.key,
    required this.post,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final SupabaseClient supabase = Supabase.instance.client;

  bool liked = false;
  bool loadingLike = false;
  int likeCount = 0;

  @override
  void initState() {
    super.initState();
    loadLikeData();
  }

  Future<void> loadLikeData() async {
    final postId = widget.post['id'];

    if (postId == null) return;

    try {
      final userId = supabase.auth.currentUser?.id;

      final data = await supabase
          .from('post_likes')
          .select('user_id')
          .eq('post_id', postId);

      final rows = List<Map<String, dynamic>>.from(data);

      if (!mounted) return;

      setState(() {
        likeCount = rows.length;
        liked = userId != null &&
            rows.any(
              (row) => row['user_id']?.toString() == userId,
            );
      });
    } catch (_) {}
  }

  Future<void> toggleLike() async {
    if (loadingLike) return;

    final userId = supabase.auth.currentUser?.id;
    final postId = widget.post['id'];

    if (userId == null) {
      showMessage('Please login first.');
      return;
    }

    if (postId == null) {
      showMessage('Post ID not found.');
      return;
    }

    final oldLiked = liked;
    final oldCount = likeCount;

    setState(() {
      loadingLike = true;
      liked = !liked;

      if (liked) {
        likeCount++;
      } else if (likeCount > 0) {
        likeCount--;
      }
    });

    try {
      if (oldLiked) {
        await supabase
            .from('post_likes')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', userId);
      } else {
        await supabase.from('post_likes').insert({
          'post_id': postId,
          'user_id': userId,
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        liked = oldLiked;
        likeCount = oldCount;
      });

      showMessage('Like failed.');
    } finally {
      if (mounted) {
        setState(() {
          loadingLike = false;
        });
      }
    }
  }

  void openComments() {
    final postId = widget.post['id'];

    if (postId == null) {
      showMessage('Post ID not found.');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) {
        return CommentsSheet(
          postId: postId,
        );
      },
    );
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String getName() {
    final profile = widget.post['profiles'];

    if (profile is Map) {
      final fullName = profile['full_name'];
      final username = profile['username'];

      if (fullName != null &&
          fullName.toString().trim().isNotEmpty) {
        return fullName.toString();
      }

      if (username != null &&
          username.toString().trim().isNotEmpty) {
        return username.toString();
      }
    }

    return 'Sociam User';
  }

  String getUsername() {
    final profile = widget.post['profiles'];

    if (profile is Map) {
      final username = profile['username'];

      if (username != null &&
          username.toString().trim().isNotEmpty) {
        return username.toString();
      }
    }

    return 'sociam_user';
  }

  String getAvatar() {
    final profile = widget.post['profiles'];

    if (profile is Map) {
      final avatar = profile['avatar_url'];

      if (avatar != null &&
          avatar.toString().trim().isNotEmpty) {
        return avatar.toString();
      }
    }

    return '';
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.post['content']?.toString() ?? '';
    final imageUrl = widget.post['image_url']?.toString() ?? '';
    final videoUrl = widget.post['video_url']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Avatar(
                  imageUrl: getAvatar(),
                  name: getName(),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        getName(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '@${getUsername()}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    showMessage(
                      'Post options coming soon',
                    );
                  },
                  icon: const Icon(Icons.more_vert),
                ),
              ],
            ),

            const SizedBox(height: 12),

            if (content.trim().isNotEmpty)
              Text(
                content,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),

            if (imageUrl.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return Container(
                      height: 200,
                      alignment: Alignment.center,
                      color: Colors.grey.shade200,
                      child: const Icon(
                        Icons.broken_image_outlined,
                        size: 50,
                      ),
                    );
                  },
                ),
              ),
            ],

            if (videoUrl.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(
                    Icons.play_circle_outline,
                    color: Colors.white,
                    size: 60,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 8),

            Row(
              children: [
                CircleButton(
                  icon: liked
                      ? Icons.favorite
                      : Icons.favorite_border,
                  active: liked,
                  onTap: toggleLike,
                ),

                const SizedBox(width: 2),

                Text(
                  '$likeCount',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(width: 12),

                Circle
