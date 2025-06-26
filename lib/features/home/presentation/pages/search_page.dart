// lib/features/search/presentation/pages/search_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/models/search_models.dart';
import '../../../../core/providers/search_provider.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchTextChanged);
    _setupScrollListener();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_searchController.text.isNotEmpty && 
          _scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        // Charger plus d'utilisateurs si on arrive en bas
        final searchProvider = context.read<SearchProvider>();
        if (!searchProvider.isLoadingMoreSearch) {
          searchProvider.loadMoreUserSearchResults();
        }
      }
    });
  }

  void _onSearchTextChanged() {
    final query = _searchController.text.trim();
    final provider = context.read<SearchProvider>();
    
    if (query.isNotEmpty && query.length >= 2) {
      provider.searchUsers(query);
    } else {
      provider.clearUserSearch();
    }
  }

  void _onSearchSubmitted(String query) {
    if (query.trim().isEmpty) return;
    
    _searchFocusNode.unfocus();
    final provider = context.read<SearchProvider>();
    provider.searchUsers(query.trim());
  }

  void _clearSearch() {
    _searchController.clear();
    _searchFocusNode.unfocus();
    final provider = context.read<SearchProvider>();
    provider.clearUserSearch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchSection(),
            Expanded(child: _buildSearchResults()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.black),
          ),
          Expanded(
            child: Center(
              child: Text(
                'Rechercher des utilisateurs',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(width: 48), // Pour équilibrer le bouton retour
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        onSubmitted: _onSearchSubmitted,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black,
        ),
        decoration: InputDecoration(
          hintText: 'Nom, prénom ou @username...',
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIcon: const Icon(Icons.search, color: Colors.black54),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.black54),
                  onPressed: _clearSearch,
                )
              : null,
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
    );
  }

  Widget _buildSearchResults() {
    return Consumer<SearchProvider>(
      builder: (context, provider, child) {
        // État de chargement initial
        if (provider.searchState == SearchState.loading && provider.searchResult.users.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.black),
          );
        }

        // Aucune recherche effectuée
        if (_searchController.text.isEmpty || _searchController.text.length < 2) {
          return _buildInitialState();
        }

        // État d'erreur
        if (provider.searchState == SearchState.error) {
          return _buildErrorState(
            provider.searchError ?? 'Erreur de recherche',
            () => provider.searchUsers(_searchController.text),
          );
        }

        // Aucun résultat trouvé
        if (provider.searchResult.users.isEmpty && provider.searchState != SearchState.loading) {
          return _buildNoResultsState();
        }

        // Afficher les utilisateurs trouvés
        return _buildUsersList(provider);
      },
    );
  }

  Widget _buildInitialState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'Rechercher des utilisateurs',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tapez au moins 2 caractères pour\ncommencer votre recherche',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[500],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_search,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'Aucun utilisateur trouvé',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Vérifiez l\'orthographe ou\nessayez un autre nom',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[500],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red[400],
          ),
          const SizedBox(height: 24),
          Text(
            'Une erreur s\'est produite',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            error,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[500],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Réessayer',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList(SearchProvider provider) {
    return RefreshIndicator(
      onRefresh: () async {
        if (_searchController.text.isNotEmpty) {
          await provider.searchUsers(_searchController.text);
        }
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: provider.searchResult.users.length + 
                   (provider.isLoadingMoreSearch ? 1 : 0),
        itemBuilder: (context, index) {
          // Indicateur de chargement en bas
          if (index >= provider.searchResult.users.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(color: Colors.black),
              ),
            );
          }

          final user = provider.searchResult.users[index];
          return _buildUserCard(user, provider);
        },
      ),
    );
  }

  Widget _buildUserCard(UserSearchResult user, SearchProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _navigateToUserProfile(user, provider),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar utilisateur
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey[200]!, width: 2),
                ),
                child: CircleAvatar(
                  radius: 26,
                  backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                      ? NetworkImage(user.avatarUrl!)
                      : null,
                  backgroundColor: Colors.grey[100],
                  child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                      ? Text(
                          user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : '?',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        )
                      : null,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Informations utilisateur
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom complet avec badge créateur
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '${user.firstName} ${user.lastName}',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (user.isCreator) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.verified,
                            size: 16,
                            color: Colors.blue[600],
                          ),
                        ],
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Username
                    Text(
                      '@${user.username}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    
                    // Bio si disponible
                    if (user.bio != null && user.bio!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        user.bio!,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.grey[700],
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    
                    // Nombre d'abonnés si créateur
                    if (user.isCreator && user.followersCount > 0) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.people,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${user.followersCount} abonné${user.followersCount > 1 ? 's' : ''}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              // Flèche pour aller au profil
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToUserProfile(UserSearchResult user, SearchProvider provider) {
    // Enregistrer l'interaction de vue de profil
    provider.trackProfileView(user);
    
    // TODO: Implémenter la navigation vers le profil utilisateur
    debugPrint('Navigation vers le profil de ${user.username}');
    
    // Placeholder pour la navigation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Profil de ${user.firstName} ${user.lastName}',
          style: GoogleFonts.inter(fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.black,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}