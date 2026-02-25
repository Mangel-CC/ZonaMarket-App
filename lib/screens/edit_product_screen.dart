import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../theme/app_theme.dart';

class EditProductScreen extends StatefulWidget {
  final Map<String, dynamic> productData;

  const EditProductScreen({super.key, required this.productData});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _precioController = TextEditingController();
  final _cantidadController = TextEditingController();

  List<Category> _categories = [];
  Category? _selectedCategory;
  bool _isLoading = false;
  bool _loadingCategories = true;

  @override
  void initState() {
    super.initState();
    _nombreController.text = widget.productData['nombre'] as String? ?? '';
    _descripcionController.text = widget.productData['descripcion'] as String? ?? '';
    final precio = widget.productData['precio'];
    _precioController.text = precio != null ? double.parse(precio.toString()).toStringAsFixed(2) : '';
    final cantidad = widget.productData['cantidad'];
    _cantidadController.text = cantidad != null ? int.parse(cantidad.toString()).toString() : '';
    _loadCategories();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _precioController.dispose();
    _cantidadController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final data = await ProductService.getCategories();
    if (mounted) {
      final cats = data.map((e) => Category.fromJson(e)).toList();
      final currentCatId = widget.productData['id_categoria'];
      Category? selected;
      if (currentCatId != null) {
        final catIdInt = int.tryParse(currentCatId.toString());
        for (final cat in cats) {
          if (cat.id == catIdInt) {
            selected = cat;
            break;
          }
        }
      }
      setState(() {
        _categories = cats;
        _selectedCategory = selected;
        _loadingCategories = false;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      _showSnack('Selecciona una categoria', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final productId = int.parse(widget.productData['id'].toString());
    final result = await ProductService.updateProduct(
      productId: productId,
      nombre: _nombreController.text.trim(),
      descripcion: _descripcionController.text.trim(),
      precio: double.parse(_precioController.text.trim()),
      cantidad: int.parse(_cantidadController.text.trim()),
      idCategoria: _selectedCategory!.id,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (result != null && result['success'] == true) {
        _showSnack('Producto actualizado correctamente');
        Navigator.pop(context, true);
      } else {
        _showSnack('Error al actualizar el producto', isError: true);
      }
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.destructive : AppColors.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imagen = widget.productData['imagen'] as String?;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppColors.foreground,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Editar producto',
          style: GoogleFonts.dmSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.foreground,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Current Image ──────────────────────────────
              if (imagen != null && imagen.isNotEmpty) ...[
                const _SectionLabel(label: 'Foto actual'),
                Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.network(
                      imagen,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.image_outlined, size: 48, color: AppColors.mutedForeground),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // ── Product Info ──────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informacion del producto',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 16),
                    const _FieldLabel(label: 'Nombre'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _nombreController,
                      style: const TextStyle(fontSize: 14, color: AppColors.foreground),
                      decoration: _inputDecoration(
                        hint: 'Ej: Camiseta azul talla M',
                        icon: Icons.label_outline_rounded,
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Campo requerido' : null,
                    ),
                    const SizedBox(height: 14),
                    const _FieldLabel(label: 'Descripcion'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _descripcionController,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 14, color: AppColors.foreground),
                      decoration: _inputDecoration(
                        hint: 'Describe tu producto, estado, caracteristicas...',
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Campo requerido' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Precio & Cantidad ─────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Precio y stock',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _FieldLabel(label: 'Precio'),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _precioController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: const TextStyle(fontSize: 14, color: AppColors.foreground),
                                decoration: _inputDecoration(
                                  hint: '0.00',
                                  icon: Icons.attach_money_rounded,
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Requerido';
                                  final n = double.tryParse(v.trim());
                                  if (n == null) return 'Invalido';
                                  if (n <= 0) return 'Debe ser mayor a 0';
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _FieldLabel(label: 'Cantidad'),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _cantidadController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(fontSize: 14, color: AppColors.foreground),
                                decoration: _inputDecoration(
                                  hint: '1',
                                  icon: Icons.inventory_2_outlined,
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Requerido';
                                  final n = int.tryParse(v.trim());
                                  if (n == null) return 'Invalido';
                                  if (n < 1) return 'Minimo 1';
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Categoria ─────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Categoria',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 12),
                    _loadingCategories
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<Category>(
                                value: _selectedCategory,
                                hint: Row(
                                  children: [
                                    const Icon(
                                      Icons.category_outlined,
                                      size: 18,
                                      color: AppColors.mutedForeground,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Selecciona una categoria',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: AppColors.mutedForeground,
                                      ),
                                    ),
                                  ],
                                ),
                                isExpanded: true,
                                icon: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: AppColors.mutedForeground,
                                ),
                                items: _categories.map((cat) {
                                  return DropdownMenuItem<Category>(
                                    value: cat,
                                    child: Text(
                                      cat.nombre,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: AppColors.foreground,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) =>
                                    setState(() => _selectedCategory = val),
                              ),
                            ),
                          ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Submit ────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.save_rounded, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Guardar cambios',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint, IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.mutedForeground, fontSize: 14),
      prefixIcon: icon != null
          ? Padding(
              padding: const EdgeInsets.only(left: 12, right: 8),
              child: Icon(icon, size: 18, color: AppColors.mutedForeground),
            )
          : null,
      prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.foreground,
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.mutedForeground,
      ),
    );
  }
}
