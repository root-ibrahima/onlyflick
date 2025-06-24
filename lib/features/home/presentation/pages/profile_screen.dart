import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../auth/auth_provider.dart';
import '../../../../core/services/profile_service.dart';
import '../../../../core/providers/profile_provider.dart'; 

class ProfileScreen extends StatefulWidget {
  final bool isCreator;

  const ProfileScreen({super.key, this.isCreator = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    
    // Initialiser le TabController
    final user = context.read<AuthProvider>().user;
    final userIsCreator = user?.isCreator ?? false;
    _tabController = TabController(length: userIsCreator ? 2 : 1, vsync: this);
    
    // Charger les données du profil
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().loadProfileData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, ProfileProvider>(
      builder: (context, authProvider, profileProvider, child) {
        final user = authProvider.user;
        final userIsCreator = user?.isCreator ?? false;
        
        return DefaultTabController(
          length: userIsCreator ? 2 : 1,
          child: Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: RefreshIndicator(
                onRefresh: () => profileProvider.refresh(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),
                    _buildAvatarAndStats(user, profileProvider),
                    _buildBioSection(user, userIsCreator, profileProvider),
                    _buildButtons(userIsCreator, context, profileProvider),
                    
                    // Widget BecomeCreator pour les non-créateurs
                    if (!userIsCreator) 
                      BecomeCreatorWidget(
                        onRequestUpgrade: () => _handleCreatorUpgrade(profileProvider),
                      ),
                    
                    if (userIsCreator) const _ProfileTabs(),
                    const SizedBox(height: 8),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildGrid(type: 'normal', profileProvider: profileProvider),
                          if (userIsCreator) _buildGrid(type: 'shop', profileProvider: profileProvider),
                        ],
                      ),
                    ),
                  ],
                ),
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
            onPressed: _showSettingsMenu,
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarAndStats(dynamic user, ProfileProvider profileProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Avatar avec possibilité de modification
          _buildAvatar(user, profileProvider),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: profileProvider.isLoadingStats
                  ? const [
                      _LoadingStatColumn(),
                      _LoadingStatColumn(),
                      _LoadingStatColumn(),
                    ]
                  : [
                      _StatColumn(
                        title: 'Posts',
                        value: _formatCount(profileProvider.stats.postsCount),
                      ),
                      _StatColumn(
                        title: 'Abonnés',
                        value: _formatCount(profileProvider.stats.followersCount),
                      ),
                      _StatColumn(
                        title: 'Abonnements',
                        value: _formatCount(profileProvider.stats.followingCount),
                      ),
                    ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(dynamic user, ProfileProvider profileProvider) {
    return Stack(
      children: [
        // Avatar principal
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey[300]!, width: 2),
          ),
          child: CircleAvatar(
            radius: 40,
            backgroundColor: Colors.grey[100],
            backgroundImage: user?.avatarUrl != null 
                ? NetworkImage(user.avatarUrl)
                : (user != null 
                    ? NetworkImage('https://i.pravatar.cc/150?img=${user.id % 20}')
                    : null),
            child: user?.avatarUrl == null && user != null
                ? Text(
                    user.initials,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  )
                : (user == null 
                    ? const Icon(Icons.person, color: Colors.grey, size: 40)
                    : null),
          ),
        ),
        
        // Bouton d'édition
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
              onPressed: profileProvider.isUploadingAvatar 
                  ? null 
                  : () => _changeAvatar(profileProvider),
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
            ),
          ),
        ),
        
        // Indicateur de chargement pour l'upload
        if (profileProvider.isUploadingAvatar)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity(0.5),
              ),
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBioSection(dynamic user, bool userIsCreator, ProfileProvider profileProvider) {
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
          
          // Bio avec possibilité de modification
          GestureDetector(
            onTap: () => _editBio(user?.bio ?? '', profileProvider),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.transparent),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                user?.bio ?? 'Ajoutez une bio... (tapez ici)',
                style: TextStyle(
                  fontSize: 14,
                  color: user?.bio != null ? Colors.black : Colors.grey[500],
                  fontStyle: user?.bio != null ? FontStyle.normal : FontStyle.italic,
                ),
              ),
            ),
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

  Widget _buildButtons(bool userIsCreator, BuildContext context, ProfileProvider profileProvider) {
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
              onPressed: profileProvider.isUpdatingBio 
                  ? null 
                  : () => _editProfile(context, profileProvider),
              child: profileProvider.isUpdatingBio
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
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
                onPressed: () => _showCreatorStats(profileProvider),
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

  Widget _buildGrid({required String type, required ProfileProvider profileProvider}) {
    final posts = type == 'shop' 
        ? profileProvider.userPosts.where((post) => post.isSubscriberOnly).toList()
        : profileProvider.userPosts;

    if (profileProvider.isLoadingPosts && posts.isEmpty) {
      return _buildLoadingGrid();
    }

    if (posts.isEmpty) {
      return _buildEmptyGrid(type);
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: posts.length + (profileProvider.hasMorePosts ? 3 : 0),
      itemBuilder: (context, index) {
        if (index >= posts.length) {
          return _buildLoadingTile();
        }

        final post = posts[index];
        return _buildPostTile(post, profileProvider);
      },
    );
  }

  Widget _buildPostTile(UserPost post, ProfileProvider profileProvider) {
    return GestureDetector(
      onTap: () => _onPostTap(post),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: post.imageUrl != null
                  ? Image.network(
                      post.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.image_outlined,
                        color: Colors.grey[400],
                        size: 32,
                      ),
                    )
                  : Icon(
                      Icons.image_outlined,
                      color: Colors.grey[400],
                      size: 32,
                    ),
            ),
          ),
          
          // Indicateur vidéo
          if (post.isVideo)
            const Positioned(
              top: 6,
              left: 6,
              child: Icon(Icons.play_circle_fill, size: 16, color: Colors.white),
            ),
          
          // Overlay pour les posts privés
          if (post.isSubscriberOnly)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'VIP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          
          // Statistiques du post
          Positioned(
            bottom: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => profileProvider.togglePostLike(post.id),
                    child: Icon(
                      post.isLiked ? Icons.favorite : Icons.favorite_border,
                      color: post.isLiked ? Colors.red : Colors.white,
                      size: 12,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    post.likesCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingGrid() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: 9,
      itemBuilder: (_, index) => _buildLoadingTile(),
    );
  }

  Widget _buildEmptyGrid(String type) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            type == 'shop' ? Icons.shopping_bag_outlined : Icons.photo_library_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            type == 'shop' ? 'Aucun contenu premium' : 'Aucun post pour le moment',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Commencez à partager votre contenu !',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingTile() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[300],
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: const Center(
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  // ===== ACTIONS =====

  Future<void> _changeAvatar(ProfileProvider profileProvider) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        final success = await profileProvider.uploadAvatar(image.path);
        
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Avatar mis à jour avec succès !'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la sélection de l\'image'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _editBio(String currentBio, ProfileProvider profileProvider) {
    showDialog(
      context: context,
      builder: (context) => _ProfileEditDialog(
        title: 'Modifier la bio',
        initialValue: currentBio,
        maxLength: 150,
        onSave: (newBio) async {
          final success = await profileProvider.updateBio(newBio);
          if (success && mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Bio mise à jour avec succès !'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
      ),
    );
  }

  void _editProfile(BuildContext context, ProfileProvider profileProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le profil'),
        content: const Text('Fonctionnalité en cours de développement'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showCreatorStats(ProfileProvider profileProvider) {
    final stats = profileProvider.stats;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Statistiques créateur'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Posts publiés: ${stats.postsCount}'),
            Text('Abonnés: ${stats.followersCount}'),
            Text('Likes reçus: ${stats.likesReceived}'),
            Text('Revenus totaux: ${stats.totalEarnings.toStringAsFixed(2)}€'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showSettingsMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Paramètres'),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: Navigation vers paramètres
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Déconnexion'),
              onTap: () {
                Navigator.of(context).pop();
                _logout();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleCreatorUpgrade(ProfileProvider profileProvider) async {
    final success = await profileProvider.requestCreatorUpgrade();
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Demande de passage en créateur envoyée !'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _onPostTap(UserPost post) {
    debugPrint('Post tapped: ${post.id}');
    // TODO: Navigation vers le détail du post
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}

// ===== WIDGETS AUXILIAIRES =====

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

class _LoadingStatColumn extends StatelessWidget {
  const _LoadingStatColumn();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 30,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 50,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
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

// Widget BecomeCreator intégré avec callback
class BecomeCreatorWidget extends StatelessWidget {
  final VoidCallback onRequestUpgrade;

  const BecomeCreatorWidget({
    super.key,
    required this.onRequestUpgrade,
  });

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
                  onPressed: onRequestUpgrade,
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
}

// Dialogue d'édition
class _ProfileEditDialog extends StatefulWidget {
  final String title;
  final String initialValue;
  final int maxLength;
  final Function(String) onSave;

  const _ProfileEditDialog({
    required this.title,
    required this.initialValue,
    required this.maxLength,
    required this.onSave,
  });

  @override
  State<_ProfileEditDialog> createState() => _ProfileEditDialogState();
}

class _ProfileEditDialogState extends State<_ProfileEditDialog> {
  late TextEditingController _controller;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            maxLength: widget.maxLength,
            maxLines: widget.maxLength > 50 ? 3 : 1,
            decoration: InputDecoration(
              hintText: 'Entrez votre texte...',
              border: const OutlineInputBorder(),
              counterStyle: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            enabled: !_isLoading,
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: LinearProgressIndicator(),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Sauvegarder'),
        ),
      ],
    );
  }

  Future<void> _handleSave() async {
    if (_controller.text.trim().length > widget.maxLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Le texte ne peut pas dépasser ${widget.maxLength} caractères'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await widget.onSave(_controller.text.trim());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la sauvegarde'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}