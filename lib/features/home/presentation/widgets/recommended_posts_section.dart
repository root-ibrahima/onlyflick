// lib/features/posts/widgets/recommended_posts_section.dart
import 'package:flutter/material.dart';
import '../../../../core/models/post_models.dart';
import '../../../../core/services/posts_service.dart';

import 'post_card.dart';

class RecommendedPostsSection extends StatefulWidget {
  const RecommendedPostsSection({super.key});

  @override
  State<RecommendedPostsSection> createState() => _RecommendedPostsSectionState();
}

class _RecommendedPostsSectionState extends State<RecommendedPostsSection> {
  final PostsService _postsService = PostsService();
  late Future<PostsResult> _recommendedPostsFuture;

  @override
  void initState() {
    super.initState();
    _recommendedPostsFuture = _postsService.getRecommendedPosts();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PostsResult>(
      future: _recommendedPostsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isFailure) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text("Aucune recommandation disponible pour le moment."),
          );
        }

        final posts = snapshot.data!.data!;
        if (posts.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text("Aucune recommandation pour l'instant."),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                "Recommandé pour vous",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              height: 260,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: posts.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return PostCard(post: posts[index]);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
