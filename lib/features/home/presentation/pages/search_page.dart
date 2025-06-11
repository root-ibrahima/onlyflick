import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  List<int> allItems = List.generate(30, (index) => index);
  List<int> filteredItems = [];

  @override
  void initState() {
    super.initState();
    filteredItems = allItems;
    _controller.addListener(_filter);
  }

  void _filter() {
    final query = _controller.text.toLowerCase();
    setState(() {
      filteredItems = allItems.where((i) => 'item $i'.contains(query)).toList();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Text(
                'OnlyFlick',
                style: GoogleFonts.pacifico(
                  fontSize: 24,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Search input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _controller,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                ),
                decoration: InputDecoration(
                  hintText: 'Recherche',
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.search, color: Colors.black54),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey[400]!),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Image grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 2,
                  crossAxisSpacing: 2,
                ),
                itemCount: filteredItems.length,
                itemBuilder: (context, index) {
                  final item = filteredItems[index];
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: Image.network(
                          'https://picsum.photos/id/${item + 10}/300/300',
                          fit: BoxFit.cover,
                        ),
                      ),
                      const Positioned(
                        top: 6,
                        right: 6,
                        child: Icon(Icons.video_library,
                            size: 16, color: Colors.white),
                      )
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SearchPageWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        // ...existing code...
        );
  }
}
