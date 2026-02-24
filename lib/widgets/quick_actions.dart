import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class _QuickActionItem {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final Color bgColor;

  const _QuickActionItem({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.bgColor,
  });
}

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  static final List<_QuickActionItem> _actions = [
    _QuickActionItem(
      icon: Icons.trending_up_rounded,
      label: 'Tendencia',
      description: 'Lo mas vendido',
      color: AppColors.primary,
      bgColor: AppColors.primaryLight,
    ),
    _QuickActionItem(
      icon: Icons.schedule_rounded,
      label: 'Recientes',
      description: 'Nuevos productos',
      color: AppColors.accent,
      bgColor: AppColors.accentLight,
    ),
    _QuickActionItem(
      icon: Icons.star_rounded,
      label: 'Valorados',
      description: 'Top calificados',
      color: AppColors.chartOrange,
      bgColor: const Color(0xFFFFF3E8),
    ),
    _QuickActionItem(
      icon: Icons.local_shipping_outlined,
      label: 'Envio gratis',
      description: 'Sin costo extra',
      color: AppColors.chartBlue,
      bgColor: const Color(0xFFE8F2FB),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: _actions.map((action) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: action == _actions.last ? 0 : 8,
              ),
              child: _QuickActionCard(action: action),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final _QuickActionItem action;

  const _QuickActionCard({required this.action});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: action.bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              action.icon,
              size: 20,
              color: action.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            action.label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.foreground,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
