import 'package:flutter/material.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';

class CategoriesSection extends StatelessWidget {
  final List<Category> categories;
  final String? selectedCategoryId;
  final ValueChanged<String?> onCategorySelected;

  const CategoriesSection({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
  });

  IconData _iconForCategory(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('tecnolog')) return Icons.laptop_mac_rounded;
    if (lower.contains('aliment') || lower.contains('comida')) return Icons.restaurant_rounded;
    if (lower.contains('servicio')) return Icons.code_rounded;
    if (lower.contains('educac')) return Icons.menu_book_rounded;
    if (lower.contains('ropa') || lower.contains('moda')) return Icons.checkroom_rounded;
    if (lower.contains('deporte')) return Icons.sports_basketball_rounded;
    if (lower.contains('salud')) return Icons.health_and_safety_rounded;
    return Icons.shopping_bag_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Categorias',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                GestureDetector(
                  onTap: () {},
                  child: Text(
                    'Ver todas',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 76,
            child: categories.isEmpty
                ? const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
                : ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length + 1, // +1 for "Todo"
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                // First item is always "Todo" (all)
                if (index == 0) {
                  final isActive = selectedCategoryId == null;
                  return GestureDetector(
                    onTap: () => onCategorySelected(null),
                    child: _CategoryChip(
                      icon: Icons.auto_awesome_rounded,
                      label: 'Todo',
                      isActive: isActive,
                    ),
                  );
                }

                final cat = categories[index - 1];
                final isActive = selectedCategoryId == cat.id.toString();
                return GestureDetector(
                  onTap: () => onCategorySelected(cat.id.toString()),
                  child: _CategoryChip(
                    icon: _iconForCategory(cat.nombre),
                    label: cat.nombre,
                    isActive: isActive,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;

  const _CategoryChip({
    required this.icon,
    required this.label,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      width: 80,
      decoration: BoxDecoration(
        color: isActive ? colors.primary : colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive ? colors.primary : colors.border,
        ),
        boxShadow: isActive
            ? [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 22,
            color: isActive ? Colors.white : colors.mutedForeground,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              color: isActive ? Colors.white : colors.mutedForeground,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
