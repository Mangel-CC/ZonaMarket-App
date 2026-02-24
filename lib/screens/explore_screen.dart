import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/product_card.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  List<Product> _products = [];
  List<Category> _categories = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedCategoryId;
  Set<int> _favoriteIds = {};
  int _userId = 0;

  // Recent searches persisted via SharedPreferences
  static const String _recentSearchesKey = 'zona_recent_searches';
  static const int _maxRecentSearches = 10;
  List<String> _recentSearches = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadProducts(),
      _loadCategories(),
      _loadFavorites(),
      _loadUserId(),
      _loadRecentSearches(),
    ]);
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_recentSearchesKey);
    if (saved != null && mounted) {
      setState(() => _recentSearches = saved);
    }
  }

  Future<void> _saveRecentSearch(String term) async {
    final trimmed = term.trim();
    if (trimmed.isEmpty) return;

    setState(() {
      _recentSearches.remove(trimmed);
      _recentSearches.insert(0, trimmed);
      if (_recentSearches.length > _maxRecentSearches) {
        _recentSearches = _recentSearches.sublist(0, _maxRecentSearches);
      }
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentSearchesKey, _recentSearches);
  }

  Future<void> _removeRecentSearch(String term) async {
    setState(() => _recentSearches.remove(term));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentSearchesKey, _recentSearches);
  }

  Future<void> _clearRecentSearches() async {
    setState(() => _recentSearches.clear());
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentSearchesKey);
  }

  Future<void> _loadUserId() async {
    final user = await AuthService.getSavedUser();
    if (user != null && mounted) {
      setState(() => _userId = user.id);
    }
  }

  Future<void> _loadProducts() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final data = await ProductService.getProducts(
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        categoryId: _selectedCategoryId,
      );
      if (mounted) {
        setState(() {
          _products = data.map((e) => Product.fromJson(e)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCategories() async {
    final data = await ProductService.getCategories();
    if (mounted) {
      setState(() {
        _categories = data.map((e) => Category.fromJson(e)).toList();
      });
    }
  }

  Future<void> _loadFavorites() async {
    final data = await ProductService.getFavorites();
    if (mounted) {
      setState(() {
        _favoriteIds = data
            .map((e) {
          final pid = e['product_id'];
          return pid is int ? pid : int.tryParse(pid.toString()) ?? 0;
        })
            .toSet();
      });
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() => _searchQuery = value);
      _loadProducts();
    });
  }

  void _onSearchSubmitted(String value) {
    _debounce?.cancel();
    final trimmed = value.trim();
    if (trimmed.isNotEmpty) _saveRecentSearch(trimmed);
    setState(() => _searchQuery = trimmed);
    _loadProducts();
  }

  void _onQuickSearch(String term) {
    _searchController.text = term;
    _saveRecentSearch(term);
    setState(() => _searchQuery = term);
    _loadProducts();
  }

  void _onCategoryTap(String? catId) {
    setState(() {
      _selectedCategoryId = _selectedCategoryId == catId ? null : catId;
    });
    _loadProducts();
  }

  Future<void> _onToggleFavorite(int productId) async {
    if (_userId == 0) return;
    final result = await ProductService.toggleFavorite(
      userId: _userId,
      productId: productId,
    );
    if (result != null && result['success'] == true && mounted) {
      final isFavorito = result['is_favorito'] as bool? ?? false;
      setState(() {
        if (isFavorito) {
          _favoriteIds.add(productId);
        } else {
          _favoriteIds.remove(productId);
        }
      });
    }
  }

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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Explorar',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontSize: 26,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Encuentra lo que necesitas',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),

                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      onSubmitted: _onSearchSubmitted,
                      decoration: const InputDecoration(
                        hintText: 'Buscar productos, servicios...',
                        hintStyle: TextStyle(
                          color: AppColors.mutedForeground,
                          fontSize: 14,
                        ),
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(left: 12, right: 8),
                          child: Icon(Icons.search_rounded, size: 20, color: AppColors.mutedForeground),
                        ),
                        prefixIconConstraints: BoxConstraints(minWidth: 40, minHeight: 40),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Recent searches (only when not searching and list is not empty)
                      if (_searchQuery.isEmpty && _recentSearches.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Busquedas recientes',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              GestureDetector(
                                onTap: _clearRecentSearches,
                                child: const Text(
                                  'Limpiar',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 36,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _recentSearches.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final term = _recentSearches[index];
                              return GestureDetector(
                                onTap: () => _onQuickSearch(term),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.card,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.history_rounded, size: 14, color: AppColors.mutedForeground),
                                      const SizedBox(width: 6),
                                      Text(
                                        term,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.foreground,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      GestureDetector(
                                        onTap: () => _removeRecentSearch(term),
                                        behavior: HitTestBehavior.opaque,
                                        child: const Icon(Icons.close_rounded, size: 14, color: AppColors.mutedForeground),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Category filter chips
                      if (_categories.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Filtrar por categoria',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 40,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _categories.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final cat = _categories[index];
                              final isActive = _selectedCategoryId == cat.id.toString();
                              return GestureDetector(
                                onTap: () => _onCategoryTap(cat.id.toString()),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  decoration: BoxDecoration(
                                    color: isActive ? AppColors.primary : AppColors.card,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isActive ? AppColors.primary : AppColors.border,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _iconForCategory(cat.nombre),
                                        size: 16,
                                        color: isActive ? Colors.white : AppColors.mutedForeground,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        cat.nombre,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: isActive ? Colors.white : AppColors.foreground,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Results header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'Resultados para "$_searchQuery"'
                                  : 'Todos los productos',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            Text(
                              '${_products.length} encontrados',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Products Grid
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 60),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_products.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 60),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.search_off_rounded,
                                  size: 48,
                                  color: AppColors.mutedForeground.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'No se encontraron productos',
                                  style: TextStyle(color: AppColors.mutedForeground, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final crossAxisCount = constraints.maxWidth > 500 ? 3 : 2;
                              return GridView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                  childAspectRatio: 0.68,
                                ),
                                itemCount: _products.length,
                                itemBuilder: (context, index) {
                                  final product = _products[index];
                                  return ProductCard(
                                    product: product,
                                    isFavorite: _favoriteIds.contains(product.id),
                                    onToggleFavorite: () => _onToggleFavorite(product.id),
                                  );
                                },
                              );
                            },
                          ),
                        ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
