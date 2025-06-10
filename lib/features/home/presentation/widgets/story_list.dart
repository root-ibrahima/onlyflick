import 'package:flutter/material.dart';

class StoryList extends StatelessWidget {
  const StoryList({super.key});

  @override
  Widget build(BuildContext context) {
    final stories = [
      'Jolly',
      'sabanok...',
      'blue_bouy',
      'waggles',
      'steve',
      'buddy',
      'shadow',
    ];

    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: stories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return Column(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage: NetworkImage(
                  'https://i.pravatar.cc/150?img=${index + 10}',
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 60,
                child: Text(
                  stories[index],
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
