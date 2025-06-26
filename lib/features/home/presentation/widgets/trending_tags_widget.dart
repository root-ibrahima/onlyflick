// lib/features/search/presentation/widgets/trending_tags_widget.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/search_models.dart';
import '../../../../core/providers/search_provider.dart';

/// Widget pour afficher les tags en tendance
class TrendingTagsWidget extends StatefulWidget {
  final Function(TagCategory)? onTagTap;
  final EdgeInsets? padding;
  final double height;
  final bool showTitle;
  final bool showStats;
  final String period;
  final int maxTags;

  const TrendingTagsWidget({
    super.key,
    this.onTagTap,
    this.padding,
    this.height = 80,
    this.showTitle = true,
    this.showStats = true,
    this.period = 'week',
    this.maxTags = 10,
  });

  @override
  State<TrendingTagsWidget> createState() => _TrendingTagsWidgetState();
}

class _TrendingTagsWidgetState extends State<TrendingTagsWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // Charger les trending tags au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<SearchProvider>();
      provider.loadTrendingTags(period: widget.period);
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SearchProvider>(
      builder: (context, provider, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: _shouldShow(provider) ? widget.height : 0,
          child: _buildContent(provider),
        );
      },
    );
  }

  bool _shouldShow(SearchProvider provider) {
    return provider.trendingTags.isNotEmpty || provider.isLoadingTrending;
  }

  Widget _buildContent(SearchProvider provider) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: widget.padding ?? const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showTitle) _buildHeader(provider),
            const SizedBox(height: 8),
            Expanded(child: _buildTagsList(provider)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(SearchProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.orange[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.trending_up,
              size: 16,
              color: Colors.orange[700],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Tendances',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _getPeriodDisplayName(widget.period),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
          const Spacer(),
          if (provider.isLoadingTrending)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.grey[400],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTagsList(SearchProvider provider) {
    if (provider.isLoadingTrending && provider.trendingTags.isEmpty) {
      return _buildLoadingShimmer();
    }

    if (provider.trendingTags.isEmpty) {
      return _buildEmptyState();
    }

    final tags = provider.trendingTags.take(widget.maxTags).toList();

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: tags.length,
      separatorBuilder: (context, index) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        final tag = tags[index];
        return TrendingTagChip(
          tag: tag,
          onTap: () => _onTagTap(tag.category),
          showStats: widget.showStats,
          animationDelay: Duration(milliseconds: index * 100),
        );
      },
    );
  }

  Widget _buildLoadingShimmer() {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 5,
      separatorBuilder: (context, index) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        return _buildShimmerChip();
      },
    );
  }

  Widget _buildShimmerChip() {
    return Container(
      width: 100,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(18),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 1000),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: [
              Colors.grey[200]!,
              Colors.grey[100]!,
              Colors.grey[200]!,
            ],
            stops: const [0.4, 0.5, 0.6],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        'Aucune tendance pour le moment',
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[500],
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  void _onTagTap(TagCategory category) {
    if (widget.onTagTap != null) {
      widget.onTagTap!(category);
    } else {
      // Par défaut, ajouter aux filtres du provider
      final provider = context.read<SearchProvider>();
      provider.toggleDiscoveryTag(category);
    }
  }

  String _getPeriodDisplayName(String period) {
    switch (period) {
      case '24h':
        return '24h';
      case 'week':
        return '7j';
      case 'month':
        return '30j';
      default:
        return period;
    }
  }
}

/// Widget pour un chip de tag trending individuel
class TrendingTagChip extends StatefulWidget {
  final TrendingTag tag;
  final VoidCallback onTap;
  final bool showStats;
  final Duration animationDelay;

  const TrendingTagChip({
    super.key,
    required this.tag,
    required this.onTap,
    this.showStats = true,
    this.animationDelay = Duration.zero,
  });

  @override
  State<TrendingTagChip> createState() => _TrendingTagChipState();
}

class _TrendingTagChipState extends State<TrendingTagChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuart,
    ));

    // Démarrer l'animation avec délai
    Future.delayed(widget.animationDelay, () {
      if (mounted) {
        _animationController.forward();
      }
    });
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
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: _buildChip(),
          ),
        );
      },
    );
  }

  Widget _buildChip() {
    final tagColor = _getTagColor(widget.tag.category);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                tagColor.withOpacity(0.1),
                tagColor.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: tagColor.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: tagColor.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
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
                  color: tagColor.withOpacity(0.9),
                ),
              ),
              if (widget.showStats) ...[
                const SizedBox(width: 6),
                _buildStatsIndicator(tagColor),
              ],
              if (widget.tag.isHot) ...[
                const SizedBox(width: 4),
                _buildHotIndicator(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsIndicator(Color tagColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: tagColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _formatCount(widget.tag.postsCount),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: tagColor,
        ),
      ),
    );
  }

  Widget _buildHotIndicator() {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.orange[600],
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(
        Icons.whatshot,
        size: 10,
        color: Colors.white,
      ),
    );
  }

  Color _getTagColor(TagCategory category) {
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

  String _formatCount(int count) {
    if (count < 1000) return count.toString();
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(0)}k';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }
}

/// Widget compact pour les trending tags
class CompactTrendingTags extends StatelessWidget {
  final Function(TagCategory)? onTagTap;
  final int maxTags;
  final bool showPeriod;

  const CompactTrendingTags({
    super.key,
    this.onTagTap,
    this.maxTags = 5,
    this.showPeriod = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SearchProvider>(
      builder: (context, provider, child) {
        if (provider.trendingTags.isEmpty) {
          return const SizedBox.shrink();
        }

        final tags = provider.trendingTags.take(maxTags).toList();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showPeriod)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Text(
                  'Tendances',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: tags.map((tag) {
                return TrendingTagChip(
                  tag: tag,
                  onTap: () => onTagTap?.call(tag.category),
                  showStats: false,
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}

/// Widget avec sélecteur de période
class TrendingTagsWithPeriodSelector extends StatefulWidget {
  final Function(TagCategory)? onTagTap;
  final EdgeInsets? padding;

  const TrendingTagsWithPeriodSelector({
    super.key,
    this.onTagTap,
    this.padding,
  });

  @override
  State<TrendingTagsWithPeriodSelector> createState() =>
      _TrendingTagsWithPeriodSelectorState();
}

class _TrendingTagsWithPeriodSelectorState
    extends State<TrendingTagsWithPeriodSelector> {
  String _selectedPeriod = 'week';
  final List<String> _periods = ['24h', 'week', 'month'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildPeriodSelector(),
        const SizedBox(height: 8),
        TrendingTagsWidget(
          onTagTap: widget.onTagTap,
          padding: widget.padding,
          period: _selectedPeriod,
          showTitle: false,
        ),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _periods.map((period) {
          final isSelected = period == _selectedPeriod;
          return Expanded(
            child: GestureDetector(
              onTap: () => _onPeriodChanged(period),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.black : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getPeriodDisplayName(period),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.grey[600],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _onPeriodChanged(String period) {
    setState(() {
      _selectedPeriod = period;
    });
    
    final provider = context.read<SearchProvider>();
    provider.loadTrendingTags(period: period);
  }

  String _getPeriodDisplayName(String period) {
    switch (period) {
      case '24h':
        return '24h';
      case 'week':
        return '7 jours';
      case 'month':
        return '30 jours';
      default:
        return period;
    }
  }
}

/// Widget en grille pour les trending tags
class TrendingTagsGrid extends StatelessWidget {
  final Function(TagCategory)? onTagTap;
  final int crossAxisCount;

  const TrendingTagsGrid({
    super.key,
    this.onTagTap,
    this.crossAxisCount = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SearchProvider>(
      builder: (context, provider, child) {
        if (provider.trendingTags.isEmpty) {
          return const SizedBox.shrink();
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 3,
          ),
          itemCount: provider.trendingTags.length,
          itemBuilder: (context, index) {
            final tag = provider.trendingTags[index];
            return TrendingTagChip(
              tag: tag,
              onTap: () => onTagTap?.call(tag.category),
              showStats: true,
              animationDelay: Duration(milliseconds: index * 50),
            );
          },
        );
      },
    );
  }
}