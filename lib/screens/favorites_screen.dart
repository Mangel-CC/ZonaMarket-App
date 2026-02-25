import 'package:flutter/material.dart';
import '../services/product_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../models/product.dart';
import 'product_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Map<String, dynamic>> _favorites = [];
  bool _isLoading = true;
  int _userId = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final user = await AuthService.getSavedUser();
    if (user != null) {
      _userId = user.id;
    }

    final data = await ProductService.getFavorites();
    if (mounted) {
      setState(() {
        _favorites = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _removeFavorite(int productId, int index) async {
    if (_userId == 0) return;

    // Optimistic removal
    final removed = _favorites[index];
    setState(() => _favorites.removeAt(index));

    final result = await ProductService.toggleFavorite(
      userId: _userId,
      productId: productId,
    );

    if (result == null || result['success'] != true) {
      // Revert on failure
      if (mounted) {
        setState(() => _favorites.insert(index, removed));
        _showSnackBar('No se pudo eliminar de favoritos', isError: true);
      }
    } else {
      if (mounted) {
        _showSnackBar('Eliminado de favoritos');
      }
    }
  }

  void _openProduct(Map<String, dynamic> fav) {
    final product = Product(
      id: _toInt(fav['product_id']),
      nombre: fav['nombre'] as String? ?? '',
      precio: _toDouble(fav['precio']),
      imagen: fav['imagen'] as String?,
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(product: product),
      ),
    );
  }

  double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _formatPrice(double price) {
    if (price >= 1000) {
      final parts = price.toStringAsFixed(0);
      final buffer = StringBuffer();
      int count = 0;
      for (int i = parts.length - 1; i >= 0; i--) {
        buffer.write(parts[i]);
        count++;
        if (count % 3 == 0 && i != 0) {
          buffer.write(',');
        }
      }
      return '\$${buffer.toString().split('').reversed.join()}';
    }
    return '\$${price.toStringAsFixed(0)}';
  }

  void _showSnackBar(String message, {bool isError = false}) {
    final colors = context.colors;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: isError ? colors.destructive : colors.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          _buildAppBar(context, colors),
          Expanded(
            child: _isLoading
                ? _buildLoadingState(colors)
                : _favorites.isEmpty
                ? _buildEmptyState(colors)
                : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: _favorites.length,
                itemBuilder: (context, index) {
                  return _buildFavoriteItem(_favorites[index], index, colors);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, DynamicColors colors) {
    return Container(
      color: colors.card,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(
                  Icons.arrow_back_rounded,
                  size: 22,
                  color: colors.foreground,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Mis Favoritos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: colors.foreground,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (!_isLoading)
                      Text(
                        '${_favorites.length} ${_favorites.length == 1 ? 'producto' : 'productos'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.mutedForeground,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(DynamicColors colors) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(4, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 100,
                    decoration: BoxDecoration(
                      color: colors.secondary,
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(14),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            height: 14,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: colors.secondary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            height: 14,
                            width: 80,
                            decoration: BoxDecoration(
                              color: colors.secondary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildEmptyState(DynamicColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colors.secondary,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.favorite_outline_rounded,
              size: 36,
              color: colors.mutedForeground,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Sin favoritos aun',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: colors.foreground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Toca el corazon en los productos\nque te gusten para guardarlos aquí',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: colors.mutedForeground,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Explorar productos',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.primaryForeground,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteItem(Map<String, dynamic> fav, int index, DynamicColors colors) {
    final nombre = fav['nombre'] as String? ?? 'Producto';
    final imagen = fav['imagen'] as String?;
    final precio = _toDouble(fav['precio']);
    final productId = _toInt(fav['product_id']);
    final stock = _toInt(fav['stock']);

    return Dismissible(
      key: ValueKey('fav-$productId'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _removeFavorite(productId, index),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: colors.destructive,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
      child: GestureDetector(
        onTap: () => _openProduct(fav),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              // Image
              Container(
                width: 100,
                height: 100,
                color: colors.secondary,
                child: imagen != null && imagen.isNotEmpty
                    ? Image.network(
                  imagen,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Center(
                    child: Icon(
                      Icons.image_outlined,
                      size: 28,
                      color: colors.mutedForeground,
                    ),
                  ),
                )
                    : Center(
                  child: Icon(
                    Icons.image_outlined,
                    size: 28,
                    color: colors.mutedForeground,
                  ),
                ),
              ),

              // Info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colors.foreground,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatPrice(precio),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (stock > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: colors.accentLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$stock en stock',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: colors.accent,
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: colors.destructive.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Sin stock',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: colors.destructive,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Remove button
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  onPressed: () => _removeFavorite(productId, index),
                  icon: Icon(
                    Icons.favorite_rounded,
                    size: 22,
                    color: colors.destructive,
                  ),
                  splashRadius: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
