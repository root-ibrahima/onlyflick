import 'package:flutter/material.dart';
import 'feed_screen.dart';
import 'search_page.dart';
import 'profile_screen.dart'; // ← Assure-toi que ce fichier existe

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const FeedScreen(),
    const SearchScreen(),
    ProfileScreen(isCreator: true), // ← Affiche maintenant la vraie page profil
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.only(top: 8, bottom: 18),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _navIcon(Icons.home_rounded, 0),
            _navIcon(Icons.search_rounded, 1),
            _profileIcon(2),
          ],
        ),
      ),
    );
  }

  Widget _navIcon(IconData icon, int index) {
    final isSelected = _selectedIndex == index;
    return IconButton(
      onPressed: () => _onItemTapped(index),
      icon: Icon(
        icon,
        color: isSelected ? Colors.black : Colors.grey[400],
        size: 28,
      ),
    );
  }

  Widget _profileIcon(int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: CircleAvatar(
        radius: 16,
        backgroundColor: isSelected ? Colors.black : Colors.transparent,
        child: const CircleAvatar(
          radius: 14,
          backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=10'),
        ),
      ),
    );
  }
}
