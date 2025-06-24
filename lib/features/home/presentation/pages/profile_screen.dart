import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../auth/auth_provider.dart';
class ProfileScreen extends StatelessWidget {
  final bool isCreator;

  const ProfileScreen({super.key, this.isCreator = false});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        final userIsCreator = user?.isCreator == true;
        
        return DefaultTabController(
          length: userIsCreator ? 2 : 1,
          child: Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  _buildAvatarAndStats(user),
                  _buildBioSection(user, userIsCreator),
                  _buildButtons(userIsCreator, context),
                  
                  // Widget BecomeCreator pour les non-créateurs
                  if (!userIsCreator) 
                    const BecomeCreatorWidget(),
                  
                  if (userIsCreator) const _ProfileTabs(),
                  const SizedBox(height: 8),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildGrid(type: 'normal'),
                        if (userIsCreator) _buildGrid(type: 'shop'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'OnlyFlick',
            style: GoogleFonts.pacifico(fontSize: 24, color: Colors.black),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 28, color: Colors.black),
            onPressed: () {
              // TODO: Navigation vers paramètres
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarAndStats(dynamic user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.grey[300],
            backgroundImage: user != null 
                ? NetworkImage('https://i.pravatar.cc/150?img=${user.id % 20}')
                : null,
            child: user == null 
                ? const Icon(Icons.person, color: Colors.grey, size: 40)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                _StatColumn(title: 'Posts', value: '0'), // TODO: Vraies données
                _StatColumn(title: 'Abonnés', value: '0'),
                _StatColumn(title: 'Abonnements', value: '0'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBioSection(dynamic user, bool userIsCreator) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            user?.fullName ?? 'Utilisateur',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            user?.email ?? 'email@example.com',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          
          // Badge du rôle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: userIsCreator ? Colors.purple.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: userIsCreator ? Colors.purple : Colors.blue,
                width: 1,
              ),
            ),
            child: Text(
              userIsCreator ? '✨ Créateur' : '👤 Abonné',
              style: TextStyle(
                fontSize: 12,
                color: userIsCreator ? Colors.purple : Colors.blue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
          if (userIsCreator) ...[
            const SizedBox(height: 8),
            const Text(
              'Abonnement : 4,99€ / mois',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildButtons(bool userIsCreator, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          SizedBox(
            height: 44,
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                // TODO: Navigation vers édition du profil
              },
              child: const Text(
                'Modifier le profil',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          
          if (userIsCreator) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 44,
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.purple),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  // TODO: Statistiques créateur
                },
                child: const Text(
                  'Statistiques créateur',
                  style: TextStyle(color: Colors.purple, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
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
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Icon(
                  type == 'shop' ? Icons.shopping_bag_outlined : Icons.image_outlined,
                  color: Colors.grey[400],
                  size: 32,
                ),
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
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: const TextStyle(fontSize: 12, color: Colors.black87),
        ),
      ],
    );
  }
}

class _ProfileTabs extends StatelessWidget {
  const _ProfileTabs();

  @override
  Widget build(BuildContext context) {
    return const TabBar(
      indicatorColor: Colors.black,
      tabs: [
        Tab(icon: Icon(Icons.grid_on_rounded, color: Colors.black)),
        Tab(icon: Icon(Icons.shopping_bag_outlined, color: Colors.black)),
      ],
    );
  }
}

// Widget BecomeCreator intégré
class BecomeCreatorWidget extends StatelessWidget {
  const BecomeCreatorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withOpacity(0.1),
            Colors.pink.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.purple.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.star_outline,
            size: 48,
            color: Colors.purple,
          ),
          const SizedBox(height: 16),
          const Text(
            'Devenez Créateur',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Partagez votre contenu et gagnez de l\'argent avec vos abonnés !',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _showCreatorInfoDialog(context);
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.purple),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'En savoir plus',
                    style: TextStyle(color: Colors.purple),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    _requestCreatorStatus(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Postuler',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCreatorInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Programme Créateur'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('En tant que créateur, vous pouvez :'),
            SizedBox(height: 8),
            Text('• Publier du contenu exclusif'),
            Text('• Recevoir des abonnements payants'),
            Text('• Interagir avec vos fans'),
            Text('• Gagner de l\'argent avec votre contenu'),
            SizedBox(height: 16),
            Text(
              'Contactez notre équipe pour commencer !',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _requestCreatorStatus(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Demande envoyée ! Notre équipe vous contactera bientôt.'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}