import 'package:flutter/material.dart';
import '../widgets/story_list.dart';
import '../widgets/post_list.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'OnlyFlick',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Icon(Icons.chat_bubble_outline, color: Colors.black),
                ],
              ),
            ),

            // "Mes abonnements"
            const Padding(
              padding: EdgeInsets.only(top: 6, bottom: 6),
            
            ),

            // Stories
            const StoryList(),
            const SizedBox(height: 4),
            const Divider(height: 1),

            // Posts
            Expanded(child: PostList()),
          ],
        ),
      ),
    );
  }
}
