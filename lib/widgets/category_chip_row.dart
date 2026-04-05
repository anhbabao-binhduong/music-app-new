import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../domain/entities/category_entity.dart';

// ─── Fix cuộn chuột trên Web ─────────────────────────────
class _AllScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  };
}

class CategoryChipRow extends StatefulWidget {
  final List<CategoryEntity>  categories;
  final String?               selectedSlug;
  final ValueChanged<String?> onTap;

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
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allCategories = [
      _ChipData(label: 'Tất cả', emoji: '🎵', color: const Color(0xFF534AB7), slug: null),
      ...widget.categories.map((cat) => _ChipData(
        label: cat.name,
        emoji: cat.emoji,
        color: _hexToColor(cat.color),
        slug: cat.slug,
      )),
    ];

    return ScrollConfiguration(
      behavior: _AllScrollBehavior(),
      child: ListView.separated(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        itemCount: allCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final chip = allCategories[i];
          final isSelected = widget.selectedSlug == chip.slug;
          return _CategoryChip(
            data: chip,
            isSelected: isSelected,
            onTap: () => widget.onTap(chip.slug),
          );
        },
      ),
    );
  }

  static Color _hexToColor(String hex) {
    final clean = hex.replaceAll('#', '');
    if (clean.length != 6) return const Color(0xFF888888);
    return Color(int.parse('FF$clean', radix: 16));
  }
}

class _ChipData {
  final String  label;
  final String  emoji;
  final Color   color;
  final String? slug;
  const _ChipData({required this.label, required this.emoji, required this.color, required this.slug});
}

class _CategoryChip extends StatelessWidget {
  final _ChipData    data;
  final bool         isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.data,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [data.color, data.color.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : data.color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected
                ? data.color
                : data.color.withOpacity(0.25),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: data.color.withOpacity(0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(data.emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              data.label,
              style: TextStyle(
                fontSize:   13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? Colors.white
                    : data.color.withOpacity(0.85),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}