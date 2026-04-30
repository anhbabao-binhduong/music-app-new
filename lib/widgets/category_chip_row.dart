import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:music_app/core/constants/colors.dart';
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;
    final name = widget.category.name.toLowerCase();

    // Keep the same mood/emoji mapping, but drive colors from the project palette
    // (kAccent/kAccentPink) + theme surface tokens.
    final baseBg = isLight
        ? <Color>[cs.surfaceContainerHighest, cs.surfaceContainer]
        : <Color>[cs.surfaceContainerHigh, cs.surfaceContainerLowest];

    if (name.contains('vui') || name.contains('summer') || name.contains('dance')) {
      return {
        'colors': baseBg,
        'icon': '😊',
        'textColor': cs.onSurface,
        'borderColor': kAccentPink,
      };
    } else if (name.contains('buồn') || name.contains('buon') || name.contains('lofi')) {
      return {
        'colors': baseBg,
        'icon': '☕',
        'textColor': cs.onSurface,
        'borderColor': kAccent,
      };
    } else if (name.contains('remix') || name.contains('electronic')) {
      return {
        'colors': baseBg,
        'icon': '⚡',
        'textColor': cs.onSurface,
        'borderColor': kAccent,
      };
    } else if (name.contains('rap') || name.contains('rock')) {
      return {
        'colors': baseBg,
        'icon': '🎤',
        'textColor': cs.onSurface,
        'borderColor': kAccent,
      };
    }

    return {
      'colors': baseBg,
      'icon': '✨',
      'textColor': cs.onSurface,
      'borderColor': kAccent,
    };
  }

  @override
  Widget build(BuildContext context) {
    final config = _getMoodConfig();
    final List<Color> bgColors = config['colors'];
    final String defaultEmoji = config['icon'];
    final Color textColor = config['textColor'];
    final Color borderColor = config['borderColor'];
    final Color shadowColor = borderColor;
    
    final emoji = widget.category.emoji.isNotEmpty 
        ? widget.category.emoji 
        : defaultEmoji;

    final double scale = _isPressed ? 0.98 : (widget.isSelected ? 1.04 : (_isHovered ? 1.01 : 1.0));

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
          opacity: widget.isSelected ? 1.0 : (_isHovered ? 0.96 : 0.82),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.ease,
            transform: Matrix4.diagonal3Values(scale, scale, 1.0),
            transformAlignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: bgColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: widget.isSelected
                    ? borderColor.withValues(alpha: 0.9)
                    : borderColor.withValues(alpha: _isHovered ? 0.28 : 0.12),
                width: widget.isSelected ? 1.6 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: shadowColor.withValues(alpha: widget.isSelected ? 0.24 : 0.08),
                  blurRadius: widget.isSelected ? 18 : 10,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                 Text(
                   emoji,
                   style: GoogleFonts.dmSans(
                     fontSize: 15,
                     fontWeight: FontWeight.w600,
                     height: 1.0,
                   ),
                 ),
                const SizedBox(width: 8),
                Text(
                  widget.category.name,
                  style: GoogleFonts.dmSans(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                    letterSpacing: 0.1,
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
