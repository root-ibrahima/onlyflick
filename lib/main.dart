import 'package:flutter/material.dart';
import 'package:matchmaker/features/home/presentation/pages/search_page.dart';

void main() {
  runApp(const OnlyFlickApp());
}

class OnlyFlickApp extends StatelessWidget {
  const OnlyFlickApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MatchMaker',
      theme: ThemeData.dark(useMaterial3: true),
      home: const MainScreen(),
    );
  }
}

// ----------------------- MAIN SCREEN + NAVBAR -----------------------

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    FeedScreen(),
    SearchScreen(),
    Center(child: Text('Reels')),
    Center(child: Text('Notifications')),
    Center(child: Text('Profile')),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.video_library), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: ''),
        ],
      ),
    );
  }
}

// ----------------------- FEED SCREEN -----------------------

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('MatchMaker',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ),
        ),
        const StoryList(),
        const Divider(height: 1),
        Expanded(child: PostList()),
      ],
    );
  }
}

// ----------------------- STORIES -----------------------

class StoryList extends StatelessWidget {
  const StoryList({super.key});

  @override
  Widget build(BuildContext context) {
    final stories = List.generate(10, (index) => 'User $index');

    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(8),
        itemCount: stories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return Column(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: NetworkImage(
                  'https://i.pravatar.cc/150?img=${index + 1}',
                ),
              ),
              const SizedBox(height: 4),
              Text(stories[index], style: const TextStyle(fontSize: 12)),
            ],
          );
        },
      ),
    );
  }
}

// ----------------------- POST LIST -----------------------

class PostList extends StatelessWidget {
  final List<Post> posts = List.generate(
    5,
    (index) => Post(
      username: 'user$index',
      userImage: 'https://i.pravatar.cc/150?img=${index + 5}',
      postImage: 'https://picsum.photos/seed/post$index/400/400',
      description: 'This is post number $index',
      likes: index * 10 + 5,
    ),
  );

  PostList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: posts.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        return PostWidget(post: posts[index]);
      },
    );
  }
}

class Post {
  final String username;
  final String userImage;
  final String postImage;
  final String description;
  final int likes;

  Post({
    required this.username,
    required this.userImage,
    required this.postImage,
    required this.description,
    required this.likes,
  });
}

// ----------------------- POST ITEM -----------------------

class PostWidget extends StatefulWidget {
  final Post post;

  const PostWidget({super.key, required this.post});

  @override
  State<PostWidget> createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  late int likeCount;
  bool isLiked = false;

  @override
  void initState() {
    super.initState();
    likeCount = widget.post.likes;
  }

  void toggleLike() {
    setState(() {
      isLiked = !isLiked;
      likeCount += isLiked ? 1 : -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: CircleAvatar(
              backgroundImage: NetworkImage(widget.post.userImage)),
          title: Text(widget.post.username),
          trailing: const Icon(Icons.more_vert),
        ),
        Image.network(widget.post.postImage,
            fit: BoxFit.cover, width: double.infinity),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? Colors.red : Colors.white),
                onPressed: toggleLike,
              ),
              IconButton(
                  icon: const Icon(Icons.comment_outlined), onPressed: () {}),
              IconButton(
                  icon: const Icon(Icons.share_outlined), onPressed: () {}),
              const Spacer(),
              IconButton(
                  icon: const Icon(Icons.bookmark_border), onPressed: () {}),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('$likeCount likes',
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text('${widget.post.username} ${widget.post.description}'),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
