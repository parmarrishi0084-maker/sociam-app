import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final supabase = Supabase.instance.client;

  late Future<List<Map<String, dynamic>>> _postsFuture;

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _postsFuture = loadPosts();
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
      _postsFuture = future;
    });

    await future;
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  void onNavigationTap(int index) {
    setState(() {
      _selectedIndex = index;
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
          future: _postsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 150),
                  Center(
                    child: Padding(
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
                          const SizedBox(height: 8),
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
                  ),
                ],
              );
            }

            final posts = snapshot.data ?? [];

            if (posts.isEmpty) {
              return ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
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
              physics:
                  const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(
                top: 8,
                bottom: 90,
              ),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                return _PostCard(
                  key: ValueKey(posts[index]['id']),
                  post: posts[index],
                );
              },
            );
          },
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: onNavigationTap,
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

class _PostCard extends StatefulWidget {
  final Map<String, dynamic> post;

  const _PostCard({
    super.key,
    required this.post,
  });

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  final supabase = Supabase.instance.client;

  bool liked = false;
  int likeCount = 0;
  bool loadingLike = false;

  @override
  void initState() {
    super.initState();
    loadLikeData();
  }

  Future<void> loadLikeData() async {
    final postId = widget.post['id'];

    if (postId == null) return;

    try {
      final userId =
          supabase.auth.currentUser?.id;

      final data = await supabase
          .from('post_likes')
          .select('user_id')
          .eq('post_id', postId);

      final rows =
          List<Map<String, dynamic>>.from(data);

      if (!mounted) return;

      setState(() {
        likeCount = rows.length;

        liked = userId != null &&
            rows.any(
              (row) =>
                  row['user_id']?.toString() ==
                  userId,
            );
      });
    } catch (_) {
      // Keep post visible if likes fail.
    }
  }

  Future<void> toggleLike() async {
    if (loadingLike) return;

    final userId =
        supabase.auth.currentUser?.id;

    final postId = widget.post['id'];

    if (userId == null) {
      showMessage('Please login first.');
      return;
    }

    if (postId == null) {
      showMessage('Post ID not found.');
      return;
    }

    final previousLiked = liked;
    final previousCount = likeCount;

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
      if (previousLiked) {
        await supabase
            .from('post_likes')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', userId);
      } else {
        await supabase
            .from('post_likes')
            .insert({
          'post_id': postId,
          'user_id': userId,
        });
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        liked = previousLiked;
        likeCount = previousCount;
      });

      showMessage(
        'Like failed. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          loadingLike = false;
        });
      }
    }
  }

  void showComments() {
    final postId = widget.post['id'];

    if (postId == null) {
      showMessage('Post ID not found.');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return _CommentsSheet(
          postId: postId,
        );
      },
    );
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  String getUsername() {
    final profile = widget.post['profiles'];

    if (profile is Map) {
      final username = profile['username'];

      if (username != null &&
          username.toString().trim().isNotEmpty) {
        return username.toString();
      }

      final fullName = profile['full_name'];

      if (fullName != null &&
          fullName.toString().trim().isNotEmpty) {
        return fullName.toString();
      }
    }

    return 'Sociam User';
  }

  String getFullName() {
    final profile = widget.post['profiles'];

    if (profile is Map) {
      final fullName = profile['full_name'];

      if (fullName != null &&
          fullName.toString().trim().isNotEmpty) {
        return fullName.toString();
      }
    }

    return getUsername();
  }

  String getAvatarUrl() {
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
    final content =
        widget.post['content']?.toString() ?? '';

    final imageUrl =
        widget.post['image_url']?.toString() ?? '';

    final videoUrl =
        widget.post['video_url']?.toString() ?? '';

    final avatarUrl = getAvatarUrl();

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _Avatar(
                  imageUrl: avatarUrl,
                  name: getUsername(),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        getFullName(),
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
                  icon:
                      const Icon(Icons.more_vert),
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
                borderRadius:
                    BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      alignment:
                          Alignment.center,
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
                  borderRadius:
                      BorderRadius.circular(12),
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
                _CircleButton(
                  icon: liked
                      ? Icons.favorite
                      : Icons.favorite_border,
                  active: liked,
                  onTap: toggleLike,
                ),

                const SizedBox(width: 4),

                Text(
                  '$likeCount',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(width: 12),

                _CircleButton(
                  icon: Icons.comment_outlined,
                  onTap: showComments,
                ),

                const SizedBox(width: 12),

                _CircleButton(
                  icon: Icons.share_outlined,
                  onTap: () {
                    showMessage(
                      'Share coming soon',
                    );
                  },
                ),

                const Spacer(),

                if (loadingLike)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentsSheet extends StatefulWidget {
  final dynamic postId;

  const _CommentsSheet({
    required this.postId,
  });

  @override
  State<_CommentsSheet> createState() =>
      _CommentsSheetState();
}

class _CommentsSheetState
    extends State<_CommentsSheet> {
  final supabase = Supabase.instance.client;

  final TextEditingController
      commentController =
      TextEditingController();

  late Future<
      List<Map<String, dynamic>>> commentsFuture;

  bool sending = false;
  bool liking = false;

  int? replyingTo;
  String replyingToName = '';

  final Set<int> likedComments = {};
  final Map<int, int> commentLikeCounts = {};
  final Map<int, int> replyCounts = {};

  @override
  void initState() {
    super.initState();
    commentsFuture = loadComments();
  }

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>>
      loadComments() async {
    final data = await supabase
        .from('comments')
        .select(
          'id, content, created_at, user_id, '
          'parent_comment_id, '
          'profiles(username, full_name, avatar_url)',
        )
        .eq('post_id', widget.postId)
        .order('created_at', ascending: true);

    final comments =
        List<Map<String, dynamic>>.from(data);

    await loadCommentLikes(comments);

    replyCounts.clear();

    for (final comment in comments) {
      final parentId =
          comment['parent_comment_id'];

      if (parentId != null) {
        final id =
            int.tryParse(parentId.toString());

        if (id != null) {
          replyCounts[id] =
              (replyCounts[id] ?? 0) + 1;
        }
      }
    }

    return comments;
  }

  Future<void> loadCommentLikes(
    List<Map<String, dynamic>> comments,
  ) async {
    likedComments.clear();
    commentLikeCounts.clear();

    if (comments.isEmpty) return;

    final commentIds = comments
        .map((comment) => comment['id'])
        .where((id) => id != null)
        .toList();

    try {
      final data = await supabase
          .from('comment_likes')
          .select('comment_id, user_id')
          .inFilter(
            'comment_id',
            commentIds,
          );

      final rows =
          List<Map<String, dynamic>>.from(data);

      final currentUserId =
          supabase.auth.currentUser?.id;

      for (final row in rows) {
        final commentId =
            int.tryParse(
          row['comment_id'].toString(),
        );

        if (commentId == null) continue;

        commentLikeCounts[commentId] =
            (commentLikeCounts[commentId] ?? 0) + 1;

        if (currentUserId != null &&
            row['user_id']?.toString() ==
                currentUserId) {
          likedComments.add(commentId);
        }
      }
    } catch (_) {
      // Keep comments working if likes fail.
    }
  }

  Future<void> refreshComments() async {
    final future = loadComments();

    setState(() {
      commentsFuture = future;
    });

    await future;
  }

  Future<void> toggleCommentLike(
    int commentId,
  ) async {
    if (liking) return;

    final userId =
        supabase.auth.currentUser?.id;

    if (userId == null) {
      showMessage('Please login first.');
      return;
    }

    final wasLiked =
        likedComments.contains(commentId);

    final oldCount =
        commentLikeCounts[commentId] ?? 0;

    setState(() {
      liking = true;

      if (wasLiked) {
        likedComments.remove(commentId);

        commentLikeCounts[commentId] =
            oldCount > 0
                ? oldCount - 1
                : 0;
      } else {
        likedComments.add(commentId);

        commentLikeCounts[commentId] =
            oldCount + 1;
      }
    });

    try {
      if (wasLiked) {
        await supabase
            .from('comment_likes')
            .delete()
            .eq(
              'comment_id',
              commentId,
            )
            .eq(
              'user_id',
              userId,
            );
      } else {
        await supabase
            .from('comment_likes')
            .insert({
          'comment_id': commentId,
          'user_id': userId,
        });
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        if (wasLiked) {
          likedComments.add(commentId);
        } else {
          likedComments.remove(commentId);
        }

        commentLikeCounts[commentId] =
            oldCount;
      });

      showMessage(
        'Comment like failed. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          liking = false;
        });
      }
    }
  }

  Future<void> sendComment() async {
    final content =
        commentController.text.trim();

    if (content.isEmpty) return;

    final userId =
        supabase.auth.currentUser?.id;

    if (userId == null) {
      showMessage('Please login first.');
      return;
    }

    if (sending) return;

    final parentId = replyingTo;

    setState(() {
      sending = true;
    });

    try {
      await supabase.from('comments').insert({
        'post_id': widget.postId,
        'user_id': userId,
        'content': content,
        'parent_comment_id': parentId,
      });

      commentController.clear();

      setState(() {
        replyingTo = null;
        replyingToName = '';
      });

      await refreshComments();
    } catch (_) {
      showMessage(
        'Comment failed. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          sending = false;
        });
      }
    }
  }

  void startReply(
    int commentId,
    String name,
  ) {
    setState(() {
      replyingTo = commentId;
      replyingToName = name;
    });
  }

  void cancelReply() {
    setState(() {
      replyingTo = null;
      replyingToName = '';
    });
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  String getName(
    Map<String, dynamic> comment,
  ) {
    final profile = comment['profiles'];

    if (profile is Map) {
      final fullName =
          profile['full_name'];

      if (fullName != null &&
          fullName.toString().trim().isNotEmpty) {
        return fullName.toString();
      }

      final username =
          profile['username'];

      if (username != null &&
          username.toString().trim().isNotEmpty) {
        return username.toString();
      }
    }

    return 'Sociam User';
  }

  String getAvatarUrl(
    Map<String, dynamic> comment,
  ) {
    final profile = comment['profiles'];

    if (profile is Map) {
      final avatar =
          profile['avatar_url'];

      if (avatar != null &&
          avatar.toString().trim().isNotEmpty) {
        return avatar.toString();
      }
    }

    return '';
  }

  bool isReply(
    Map<String, dynamic> comment,
  ) {
    return comment['parent_comment_id'] != null;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset =
        MediaQuery.of(context)
            .viewInsets
            .bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: bottomInset,
        ),
        child: SizedBox(
          height:
              MediaQuery.of(context).size.height *
                  0.75,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Comments',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),

              const Divider(height: 1),

              Expanded(
                child: FutureBuilder<
                    List<Map<String, dynamic>>>(
                  future: commentsFuture,
                  builder:
                      (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child:
                            CircularProgressIndicator(),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisSize:
                              MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 45,
                            ),
                            const SizedBox(
                              height: 12,
                            ),
                            const Text(
                              'Comments load failed',
                            ),
                            const SizedBox(
                              height: 12,
                            ),
                            FilledButton(
                              onPressed:
                                  refreshComments,
                              child:
                                  const Text(
                                'Retry',
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final comments =
                        snapshot.data ?? [];

                    if (comments.isEmpty) {
                      return const Center(
                        child: Text(
                          'No comments yet.',
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh:
                          refreshComments,
                      child:
                          ListView.builder(
                        padding:
                            const EdgeInsets.all(
                          12,
                        ),
                        itemCount:
                            comments.length,
                        itemBuilder:
                            (context, index) {
                          final comment =
                              comments[index];

                          final id =
                              int.tryParse(
                            comment['id']
                                .toString(),
                          );

                          if (id == null) {
                            return const SizedBox
                                .shrink();
                          }

                          final name =
                              getName(comment);

                          final avatarUrl =
                              getAvatarUrl(
                            comment,
                          );

                          final liked =
                              likedComments
                                  .contains(id);

                          final likeCount =
                              commentLikeCounts[
                                      id] ??
                                  0;

                          final replies =
                              replyCounts[id] ??
                                  0;

                          final reply =
                              isReply(comment);

                          return Container(
                            margin:
                                EdgeInsets.only(
                              left: reply
                                  ? 32
                                  : 0,
                              bottom: 8,
                            ),
                            padding:
                                const EdgeInsets
                                    .all(10),
                            decoration:
                                BoxDecoration(
                              color: Theme.of(
                                context,
                              )
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withValues(
                                    alpha: 0.35,
                                  ),
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                12,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundImage:
                                          avatarUrl
                                                  .isNotEmpty
                                              ? NetworkImage(
                                                  avatarUrl,
                                                )
                                              : null,
                                      child:
                                          avatarUrl
                                                  .isEmpty
                                              ? Text(
                                                  name
                                                      .substring(
                                                    0,
                                                    1,
                                                  )
                                                      .toUpperCase(),
                                                )
                                              : null,
                                    ),

                                    const SizedBox(
                                      width: 10,
                                    ),

                                    Expanded(
                                      child:
                                          Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment
                                                .start,
                                        children: [
                                          Text(
                                            name,
                                            style:
                                                const TextStyle(
                                              fontWeight:
                                                  FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(
                                            height: 4,
                                          ),
                                          Text(
                                            comment[
                                                        'content']
                                                    ?.toString() ??
                                                '',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(
                                  height: 4,
                                ),

                                Row(
                                  children: [
                                    TextButton.icon(
                                      onPressed:
                                          () {
                                        toggleCommentLike(
                                          id,
                                        );
                                      },
                                      icon: Icon(
                                        liked
                                            ? Icons
                                                .favorite
                                            : Icons
                                                .favorite_border,
                                        size: 18,
                                        color: liked
                                            ? Colors
                                                .red
                                            : null,
                                      ),
                                      label:
                                          Text(
                                        '$likeCount',
                                      ),
                                    ),

                                    TextButton.icon(
                                      onPressed:
                                          () {
                                        startReply(
                                          id,
                                          name,
                                        );
                                      },
                                      icon:
                                          const Icon(
                                        Icons
                                            .reply_outlined,
                                        size: 18,
                                      ),
                                      label:
                                          const Text(
                                        'Reply',
                                      ),
                                    ),

                                    if (replies >
                                        0)
                                      Text(
                                        '$replies ${replies == 1 ? 'reply' : 'replies'}',
                                        style:
                                            const TextStyle(
                                          color:
                                              Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),

              const Divider(height: 1),

              if (replyingTo != null)
                Container(
                  width:
                      double.infinity,
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Replying to $replyingToName',
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed:
                            cancelReply,
                        icon:
                            const Icon(
                          Icons.close,
                        ),
                      ),
                    ],
                  ),
                ),

              Padding(
                padding:
                    const EdgeInsets.fromLTRB(
                  12,
                  8,
                  12,
                  8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller:
                            commentController,
                        textInputAction:
                            TextInputAction.send,
                        onSubmitted: (_) {
                          sendComment();
                        },
                        decoration:
                            InputDecoration(
                          hintText:
                              replyingTo !=
                                      null
                                  ? 'Write a reply...'
                                  : 'Write a comment...',
                          border:
                              const OutlineInputBorder(),
                        ),
                      ),
                    ),

                    const SizedBox(
                      width: 8,
                    ),

                    IconButton(
                      onPressed:
                          sending
                              ? null
                              : sendComment,
                      icon: sending
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              Icons.send,
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String imageUrl;
  final String name;

  const _Avatar({
    required this.imageUrl,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.trim().isNotEmpty) {
      return CircleAvatar(
        radius: 22,
        backgroundImage:
            NetworkImage(imageUrl),
        onBackgroundImageError:
            (_, __) {},
      );
    }

    return CircleAvatar(
      radius: 22,
      child: Text(
        name.isNotEmpty
            ? name.substring(0, 1)
                .toUpperCase()
            : 'S',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool active;

  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(
        icon,
        color:
            active ? Colors.red : null,
      ),
    );
  }
}
