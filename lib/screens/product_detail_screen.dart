import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Map<String, dynamic>? _detail;
  bool _isLoading = true;
  bool _isFavorite = false;
  bool _addingToCart = false;
  int _userId = 0;
  int _cantidad = 1;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadDetail(),
      _loadUserId(),
    ]);
  }

  Future<void> _loadDetail() async {
    setState(() => _isLoading = true);
    final data = await ProductService.getProductDetail(widget.product.id);
    if (mounted) {
      setState(() {
        _detail = data;
        _isLoading = false;
        if (data != null) {
          _isFavorite = data['is_favorito'] == true || data['is_favorito'] == 1;
        }
      });
    }
  }

  Future<void> _loadUserId() async {
    final user = await AuthService.getSavedUser();
    if (user != null && mounted) {
      setState(() => _userId = user.id);
    }
  }

  Future<void> _toggleFavorite() async {
    if (_userId == 0) return;
    final result = await ProductService.toggleFavorite(
      userId: _userId,
      productId: widget.product.id,
    );
    if (result != null && result['success'] == true && mounted) {
      setState(() {
        _isFavorite = result['is_favorito'] as bool? ?? false;
      });
    }
  }

  Future<void> _addToCart() async {
    if (_userId == 0) {
      _showSnackBar('Inicia sesion para agregar al carrito', isError: true);
      return;
    }
    setState(() => _addingToCart = true);
    final success = await ProductService.addToCart(
      userId: _userId,
      productId: widget.product.id,
      cantidad: _cantidad,
    );
    if (mounted) {
      setState(() => _addingToCart = false);
      if (success) {
        _showSnackBar('Producto agregado al carrito');
      } else {
        _showSnackBar('No se pudo agregar al carrito', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
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
        backgroundColor: isError ? AppColors.destructive : AppColors.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // Use detail data if available, fallback to basic product data
    final nombre = _detail?['nombre'] as String? ?? product.nombre;
    final precio = (_detail?['precio'] is num)
        ? (_detail!['precio'] as num).toDouble()
        : product.precio;
    final imagen = _detail?['imagen'] as String? ?? product.imagen;
    final descripcion = _detail?['descripcion'] as String? ?? '';
    final categoria = _detail?['categoria_nombre'] as String? ?? '';
    final vendedor = _detail?['vendedor_nombre'] as String? ?? '';
    final stock = _detail?['cantidad'];
    final stockNum = stock is int
        ? stock
        : int.tryParse(stock?.toString() ?? '') ?? 0;
    final hasStockInfo = !_isLoading && _detail != null && stock != null;
    final canIncrement = hasStockInfo ? _cantidad < stockNum : true;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Main scrollable content
          Expanded(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Image with app bar overlay
                SliverToBoxAdapter(
                  child: Stack(
                    children: [
                      // Product image
                      Container(
                        width: double.infinity,
                        height: 360,
                        color: AppColors.secondary,
                        child: imagen != null && imagen.isNotEmpty
                            ? Image.network(
                          imagen,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                value: progress.expectedTotalBytes != null
                                    ? progress.cumulativeBytesLoaded /
                                    progress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Icon(
                                Icons.image_outlined,
                                size: 64,
                                color: AppColors.mutedForeground
                                    .withValues(alpha: 0.4),
                              ),
                            );
                          },
                        )
                            : Center(
                          child: Icon(
                            Icons.image_outlined,
                            size: 64,
                            color: AppColors.mutedForeground
                                .withValues(alpha: 0.4),
                          ),
                        ),
                      ),

                      // Top bar buttons
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 8,
                        left: 12,
                        right: 12,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _CircleButton(
                              icon: Icons.arrow_back_rounded,
                              onTap: () => Navigator.of(context).pop(),
                            ),
                            Row(
                              children: [
                                _CircleButton(
                                  icon: _isFavorite
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_outline_rounded,
                                  iconColor: _isFavorite
                                      ? AppColors.destructive
                                      : null,
                                  onTap: _toggleFavorite,
                                ),
                                const SizedBox(width: 8),
                                _CircleButton(
                                  icon: Icons.share_rounded,
                                  onTap: () {},
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Product info
                SliverToBoxAdapter(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    transform: Matrix4.translationValues(0, -20, 0),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category & stock badges
                          if (categoria.isNotEmpty || stockNum > 0)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  if (categoria.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryLight,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        categoria,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  if (categoria.isNotEmpty && stockNum > 0)
                                    const SizedBox(width: 8),
                                  if (stockNum > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.accentLight,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '$stockNum en stock',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.accent,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),

                          // Product name
                          Text(
                            nombre,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.foreground,
                              height: 1.3,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Price
                          Text(
                            _formatPrice(precio),
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Seller info
                          if (vendedor.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryLight,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        vendedor.isNotEmpty
                                            ? vendedor[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          vendedor,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.foreground,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        const Text(
                                          'Vendedor',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.mutedForeground,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.secondary,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Contactar',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Description
                          if (descripcion.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            const Text(
                              'Descripcion',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.foreground,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              descripcion,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.mutedForeground,
                                height: 1.6,
                              ),
                            ),
                          ],

                          // Loading state for detail
                          if (_isLoading) ...[
                            const SizedBox(height: 24),
                            _buildShimmerBlock(),
                            const SizedBox(height: 12),
                            _buildShimmerBlock(width: 200),
                            const SizedBox(height: 12),
                            _buildShimmerBlock(height: 80),
                          ],

                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom action bar
          Container(
            padding: EdgeInsets.fromLTRB(20, 14, 20, 14 + bottomPadding),
            decoration: BoxDecoration(
              color: AppColors.card,
              border: Border(
                top: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: Row(
              children: [
                // Quantity selector
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _QuantityButton(
                        icon: Icons.remove_rounded,
                        onTap: _cantidad > 1
                            ? () => setState(() => _cantidad--)
                            : null,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '$_cantidad',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.foreground,
                          ),
                        ),
                      ),
                      _QuantityButton(
                        icon: Icons.add_rounded,
                        onTap: canIncrement
                            ? () => setState(() => _cantidad++)
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Add to cart button
                Expanded(
                  child: GestureDetector(
                    onTap: _addingToCart ? null : _addToCart,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 48,
                      decoration: BoxDecoration(
                        color: _addingToCart
                            ? AppColors.primary.withValues(alpha: 0.7)
                            : AppColors.primary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: _addingToCart
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.shopping_cart_outlined,
                              size: 18,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Agregar al carrito  ${_formatPrice(precio * _cantidad)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerBlock({double? width, double height = 16}) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.muted,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

/// Circle button used in the image overlay (back, favorite, share).
class _CircleButton extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final VoidCallback onTap;

  const _CircleButton({
    required this.icon,
    this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.card.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 20,
          color: iconColor ?? AppColors.foreground,
        ),
      ),
    );
  }
}

/// Small +/- button for quantity selector.
class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _QuantityButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Icon(
          icon,
          size: 18,
          color: enabled
              ? AppColors.foreground
              : AppColors.mutedForeground.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}
