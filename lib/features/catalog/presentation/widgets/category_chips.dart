import 'package:flutter/material.dart';

class CategoryChips extends StatelessWidget {
  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String?> onCategorySelected;

  const CategoryChips({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final items = ['All', ...categories];
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final onSurface = colorScheme.onSurface;
    final accent = colorScheme.primary;

    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final category = items[index];
          final isSelected = isAll
              ? selectedCategory == null
              : selectedCategory == category;

          final displayLabel = isAll
              ? 'All'
              : category.replaceAll(RegExp(r"'s"), 's').toUpperCase();

          final selectedStyle = (textTheme.bodyMedium ?? const TextStyle())
              .copyWith(color: onSurface, fontWeight: FontWeight.w700);

          final unselectedStyle = (textTheme.bodyMedium ?? const TextStyle())
              .copyWith(
                color: onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
              );

          return Material(
            color: Colors.transparent,
            child: InkWell(
              splashColor: Colors.transparent,
              hoverColor: Colors.transparent,
              highlightColor: Colors.transparent,
              focusColor: Colors.transparent,
              onTap: () {
                onCategorySelected(isAll ? null : category);
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      style: isSelected ? selectedStyle : unselectedStyle,
                      child: Text(displayLabel),
                    ),
                    const SizedBox(height: 6),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      height: 2,
                      width: isSelected ? 20 : 0,
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
