import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import '../widgets/marketplace_header.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/promo_banner.dart';
import '../widgets/quick_actions.dart';
import '../widgets/categories.dart';
import '../widgets/product_grid.dart';
// bottom_nav is now handled by MainShell

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // User data
  String _userName = '';
  String _userInitials = '';
  int _userId = 0;

  // Products
  List<Product> _products = [];
  bool _loadingProducts = true;

  // Categories
  List<Category> _categories = [];
  String? _selectedCategoryId;

  // Search
  String _searchQuery = '';

  // Favorites
  Set<int> _favoriteProductIds = {};

  // Notifications
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadUserData(),
      _loadCategories(),
      _loadProducts(),
      _loadFavorites(),
      _loadNotificationCount(),
    ]);
  }

  Future<void> _loadUserData() async {
    final userData = await ProductService.getUserData();
    if (userData != null && mounted) {
      final nombre = userData['nombre'] as String? ?? '';
      final apellidos = userData['apellidos'] as String? ?? '';
      final id = userData['id'];
      setState(() {
        _userName = '$nombre $apellidos'.trim();
        _userId = id is int ? id : int.tryParse(id.toString()) ?? 0;
        _userInitials = _buildInitials(nombre, apellidos);
      });
    } else {
      // Fallback to stored data
      final user = await AuthService.getSavedUser();
      if (user != null && mounted) {
        setState(() {
          _userName = user.nombre;
          _userId = user.id;
          _userInitials = user.nombre.isNotEmpty ? user.nombre[0].toUpperCase() : '?';
        });
      }
    }
  }

  String _buildInitials(String nombre, String apellidos) {
    final first = nombre.isNotEmpty ? nombre[0].toUpperCase() : '';
    final last = apellidos.isNotEmpty ? apellidos[0].toUpperCase() : '';
    return '$first$last'.trim();
  }

  Future<void> _loadCategories() async {
    final data = await ProductService.getCategories();
    if (mounted) {
      setState(() {
        _categories = data.map((e) => Category.fromJson(e)).toList();
      });
    }
  }

  Future<void> _loadProducts() async {
    if (mounted) setState(() => _loadingProducts = true);
    final data = await ProductService.getProducts(
      searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      categoryId: _selectedCategoryId,
    );
    if (mounted) {
      setState(() {
        _products = data.map((e) => Product.fromJson(e)).toList();
        _loadingProducts = false;
      });
    }
  }

  Future<void> _loadFavorites() async {
    final data = await ProductService.getFavorites();
    if (mounted) {
      setState(() {
        _favoriteProductIds = data
            .map((e) {
          final pid = e['product_id'];
          return pid is int ? pid : int.tryParse(pid.toString()) ?? 0;
        })
            .toSet();
      });
    }
  }

  Future<void> _loadNotificationCount() async {
    final count = await ProductService.getUnreadNotificationsCount();
    if (mounted) {
      setState(() => _unreadNotifications = count);
    }
  }

  void _onSearch(String query) {
    _searchQuery = query;
    _loadProducts();
  }

  void _onCategorySelected(String? categoryId) {
    _selectedCategoryId = categoryId;
    _loadProducts();
  }

  Future<void> _onToggleFavorite(int productId) async {
    if (_userId == 0) {
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
      return;
    }
    final result = await ProductService.toggleFavorite(
      userId: _userId,
      productId: productId,
    );
    if (result != null && result['success'] == true && mounted) {
      final isFavorito = result['is_favorito'] as bool? ?? false;
      setState(() {
        if (isFavorito) {
          _favoriteProductIds.add(productId);
        } else {
          _favoriteProductIds.remove(productId);
        }
      });
    }
  }

  Future<void> _onRefresh() async {
    await _loadInitialData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Sticky header
          MarketplaceHeader(
            userName: _userName,
            userInitials: _userInitials,
            unreadNotifications: _unreadNotifications,
          ),
          // Scrollable content
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                child: Column(
                  children: [
                    SearchBarWidget(onSearch: _onSearch),
                    const PromoBanner(),
                    const QuickActions(),
                    CategoriesSection(
                      categories: _categories,
                      selectedCategoryId: _selectedCategoryId,
                      onCategorySelected: _onCategorySelected,
                    ),
                    ProductGrid(
                      products: _products,
                      isLoading: _loadingProducts,
                      favoriteIds: _favoriteProductIds,
                      onToggleFavorite: _onToggleFavorite,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      // bottomNavigationBar is now handled by MainShell
    );
  }
}
