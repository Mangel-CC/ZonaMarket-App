import 'package:flutter/material.dart';
import '../services/product_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  int _userId = 0;
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;
  bool _isClearing = false;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    setState(() => _isLoading = true);

    final user = await AuthService.getSavedUser();
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    _userId = user.id;
    final data = await ProductService.getCart(_userId);

    if (mounted) {
      setState(() {
        if (data != null && data['items'] is List) {
          _items = (data['items'] as List).cast<Map<String, dynamic>>();
        } else {
          _items = [];
        }
        _isLoading = false;
      });
    }
  }

  double get _subtotal {
    double total = 0;
    for (final item in _items) {
      final precio = _toDouble(item['precio']);
      final cantidad = _toInt(item['cantidad']);
      total += precio * cantidad;
    }
    return total;
  }

  double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 1;
  }

  String _formatPrice(double price) {
    if (price >= 1000) {
      final parts = price.toStringAsFixed(2);
      final split = parts.split('.');
      final intPart = split[0];
      final decPart = split[1];
      final buffer = StringBuffer();
      int count = 0;
      for (int i = intPart.length - 1; i >= 0; i--) {
        buffer.write(intPart[i]);
        count++;
        if (count % 3 == 0 && i != 0) {
          buffer.write(',');
        }
      }
      return '\$${buffer.toString().split('').reversed.join()}.$decPart';
    }
    return '\$${price.toStringAsFixed(2)}';
  }

  Future<void> _removeItem(int itemId) async {
    final success = await ProductService.removeFromCart(
      itemId: itemId,
      userId: _userId,
    );
    if (success) {
      await _loadCart();
      if (mounted) _showSnackBar('Producto eliminado del carrito');
    } else {
      if (mounted) _showSnackBar('No se pudo eliminar', isError: true);
    }
  }

  Future<void> _clearCart() async {
    final colors = context.colors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Vaciar carrito',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colors.foreground,
          ),
        ),
        content: Text(
          'Se eliminaran todos los productos del carrito. Esta acción no se puede deshacer.',
          style: TextStyle(
            fontSize: 14,
            color: colors.mutedForeground,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: colors.mutedForeground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Vaciar',
              style: TextStyle(
                color: colors.destructive,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isClearing = true);
    final success = await ProductService.clearCart(_userId);
    if (mounted) {
      setState(() => _isClearing = false);
      if (success) {
        await _loadCart();
        _showSnackBar('Carrito vaciado');
      } else {
        _showSnackBar('No se pudo vaciar el carrito', isError: true);
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

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          // App bar
          _buildAppBar(context, colors),

          // Content
          Expanded(
            child: _isLoading
                ? _buildLoadingState(colors)
                : _items.isEmpty
                ? _buildEmptyState(colors)
                : RefreshIndicator(
              onRefresh: _loadCart,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  return _buildCartItem(_items[index], colors);
                },
              ),
            ),
          ),

          // Bottom bar with totals
          if (!_isLoading && _items.isNotEmpty)
            _buildBottomBar(bottomPadding, colors),
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
                      'Mi Carrito',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: colors.foreground,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (!_isLoading)
                      Text(
                        '${_items.length} ${_items.length == 1 ? 'producto' : 'productos'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.mutedForeground,
                        ),
                      ),
                  ],
                ),
              ),
              if (_items.isNotEmpty && !_isLoading)
                IconButton(
                  onPressed: _isClearing ? null : _clearCart,
                  icon: _isClearing
                      ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.destructive,
                    ),
                  )
                      : Icon(
                    Icons.delete_outline_rounded,
                    size: 22,
                    color: colors.destructive,
                  ),
                  tooltip: 'Vaciar carrito',
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
        children: List.generate(3, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              height: 110,
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
                          const SizedBox(height: 8),
                          Container(
                            height: 14,
                            width: 80,
                            decoration: BoxDecoration(
                              color: colors.secondary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 14,
                            width: 60,
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
              Icons.shopping_cart_outlined,
              size: 36,
              color: colors.mutedForeground,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Tu carrito esta vacío',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: colors.foreground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega productos para comenzar\na armar tu pedido',
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

  Widget _buildCartItem(Map<String, dynamic> item, DynamicColors colors) {
    final nombre = item['nombre'] as String? ?? 'Producto';
    final imagen = item['imagen'] as String?;
    final precio = _toDouble(item['precio']);
    final cantidad = _toInt(item['cantidad']);
    final itemId = _toInt(item['id']);
    final subtotal = precio * cantidad;

    return Dismissible(
      key: ValueKey(itemId),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _removeItem(itemId),
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
              height: 110,
              color: colors.secondary,
              child: imagen != null && imagen.isNotEmpty
                  ? Image.network(
                imagen,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Center(
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
                    const SizedBox(height: 4),
                    Text(
                      _formatPrice(precio),
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Quantity display
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colors.secondary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'x$cantidad',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: colors.foreground,
                            ),
                          ),
                        ),
                        // Subtotal
                        Text(
                          _formatPrice(subtotal),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: colors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(double bottomPadding, DynamicColors colors) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottomPadding),
      decoration: BoxDecoration(
        color: colors.card,
        border: Border(
          top: BorderSide(color: colors.border, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Summary rows
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal',
                style: TextStyle(
                  fontSize: 14,
                  color: colors.mutedForeground,
                ),
              ),
              Text(
                _formatPrice(_subtotal),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.foreground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Envio',
                style: TextStyle(
                  fontSize: 14,
                  color: colors.mutedForeground,
                ),
              ),
              Text(
                'Gratis',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 1,
            color: colors.border,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: colors.foreground,
                ),
              ),
              Text(
                _formatPrice(_subtotal),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: colors.primary,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Checkout button
          GestureDetector(
            onTap: () {
              _showSnackBar('Procesando pedido...');
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_rounded,
                    size: 18,
                    color: colors.primaryForeground,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Proceder al pago',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colors.primaryForeground,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
