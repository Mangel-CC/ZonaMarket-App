import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/app_theme.dart';
import '../screens/cart_screen.dart';
import '../screens/favorites_screen.dart';
import '../screens/notifications_screen.dart';

class MarketplaceHeader extends StatelessWidget {
  final String userName;
  final String userInitials;
  final int unreadNotifications;

  const MarketplaceHeader({
    super.key,
    required this.userName,
    required this.userInitials,
    this.unreadNotifications = 0,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          color: colors.card.withValues(alpha: 0.8),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Logo
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'ZM',
                        style: TextStyle(
                          color: colors.primaryForeground,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Greeting
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Hola, buen dia',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.mutedForeground,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          userName.isNotEmpty ? userName : '...',
                          style: Theme.of(context).textTheme.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Actions
                  _HeaderIconButton(
                    icon: Icons.favorite_outline_rounded,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const FavoritesScreen(),
                        ),
                      );
                    },
                  ),
                  _HeaderIconButton(
                    icon: Icons.shopping_cart_outlined,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const CartScreen(),
                        ),
                      );
                    },
                  ),
                  _HeaderIconButton(
                    icon: Icons.notifications_outlined,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      );
                    },
                    badgeCount: unreadNotifications > 0 ? unreadNotifications : null,
                    badgeColor: colors.accent,
                  ),
                  const SizedBox(width: 4),
                  // Avatar
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: colors.primaryLight,
                    child: Text(
                      userInitials.isNotEmpty ? userInitials : '?',
                      style: TextStyle(
                        color: colors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final int? badgeCount;
  final Color? badgeColor;

  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
    this.badgeCount,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: onTap,
          icon: Icon(icon, size: 20),
          color: colors.mutedForeground,
          padding: const EdgeInsets.all(6),
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          splashRadius: 20,
        ),
        if (badgeCount != null)
          Positioned(
            top: 2,
            right: 2,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: badgeColor ?? colors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: colors.card, width: 1.5),
              ),
              child: Center(
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
