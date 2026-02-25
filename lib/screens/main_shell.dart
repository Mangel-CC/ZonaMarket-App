import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'explore_screen.dart';
import 'categories_screen.dart';
import 'orders_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';
import '../widgets/bottom_nav.dart';
import '../services/auth_service.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),
    ExploreScreen(),
    CategoriesScreen(),
    OrdersScreen(),
    ProfileScreen(),
  ];

  Future<void> _onNavTap(int index) async {
    // Tabs 3 (Pedidos) y 4 (Perfil) requieren sesión iniciada
    if (index >= 3) {
      final loggedIn = await AuthService.isLoggedIn();
      if (!loggedIn) {
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
        return;
      }
    }
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: MarketplaceBottomNav(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }
}
