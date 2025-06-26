// lib/features/search/presentation/widgets/tags_filter_widget.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/search_models.dart';
import '../../../../core/providers/search_provider.dart';

/// Widget pour filtrer par tags avec interface moderne
class TagsFilterWidget extends StatefulWidget {
  final bool isDiscoveryMode;
  final EdgeInsets? padding;
  final double height;
  final bool showClearButton;
  final bool showSelectAll;

  const TagsFilterWidget({
    super.key,
    required this.isDiscoveryMode,
    this.padding,
    this.height = 60.0,
    this.showClearButton = true,
    this.showSelectAll = false,
  });

  @override
  State<TagsFilterWidget> createState() => _TagsFilterWidgetState();
}

class _TagsFilterWidgetState extends State<TagsFilterWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _slideAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1),
            end: Offset.zero,
          ).animate(_slideAnimation),
          child: Container(
            height: widget.height,
            padding: widget.padding ?? const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey[200]!,
                  width: 1,
                ),
              ),
            ),
            child: Consumer<SearchProvider>(
              builder: (context, provider, child) {
                final selectedTags = widget.isDiscoveryMode
                    ? provider.discoveryTags
                    : provider.selectedTags;
                
                return Row(
                  children: [
                    if (widget.showSelectAll) _buildSelectAllButton(provider),
                    Expanded(
                      child: _buildTagsList(provider, selectedTags),
                    ),
                    if (widget.showClearButton && selectedTags.isNotEmpty)
                      _buildClearButton(provider),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectAllButton(SearchProvider provider) {
    final allTags = TagCategory.values;
    final selectedTags = widget.isDiscoveryMode
        ? provider.discoveryTags
        : provider.selectedTags;
    final isAllSelected = selectedTags.length == allTags.length;

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _toggleSelectAll(provider, isAllSelected),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isAllSelected ? Colors.black : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isAllSelected ? Colors.black : Colors.grey[300]!,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isAllSelected ? Icons.check_circle : Icons.circle_outlined,
                  size: 16,
                  color: isAllSelected ? Colors.white : Colors.grey[600],
                ),
                const SizedBox(width: 6),
                Text(
                  'Tout',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isAllSelected ? Colors.white : Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTagsList(SearchProvider provider, List<TagCategory> selectedTags) {
    return ListView.separated(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: TagCategory.values.length,
      separatorBuilder: (context, index) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        final tag = TagCategory.values[index];
        final isSelected = selectedTags.contains(tag);
        
        return AnimatedContainer(
          duration: Duration(milliseconds: 200 + (index * 50)),
          child: TagFilterChip(
            tag: tag,
            isSelected: isSelected,
            onTap: () => _toggleTag(provider, tag),
            animationDelay: index * 50,
          ),
        );
      },
    );
  }

  Widget _buildClearButton(SearchProvider provider) {
    return Padding(
      padding: const EdgeInsets.only(right: 16, left: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _clearAllFilters(provider),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.clear,
                  size: 16,
                  color: Colors.red[600],
                ),
                const SizedBox(width: 4),
                Text(
                  'Effacer',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.red[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _toggleTag(SearchProvider provider, TagCategory tag) {
    if (widget.isDiscoveryMode) {
      provider.toggleDiscoveryTag(tag);
    } else {
      provider.toggleSearchTag(tag);
    }
  }

  void _toggleSelectAll(SearchProvider provider, bool isAllSelected) {
    if (isAllSelected) {
      _clearAllFilters(provider);
    } else {
      // Sélectionner tous les tags
      for (final tag in TagCategory.values) {
        final selectedTags = widget.isDiscoveryMode
            ? provider.discoveryTags
            : provider.selectedTags;
        
        if (!selectedTags.contains(tag)) {
          _toggleTag(provider, tag);
        }
      }
    }
  }

  void _clearAllFilters(SearchProvider provider) {
    if (widget.isDiscoveryMode) {
      provider.clearDiscoveryFilters();
    } else {
      provider.clearSearchFilters();
    }
  }
}

/// Widget pour un chip de tag individuel
class TagFilterChip extends StatefulWidget {
  final TagCategory tag;
  final bool isSelected;
  final VoidCallback onTap;
  final int animationDelay;

  const TagFilterChip({
    super.key,
    required this.tag,
    required this.isSelected,
    required this.onTap,
    this.animationDelay = 0,
  });

  @override
  State<TagFilterChip> createState() => _TagFilterChipState();
}

class _TagFilterChipState extends State<TagFilterChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Animation d'entrée avec délai
    Future.delayed(Duration(milliseconds: widget.animationDelay), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void didUpdateWidget(TagFilterChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isSelected != oldWidget.isSelected) {
      // Animation de sélection/désélection
      _animationController.forward().then((_) {
        if (mounted) {
          _animationController.reverse().then((_) {
            if (mounted) {
              _animationController.forward();
            }
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: widget.isSelected 
                        ? _getTagColor(widget.tag)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: widget.isSelected 
                          ? _getTagColor(widget.tag)
                          : Colors.grey[300]!,
                      width: 1.5,
                    ),
                    boxShadow: widget.isSelected ? [
                      BoxShadow(
                        color: _getTagColor(widget.tag).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ] : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.tag.emoji,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.tag.displayName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: widget.isSelected 
                              ? Colors.white 
                              : Colors.grey[700],
                        ),
                      ),
                      if (widget.isSelected) ...[
                        const SizedBox(width: 6),
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getTagColor(TagCategory tag) {
    switch (tag) {
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

/// Widget vertical pour sélection de tags dans une modal
class VerticalTagsSelector extends StatelessWidget {
  final List<TagCategory> selectedTags;
  final Function(TagCategory) onTagToggle;
  final bool showSelectAll;
  final VoidCallback? onSelectAll;
  final VoidCallback? onClearAll;

  const VerticalTagsSelector({
    super.key,
    required this.selectedTags,
    required this.onTagToggle,
    this.showSelectAll = true,
    this.onSelectAll,
    this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showSelectAll) _buildHeaderActions(),
        const SizedBox(height: 16),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 3,
            ),
            itemCount: TagCategory.values.length,
            itemBuilder: (context, index) {
              final tag = TagCategory.values[index];
              final isSelected = selectedTags.contains(tag);
              
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onTagToggle(tag),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? _getTagColor(tag).withOpacity(0.1)
                          : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected 
                            ? _getTagColor(tag)
                            : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          tag.emoji,
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            tag.displayName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isSelected 
                                  ? _getTagColor(tag)
                                  : Colors.grey[700],
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            size: 20,
                            color: _getTagColor(tag),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderActions() {
    final isAllSelected = selectedTags.length == TagCategory.values.length;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            'Catégories (${selectedTags.length}/${TagCategory.values.length})',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const Spacer(),
          if (selectedTags.isNotEmpty)
            TextButton(
              onPressed: onClearAll,
              child: const Text(
                'Effacer tout',
                style: TextStyle(color: Colors.red),
              ),
            ),
          TextButton(
            onPressed: onSelectAll,
            child: Text(
              isAllSelected ? 'Désélectionner' : 'Tout sélectionner',
              style: const TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  Color _getTagColor(TagCategory tag) {
    switch (tag) {
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

/// Widget compact pour afficher les tags sélectionnés
class SelectedTagsDisplay extends StatelessWidget {
  final List<TagCategory> selectedTags;
  final Function(TagCategory)? onTagRemove;
  final int maxDisplayTags;

  const SelectedTagsDisplay({
    super.key,
    required this.selectedTags,
    this.onTagRemove,
    this.maxDisplayTags = 3,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedTags.isEmpty) return const SizedBox.shrink();

    final displayTags = selectedTags.take(maxDisplayTags).toList();
    final remainingCount = selectedTags.length - maxDisplayTags;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ...displayTags.map((tag) => _buildTagChip(tag)),
          if (remainingCount > 0) _buildMoreChip(remainingCount),
        ],
      ),
    );
  }

  Widget _buildTagChip(TagCategory tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getTagColor(tag).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getTagColor(tag).withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tag.emoji,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(width: 4),
          Text(
            tag.displayName,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _getTagColor(tag),
            ),
          ),
          if (onTagRemove != null) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => onTagRemove!(tag),
              child: Icon(
                Icons.close,
                size: 14,
                color: _getTagColor(tag),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMoreChip(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '+$count',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Color _getTagColor(TagCategory tag) {
    switch (tag) {
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