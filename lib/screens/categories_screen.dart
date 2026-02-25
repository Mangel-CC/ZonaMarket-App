import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/product_card.dart';
import 'login_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<Category> _categories = [];
  List<Product> _products = [];
  bool _loadingCategories = true;
  bool _loadingProducts = false;
  String? _selectedCategoryId;
  String _selectedCategoryName = '';
  Set<int> _favoriteIds = {};
  int _userId = 0;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadCategories(),
      _loadFavorites(),
      _loadUserId(),
    ]);
  }

  Future<void> _loadUserId() async {
    final user = await AuthService.getSavedUser();
    if (user != null && mounted) {
      setState(() => _userId = user.id);
    }
  }

  Future<void> _loadCategories() async {
    final data = await ProductService.getCategories();
    if (mounted) {
      setState(() {
        _categories = data.map((e) => Category.fromJson(e)).toList();
        _loadingCategories = false;
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

  Future<void> _selectCategory(Category cat) async {
    setState(() {
      _selectedCategoryId = cat.id.toString();
      _selectedCategoryName = cat.nombre;
      _loadingProducts = true;
    });

    final data = await ProductService.getProducts(categoryId: cat.id.toString());
    if (mounted) {
      setState(() {
        _products = data.map((e) => Product.fromJson(e)).toList();
        _loadingProducts = false;
      });
    }
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
          _favoriteIds.add(productId);
        } else {
          _favoriteIds.remove(productId);
        }
      });
    }
  }

  void _goBack() {
    setState(() {
      _selectedCategoryId = null;
      _selectedCategoryName = '';
      _products = [];
    });
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

  Color _colorForIndex(int index) {
    final colors = [
      AppColors.primary,
      AppColors.accent,
      AppColors.chartOrange,
      AppColors.chartBlue,
      AppColors.destructive,
      const Color(0xFF8B5CF6),
    ];
    return colors[index % colors.length];
  }

  Color _bgColorForIndex(int index) {
    final colors = [
      AppColors.primaryLight,
      AppColors.accentLight,
      const Color(0xFFFFF3E8),
      const Color(0xFFE8F2FB),
      const Color(0xFFFDE8E8),
      const Color(0xFFF0E8FF),
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _selectedCategoryId != null
                  ? Row(
                children: [
                  GestureDetector(
                    onTap: _goBack,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.border),
                      ),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        size: 20,
                        color: colors.foreground,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedCategoryName,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20),
                        ),
                        Text(
                          '${_products.length} productos',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Categorías',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontSize: 26,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Explora por tipo de producto',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Content
            Expanded(
              child: _selectedCategoryId != null
                  ? _buildProductsList(colors)
                  : _buildCategoriesGrid(colors),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesGrid(DynamicColors colors) {
    if (_loadingCategories) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.category_outlined, size: 48, color: colors.mutedForeground.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(
              'No hay categorías disponibles',
              style: TextStyle(color: colors.mutedForeground, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        physics: const BouncingScrollPhysics(),
        itemCount: _categories.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final color = _colorForIndex(index);
          final bgColor = _bgColorForIndex(index);

          return GestureDetector(
            onTap: () => _selectCategory(cat),
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.border),
              ),
              child: Stack(
                children: [
                  // Decorative circle
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: bgColor,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            _iconForCategory(cat.nombre),
                            size: 24,
                            color: color,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                cat.nombre,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: colors.foreground,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Ver productos',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.mutedForeground,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios_rounded, size: 16, color: color),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductsList(DynamicColors colors) {
    if (_loadingProducts) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, size: 48, color: colors.mutedForeground.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(
              'No hay productos en esta categoria',
              style: TextStyle(color: colors.mutedForeground, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        physics: const BouncingScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
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
      ),
    );
  }
}
