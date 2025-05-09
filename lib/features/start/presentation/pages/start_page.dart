import 'package:flutter/material.dart';

class StartPage extends StatelessWidget {
  const StartPage({super.key});

  final List<Map<String, dynamic>> players = const [
    {
      'name': 'Zizou',
      'image': 'assets/images/creator1.jpg',
      'role': 'Le Finisseur',
      'value': '9.99€'
    },
    {
      'name': 'Ronaldinho',
      'image': 'assets/images/creator2.jpg',
      'role': 'Magicien',
      'value': '4.99€'
    },
    {
      'name': 'Messi',
      'image': 'assets/images/creator1.jpg',
      'role': 'La Pulga',
      'value': '12.99€'
    },
    {
      'name': 'Cristiano Ronaldo',
      'image': 'assets/images/creator2.jpg',
      'role': 'CR7',
      'value': '11.99€'
    },
    {
      'name': 'Mbappé',
      'image': 'assets/images/creator1.jpg',
      'role': 'La Tortue',
      'value': '10.99€'
    },
    {
      'name': 'Neymar',
      'image': 'assets/images/creator2.jpg',
      'role': 'Le Showman',
      'value': '8.99€'
    },
    {
      'name': 'Benzema',
      'image': 'assets/images/creator1.jpg',
      'role': 'Le Chat',
      'value': '7.99€'
    },
    {
      'name': 'Haaland',
      'image': 'assets/images/creator2.jpg',
      'role': 'Le Robot',
      'value': '9.99€'
    },
    {
      'name': 'Lewandowski',
      'image': 'assets/images/creator1.jpg',
      'role': 'Le Buteur',
      'value': '6.99€'
    },
    {
      'name': 'De Bruyne',
      'image': 'assets/images/creator2.jpg',
      'role': 'Le Maestro',
      'value': '8.49€'
    },
    {
      'name': 'Modric',
      'image': 'assets/images/creator1.jpg',
      'role': 'Le Stratège',
      'value': '7.49€'
    },
    {
      'name': 'Salah',
      'image': 'assets/images/creator2.jpg',
      'role': 'Le Pharaon',
      'value': '7.99€'
    },
    {
      'name': 'Kanté',
      'image': 'assets/images/creator1.jpg',
      'role': 'L\'Infatigable',
      'value': '6.49€'
    },
    {
      'name': 'Courtois',
      'image': 'assets/images/creator1.jpg',
      'role': 'La Muraille',
      'value': '5.99€'
    },
    {
      'name': 'Van Dijk',
      'image': 'assets/images/creator1.jpg',
      'role': 'Le Roc',
      'value': '6.99€'
    },
    {
      'name': 'Kroos',
      'image': 'assets/images/creator1.jpg',
      'role': 'Le Métronome',
      'value': '5.49€'
    },
    {
      'name': 'Müller',
      'image': 'assets/images/creator1.jpg',
      'role': 'L\'Espace',
      'value': '4.99€'
    },
    {
      'name': 'Ramos',
      'image': 'assets/images/creator1.jpg',
      'role': 'El Capitan',
      'value': '4.49€'
    },
    {
      'name': 'Neuer',
      'image': 'assets/images/creator1.jpg',
      'role': 'Le Mur',
      'value': '5.99€'
    },
    {
      'name': 'Ibrahimović',
      'image': 'assets/images/creator2.jpg',
      'role': 'Le Lion',
      'value': '3.99€'
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      appBar: AppBar(
        title: const Text("Collectionne tes joueurs favoris"),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.separated(
          itemCount: players.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final player = players[index];
            return _creatorCard(
              image: player['image'],
              name: player['name'],
              role: player['role'],
              value: player['value'],
              theme: theme,
            );
          },
        ),
      ),
    );
  }

  Widget _creatorCard({
    required String image,
    required String name,
    required String role,
    required String value,
    required ThemeData theme,
  }) {
    // Existing _creatorCard implementation
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: Image.asset(
              image,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(role,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.white70)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: Colors.orangeAccent)),
              const SizedBox(height: 8),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.orange,
                  minimumSize: const Size(80, 36),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                onPressed: () {
                  // À connecter à la logique de souscription
                },
                child: const Text("Collectionner",
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ),
            ],
          )
        ],
      ),
    );
  }
}
