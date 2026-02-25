import 'package:flutter/material.dart';
import '../services/product_service.dart';
import '../theme/app_theme.dart';
import 'edit_product_screen.dart';
import 'upload_product_screen.dart';

class MyProductsScreen extends StatefulWidget {
  const MyProductsScreen({super.key});

  @override
  State<MyProductsScreen> createState() => _MyProductsScreenState();
}

class _MyProductsScreenState extends State<MyProductsScreen> {
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    final data = await ProductService.getMyProducts();
    if (mounted) {
      setState(() {
        _products = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteProduct(int productId, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar producto'),
        content: const Text('Estas seguro de que deseas eliminar este producto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: AppColors.destructive)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final removed = _products[index];
    setState(() => _products.removeAt(index));

    final success = await ProductService.deleteMyProduct(productId);
    if (!success && mounted) {
      setState(() => _products.insert(index, removed));
      _showSnackBar('No se pudo eliminar el producto', isError: true);
    } else if (mounted) {
      _showSnackBar('Producto eliminado');
    }
  }

  void _openProduct(Map<String, dynamic> data) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditProductScreen(productData: data),
      ),
    );
    if (updated == true) _loadProducts();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildAppBar(context),
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _products.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadProducts,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          itemCount: _products.length,
                          itemBuilder: (context, index) {
                            return _buildProductItem(_products[index], index);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      color: AppColors.card,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  size: 22,
                  color: AppColors.foreground,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Mis Productos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.foreground,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (!_isLoading)
                      Text(
                        '${_products.length} ${_products.length == 1 ? 'producto' : 'productos'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () async {
                  final uploaded = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const UploadProductScreen(),
                    ),
                  );
                  if (uploaded == true) _loadProducts();
                },
                icon: const Icon(
                  Icons.add_rounded,
                  size: 24,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(4, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 100,
                    decoration: const BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.horizontal(
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
                              color: AppColors.secondary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            height: 14,
                            width: 80,
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.shopping_bag_outlined,
              size: 36,
              color: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Sin productos aun',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Publica tu primer producto\ny comienza a vender',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.mutedForeground,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () async {
              final uploaded = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => const UploadProductScreen(),
                ),
              );
              if (uploaded == true) _loadProducts();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Publicar producto',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryForeground,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductItem(Map<String, dynamic> data, int index) {
    final nombre = data['nombre'] as String? ?? 'Producto';
    final imagen = data['imagen'] as String?;
    final precio = _toDouble(data['precio']);
    final productId = _toInt(data['id']);
    final cantidad = _toInt(data['cantidad']);

    return GestureDetector(
      onTap: () => _openProduct(data),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            Container(
              width: 100,
              height: 100,
              color: AppColors.secondary,
              child: imagen != null && imagen.isNotEmpty
                  ? Image.network(
                      imagen,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(
                          Icons.image_outlined,
                          size: 28,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    )
                  : const Center(
                      child: Icon(
                        Icons.image_outlined,
                        size: 28,
                        color: AppColors.mutedForeground,
                      ),
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.foreground,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatPrice(precio),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: cantidad > 0
                            ? AppColors.accentLight
                            : AppColors.destructive.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        cantidad > 0 ? '$cantidad en stock' : 'Sin stock',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: cantidad > 0
                              ? AppColors.accent
                              : AppColors.destructive,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () => _openProduct(data),
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  splashRadius: 18,
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(height: 4),
                IconButton(
                  onPressed: () => _deleteProduct(productId, index),
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: AppColors.destructive,
                  ),
                  splashRadius: 18,
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}
