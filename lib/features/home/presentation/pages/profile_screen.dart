import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileScreen extends StatelessWidget {
  final bool isCreator;

  const ProfileScreen({super.key, this.isCreator = false});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: isCreator ? 2 : 1,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              _buildAvatarAndStats(),
              _buildBioSection(),
              _buildButtons(),
              if (isCreator) const _ProfileTabs(),
              const SizedBox(height: 8),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildGrid(type: 'normal'),
                    if (isCreator) _buildGrid(type: 'shop'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('OnlyFlick',
              style: GoogleFonts.pacifico(fontSize: 24, color: Colors.black)),
          IconButton(
            icon: const Icon(Icons.add_box_outlined, size: 28, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarAndStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 40,
            backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=10'),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                _StatColumn(title: 'Posts', value: '1,234'),
                _StatColumn(title: 'Followers', value: '5,678'),
                _StatColumn(title: 'Following', value: '9,101'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBioSection() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ruffles', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          SizedBox(height: 4),
          Text(
            'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt #hashtag',
            style: TextStyle(fontSize: 14, color: Colors.black87),
          ),
          SizedBox(height: 6),
          Text(
            'Abonnement : 4,99€ / mois',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            height: 44,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              onPressed: () {},
              child: const Text('Mettre à jour le profil', style: TextStyle(color: Colors.white)),
            ),
          ),
        ),
        if (!isCreator) ...[
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                onPressed: () {},
                child: const Text('Passer en compte créateur', style: TextStyle(color: Colors.black)),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGrid({required String type}) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: 12,
      itemBuilder: (_, index) {
        return Stack(
          children: [
            Positioned.fill(
              child: Image.network(
                'https://picsum.photos/seed/$type$index/300',
                fit: BoxFit.cover,
              ),
            ),
            if (type == 'normal' && index % 3 == 0)
              const Positioned(
                top: 6,
                right: 6,
                child: Icon(Icons.video_library, size: 16, color: Colors.white),
              ),
            if (type == 'shop' && index % 2 == 0)
              const Positioned(
                top: 6,
                right: 6,
                child: Icon(Icons.shopping_bag, size: 16, color: Colors.white),
              ),
          ],
        );
      },
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String value;
  final String title;
  const _StatColumn({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 2),
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.black87)),
      ],
    );
  }
}

class _ProfileTabs extends StatelessWidget {
  const _ProfileTabs();

  @override
  Widget build(BuildContext context) {
    return TabBar(
      indicatorColor: Colors.black,
      tabs: const [
        Tab(icon: Icon(Icons.grid_on_rounded, color: Colors.black)),
        Tab(icon: Icon(Icons.shopping_bag_outlined, color: Colors.black)),
      ],
    );
  }
}
