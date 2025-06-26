// lib/features/search/presentation/widgets/search_suggestions_widget.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/search_models.dart';
import '../../../../core/providers/search_provider.dart';

/// Widget d'affichage des suggestions de recherche
class SearchSuggestionsWidget extends StatefulWidget {
  final Function(SearchSuggestion) onSuggestionTap;
  final EdgeInsets? padding;
  final double? maxHeight;
  final bool showRecentSearches;

  const SearchSuggestionsWidget({
    super.key,
    required this.onSuggestionTap,
    this.padding,
    this.maxHeight,
    this.showRecentSearches = true,
  });

  @override
  State<SearchSuggestionsWidget> createState() => _SearchSuggestionsWidgetState();
}

class _SearchSuggestionsWidgetState extends State<SearchSuggestionsWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        constraints: widget.maxHeight != null 
            ? BoxConstraints(maxHeight: widget.maxHeight!)
            : null,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Consumer<SearchProvider>(
          builder: (context, provider, child) {
            return _buildContent(provider);
          },
        ),
      ),
    );
  }

  Widget _buildContent(SearchProvider provider) {
    if (provider.isLoadingSuggestions) {
      return _buildLoadingState();
    }

    if (provider.suggestions.isEmpty) {
      return _buildEmptyState(provider);
    }

    return _buildSuggestionsList(provider.suggestions);
  }

  Widget _buildLoadingState() {
    return Container(
      height: 120,
      padding: widget.padding ?? const EdgeInsets.all(24),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.black,
                strokeWidth: 2,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Recherche en cours...',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(SearchProvider provider) {
    return Container(
      padding: widget.padding ?? const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            'Tapez pour voir des suggestions',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Recherchez des utilisateurs ou des tags',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
          if (widget.showRecentSearches && provider.trendingTags.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildTrendingTags(provider.trendingTags.take(5).toList()),
          ],
        ],
      ),
    );
  }

  Widget _buildSuggestionsList(List<SearchSuggestion> suggestions) {
    return ListView.separated(
      shrinkWrap: true,
      padding: widget.padding ?? const EdgeInsets.symmetric(vertical: 8),
      itemCount: suggestions.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        color: Colors.grey[200],
        indent: 60,
      ),
      itemBuilder: (context, index) {
        final suggestion = suggestions[index];
        return _buildSuggestionTile(suggestion, index);
      },
    );
  }

  Widget _buildSuggestionTile(SearchSuggestion suggestion, int index) {
    return AnimatedSlide(
      duration: Duration(milliseconds: 200 + (index * 50)),
      offset: Offset(0, _animationController.value == 1.0 ? 0 : 0.5),
      child: AnimatedOpacity(
        duration: Duration(milliseconds: 200 + (index * 50)),
        opacity: _animationController.value,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => widget.onSuggestionTap(suggestion),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  _buildSuggestionIcon(suggestion),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          suggestion.display,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        _buildSuggestionSubtitle(suggestion),
                      ],
                    ),
                  ),
                  _buildSuggestionTrailing(suggestion),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionIcon(SearchSuggestion suggestion) {
    if (suggestion.isUser) {
      return CircleAvatar(
        radius: 20,
        backgroundColor: Colors.grey[200],
        backgroundImage: suggestion.avatarUrl != null 
            ? NetworkImage(suggestion.avatarUrl!)
            : null,
        child: suggestion.avatarUrl == null 
            ? Icon(
                Icons.person,
                color: Colors.grey[600],
                size: 20,
              )
            : null,
      );
    } else {
      // Tag suggestion
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _getTagColor(suggestion.category),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            suggestion.category?.emoji ?? '🏷️',
            style: const TextStyle(fontSize: 18),
          ),
        ),
      );
    }
  }

  Widget _buildSuggestionSubtitle(SearchSuggestion suggestion) {
    if (suggestion.isUser) {
      return Row(
        children: [
          Icon(
            Icons.person_outline,
            size: 14,
            color: Colors.grey[500],
          ),
          const SizedBox(width: 4),
          Text(
            'Utilisateur',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
          if (suggestion.userId != null) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.verified,
              size: 14,
              color: Colors.blue[400],
            ),
          ],
        ],
      );
    } else {
      return Row(
        children: [
          Icon(
            Icons.tag,
            size: 14,
            color: Colors.grey[500],
          ),
          const SizedBox(width: 4),
          Text(
            'Tag ${suggestion.category?.displayName ?? ''}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      );
    }
  }

  Widget _buildSuggestionTrailing(SearchSuggestion suggestion) {
    return Icon(
      suggestion.isUser ? Icons.arrow_forward_ios : Icons.add,
      size: 16,
      color: Colors.grey[400],
    );
  }

  Widget _buildTrendingTags(List<TrendingTag> trendingTags) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Icon(
                Icons.trending_up,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                'Tendances',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 32,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            itemCount: trendingTags.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final tag = trendingTags[index];
              return _buildTrendingTagChip(tag);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTrendingTagChip(TrendingTag tag) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          final suggestion = SearchSuggestion(
            type: 'tag',
            text: tag.category.value,
            display: '${tag.emoji} ${tag.displayName}',
            category: tag.category,
          );
          widget.onSuggestionTap(suggestion);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getTagColor(tag.category).withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _getTagColor(tag.category).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tag.emoji,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(width: 4),
              Text(
                tag.displayName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _getTagColor(tag.category),
                ),
              ),
              if (tag.isHot) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.whatshot,
                  size: 12,
                  color: Colors.orange[600],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getTagColor(TagCategory? category) {
    if (category == null) return Colors.grey;
    
    switch (category) {
      case TagCategory.art:
        return Colors.purple;
      case TagCategory.music:
        return Colors.pink;
      case TagCategory.sport:
        return Colors.green;
      case TagCategory.cinema:
        return Colors.red;
      case TagCategory.tech:
        return Colors.blue;
      case TagCategory.fashion:
        return Colors.orange;
      case TagCategory.food:
        return Colors.amber;
      case TagCategory.travel:
        return Colors.teal;
      case TagCategory.gaming:
        return Colors.indigo;
      case TagCategory.lifestyle:
        return Colors.brown;
    }
  }
}

/// Widget compact pour suggestions rapides
class CompactSuggestionsWidget extends StatelessWidget {
  final Function(SearchSuggestion) onSuggestionTap;
  final int maxItems;

  const CompactSuggestionsWidget({
    super.key,
    required this.onSuggestionTap,
    this.maxItems = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SearchProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingSuggestions) {
          return const SizedBox(
            height: 40,
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.black,
                  strokeWidth: 2,
                ),
              ),
            ),
          );
        }

        final suggestions = provider.suggestions.take(maxItems).toList();
        
        if (suggestions.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: suggestions.map((suggestion) {
              return ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: suggestion.isUser 
                      ? Colors.blue[100] 
                      : Colors.orange[100],
                  child: Icon(
                    suggestion.isUser ? Icons.person : Icons.tag,
                    size: 16,
                    color: suggestion.isUser ? Colors.blue : Colors.orange,
                  ),
                ),
                title: Text(
                  suggestion.display,
                  style: const TextStyle(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => onSuggestionTap(suggestion),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

/// Widget de suggestions avec recherches récentes
class SuggestionsWithHistoryWidget extends StatelessWidget {
  final Function(SearchSuggestion) onSuggestionTap;
  final List<String> recentSearches;
  final VoidCallback? onClearHistory;

  const SuggestionsWithHistoryWidget({
    super.key,
    required this.onSuggestionTap,
    this.recentSearches = const [],
    this.onClearHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SearchProvider>(
      builder: (context, provider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Suggestions actuelles
            if (provider.suggestions.isNotEmpty) ...[
              SearchSuggestionsWidget(
                onSuggestionTap: onSuggestionTap,
                showRecentSearches: false,
              ),
              if (recentSearches.isNotEmpty) const SizedBox(height: 16),
            ],
            
            // Recherches récentes
            if (recentSearches.isNotEmpty) ...[
              _buildRecentSearchesSection(),
            ],
          ],
        );
      },
    );
  }

  Widget _buildRecentSearchesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.history,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                'Recherches récentes',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const Spacer(),
              if (onClearHistory != null)
                GestureDetector(
                  onTap: onClearHistory,
                  child: Text(
                    'Effacer',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: recentSearches.take(6).map((search) {
              return GestureDetector(
                onTap: () {
                  final suggestion = SearchSuggestion(
                    type: 'search',
                    text: search,
                    display: search,
                  );
                  onSuggestionTap(suggestion);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    search,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black87,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}