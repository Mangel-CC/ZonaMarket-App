import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

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
  List<Map<String, dynamic>> _reviews = [];
  bool _reviewsLoading = false;
  double _avgRating = 0;
  int _totalReviews = 0;
  Map<String, int> _ratingDistribution = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadDetail(),
      _loadUserId(),
      _loadReviews(),
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

  Future<void> _loadReviews() async {
    setState(() => _reviewsLoading = true);
    final reviews = await ProductService.getProductReviews(widget.product.id);
    if (mounted) {
      setState(() {
        _reviewsLoading = false;
        _reviews = reviews;
        _totalReviews = reviews.length;
        _avgRating = _computeAvg(reviews);
        _ratingDistribution = _computeDistribution(reviews);
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
    if (_userId == 0) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }
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
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
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
    final colors = context.colors;
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
      backgroundColor: colors.background,
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
                        color: colors.secondary,
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
                                color: colors.mutedForeground
                                    .withValues(alpha: 0.4),
                              ),
                            );
                          },
                        )
                            : Center(
                          child: Icon(
                            Icons.image_outlined,
                            size: 64,
                            color: colors.mutedForeground
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
                                      ? colors.destructive
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
                    decoration: BoxDecoration(
                      color: colors.background,
                      borderRadius: const BorderRadius.vertical(
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
                                        color: colors.primaryLight,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        categoria,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: colors.primary,
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
                                        color: colors.accentLight,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '$stockNum en stock',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: colors.accent,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),

                          // Product name
                          Text(
                            nombre,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: colors.foreground,
                              height: 1.3,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Price
                          Text(
                            _formatPrice(precio),
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: colors.primary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Seller info
                          if (vendedor.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: colors.card,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: colors.border),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: colors.primaryLight,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        vendedor.isNotEmpty
                                            ? vendedor[0].toUpperCase()
                                            : '?',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: colors.primary,
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
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: colors.foreground,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Vendedor',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: colors.mutedForeground,
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
                                      color: colors.secondary,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Contactar',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: colors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Description
                          if (descripcion.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            Text(
                              'Descripción',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: colors.foreground,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              descripcion,
                              style: TextStyle(
                                fontSize: 14,
                                color: colors.mutedForeground,
                                height: 1.6,
                              ),
                            ),
                          ],

                          // Reviews section
                          const SizedBox(height: 24),
                          _buildReviewsSection(colors),

                          // Loading state for detail
                          if (_isLoading) ...[
                            const SizedBox(height: 24),
                            _buildShimmerBlock(colors),
                            const SizedBox(height: 12),
                            _buildShimmerBlock(colors, width: 200),
                            const SizedBox(height: 12),
                            _buildShimmerBlock(colors, height: 80),
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
              color: colors.card,
              border: Border(
                top: BorderSide(color: colors.border, width: 1),
              ),
            ),
            child: Row(
              children: [
                // Quantity selector
                Container(
                  decoration: BoxDecoration(
                    color: colors.secondary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.border),
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
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: colors.foreground,
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
                            ? colors.primary.withValues(alpha: 0.7)
                            : colors.primary,
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

  // ── Reviews helpers ─────────────────────────────────────────────────────

  double _computeAvg(List<Map<String, dynamic>> reviews) {
    if (reviews.isEmpty) return 0;
    final sum = reviews.fold<double>(
      0,
      (acc, r) => acc + ((r['calificacion'] as num?)?.toDouble() ?? 0),
    );
    return sum / reviews.length;
  }

  Map<String, int> _computeDistribution(List<Map<String, dynamic>> reviews) {
    final dist = <String, int>{'5': 0, '4': 0, '3': 0, '2': 0, '1': 0};
    for (final r in reviews) {
      final cal = (r['calificacion'] as num?)?.toInt() ?? 0;
      final key = cal.clamp(1, 5).toString();
      dist[key] = (dist[key] ?? 0) + 1;
    }
    return dist;
  }

  String _formatReviewDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(date);
      if (diff.inDays == 0) return 'Hoy';
      if (diff.inDays == 1) return 'Ayer';
      if (diff.inDays < 7) return 'Hace ${diff.inDays} días';
      if (diff.inDays < 30) return 'Hace ${(diff.inDays / 7).floor()} sem';
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  Widget _buildStars(double rating, {double size = 16}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = rating >= i + 1;
        final half = !filled && rating >= i + 0.5;
        return Icon(
          filled
              ? Icons.star_rounded
              : half
                  ? Icons.star_half_rounded
                  : Icons.star_outline_rounded,
          size: size,
          color: const Color(0xFFFFC107),
        );
      }),
    );
  }

  Widget _buildRatingBar(int star, DynamicColors colors) {
    final count = _ratingDistribution[star.toString()] ?? 0;
    final pct = _totalReviews > 0 ? count / _totalReviews : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        children: [
          Text(
            '$star',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colors.mutedForeground,
            ),
          ),
          const SizedBox(width: 3),
          Icon(Icons.star_rounded, size: 11, color: const Color(0xFFFFC107)),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 6,
                backgroundColor: colors.muted,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Color(0xFFFFC107)),
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 22,
            child: Text(
              '$count',
              style: TextStyle(fontSize: 11, color: colors.mutedForeground),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review, DynamicColors colors) {
    final nombre = review['autor'] as String? ?? 'Usuario';
    final calificacion = (review['calificacion'] as num?)?.toDouble() ?? 0;
    final comentario = review['comentario'] as String? ?? '';
    final fecha = review['fecha'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.foreground,
                      ),
                    ),
                    const SizedBox(height: 3),
                    _buildStars(calificacion, size: 13),
                  ],
                ),
              ),
              if (fecha.isNotEmpty)
                Text(
                  _formatReviewDate(fecha),
                  style:
                      TextStyle(fontSize: 11, color: colors.mutedForeground),
                ),
            ],
          ),
          if (comentario.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              comentario,
              style: TextStyle(
                fontSize: 13,
                color: colors.mutedForeground,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewsSection(DynamicColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Reseñas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colors.foreground,
              ),
            ),
            if (!_reviewsLoading && _totalReviews > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.muted,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$_totalReviews',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.mutedForeground,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        if (_reviewsLoading) ...[
          _buildShimmerBlock(colors, height: 110),
          const SizedBox(height: 10),
          _buildShimmerBlock(colors, height: 80),
        ] else if (_reviews.isEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.rate_review_outlined,
                  size: 36,
                  color: colors.mutedForeground.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sin reseñas aún',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.mutedForeground,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sé el primero en reseñar este producto',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.mutedForeground.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ] else ...[
          // Summary card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Text(
                      _avgRating.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                        color: colors.foreground,
                        letterSpacing: -1,
                      ),
                    ),
                    _buildStars(_avgRating),
                    const SizedBox(height: 4),
                    Text(
                      '$_totalReviews reseña${_totalReviews != 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Container(width: 1, height: 80, color: colors.border),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [5, 4, 3, 2, 1]
                        .map((s) => _buildRatingBar(s, colors))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Review cards
          ..._reviews.map((r) => _buildReviewCard(r, colors)),
        ],
      ],
    );
  }

  Widget _buildShimmerBlock(DynamicColors colors, {double? width, double height = 16}) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: colors.muted,
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
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colors.card.withValues(alpha: 0.9),
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
          color: iconColor ?? colors.foreground,
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
    final colors = context.colors;
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Icon(
          icon,
          size: 18,
          color: enabled
              ? colors.foreground
              : colors.mutedForeground.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}
