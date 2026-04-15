import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../domain/entities/category_entity.dart';

class CategoryChipRow extends StatefulWidget {
  final List<CategoryEntity> categories;
  final String? selectedSlug;
  final Function(String) onTap;

  const CategoryChipRow({
    super.key,
    required this.categories,
    required this.selectedSlug,
    required this.onTap,
  });

  @override
  State<CategoryChipRow> createState() => _CategoryChipRowState();
}

class _CategoryChipRowState extends State<CategoryChipRow> {
  final ScrollController _scrollController = ScrollController();
  bool _isDragging = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _isDragging = true),
      onPointerUp: (_) => setState(() => _isDragging = false),
      onPointerCancel: (_) => setState(() => _isDragging = false),
      child: MouseRegion(
        cursor: _isDragging ? SystemMouseCursors.grabbing : SystemMouseCursors.grab,
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
              PointerDeviceKind.trackpad,
            },
          ),
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: widget.categories.length,
            itemBuilder: (ctx, i) {
              final category = widget.categories[i];
              final isSelected = category.slug == widget.selectedSlug;
              
              return Padding(
                padding: EdgeInsets.only(
                  left: i == 0 ? 0 : 8,
                  right: i == widget.categories.length - 1 ? 0 : 0,
                ),
                child: _CategoryChip(
                  category: category,
                  isSelected: isSelected,
                  onTap: () => widget.onTap(category.slug),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatefulWidget {
  final CategoryEntity category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_CategoryChip> createState() => _CategoryChipState();
}

class _CategoryChipState extends State<_CategoryChip> {
  bool _isHovered = false;
  bool _isPressed = false;

  Map<String, dynamic> _getMoodConfig() {
    final name = widget.category.name.toLowerCase();
    
    if (name.contains('buồn') || name.contains('buon')) {
      return {'colors': [const Color(0xFF1a1a2e), const Color(0xFF16213e)], 'icon': '😢', 'textColor': Colors.white};
    } else if (name.contains('vui')) {
      return {'colors': [const Color(0xFFf7971e), const Color(0xFFffd200)], 'icon': '😊', 'textColor': Colors.black87};
    } else if (name.contains('remix')) {
      return {'colors': [const Color(0xFF642B73), const Color(0xFFC6426E)], 'icon': '🎧', 'textColor': Colors.white};
    } else if (name.contains('ballad')) {
      return {'colors': [const Color(0xFF1a1a2e), const Color(0xFF4a00e0)], 'icon': '🎵', 'textColor': Colors.white};
    } else if (name.contains('rap')) {
      return {'colors': [const Color(0xFF232526), const Color(0xFF414345)], 'icon': '🎤', 'textColor': Colors.white};
    } else if (name.contains('rock')) {
      return {'colors': [const Color(0xFF870000), const Color(0xFF190A05)], 'icon': '🤘', 'textColor': Colors.white};
    } else if (name.contains('electronic')) {
      return {'colors': [const Color(0xFF00b09b), const Color(0xFF96c93d)], 'icon': '⚡', 'textColor': Colors.black87};
    } else if (name.contains('lofi')) {
      return {'colors': [const Color(0xFF2c3e50), const Color(0xFF3498db)], 'icon': '☕', 'textColor': Colors.white};
    }
    
    return {'colors': [const Color(0xFF2A2A2E), const Color(0xFF1E1E28)], 'icon': '✨', 'textColor': Colors.white};
  }

  @override
  Widget build(BuildContext context) {
    final config = _getMoodConfig();
    final List<Color> bgColors = config['colors'];
    final String defaultEmoji = config['icon'];
    final Color textColor = config['textColor'];
    final Color shadowColor = bgColors[0];
    
    final emoji = widget.category.emoji.isNotEmpty 
        ? widget.category.emoji 
        : defaultEmoji;

    final double scale = _isPressed ? 0.98 : (widget.isSelected ? 1.05 : (_isHovered ? 1.02 : 1.0));

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: widget.isSelected ? 1.0 : (_isHovered ? 1.0 : 0.75),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.ease,
            transform: Matrix4.diagonal3Values(scale, scale, 1.0),
            transformAlignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: bgColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: widget.isSelected 
                  ? Border.all(color: Colors.white, width: 2) 
                  : Border.all(color: Colors.transparent, width: 2),
              boxShadow: widget.isSelected
                  ? [
                      BoxShadow(
                        color: shadowColor.withValues(alpha: 0.6),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(
                  widget.category.name,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
