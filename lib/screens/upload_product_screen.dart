import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../theme/app_theme.dart';

class UploadProductScreen extends StatefulWidget {
  const UploadProductScreen({super.key});

  @override
  State<UploadProductScreen> createState() => _UploadProductScreenState();
}

class _UploadProductScreenState extends State<UploadProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _precioController = TextEditingController();
  final _cantidadController = TextEditingController();

  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  List<Category> _categories = [];
  Category? _selectedCategory;
  bool _isLoading = false;
  bool _loadingCategories = true;

  @override
  void initState() {
    super.initState();
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
      setState(() {
        _categories = data.map((e) => Category.fromJson(e)).toList();
        _loadingCategories = false;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked != null && mounted) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _selectedImage = picked;
        _selectedImageBytes = bytes;
      });
    }
  }

  void _showImageSourceSheet() {
    final colors = context.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Seleccionar imagen',
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: colors.foreground,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _ImageSourceButton(
                      icon: Icons.camera_alt_outlined,
                      label: 'Camara',
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickImage(ImageSource.camera);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ImageSourceButton(
                      icon: Icons.photo_library_outlined,
                      label: 'Galería',
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickImage(ImageSource.gallery);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_selectedImage == null) {
      _showSnack('Selecciona una imagen para el producto', isError: true);
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      _showSnack('Selecciona una categoria', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final result = await ProductService.uploadProduct(
      nombre: _nombreController.text.trim(),
      descripcion: _descripcionController.text.trim(),
      precio: double.parse(_precioController.text.trim()),
      cantidad: int.parse(_cantidadController.text.trim()),
      idCategoria: _selectedCategory!.id,
      imageBytes: _selectedImageBytes!,
      imageName: _selectedImage!.name,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (result != null && result['success'] == true) {
        _showSnack('Producto publicado correctamente');
        Navigator.pop(context, true);
      } else {
        _showSnack('Error al publicar el producto. Intenta de nuevo.', isError: true);
      }
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    final colors = context.colors;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? colors.destructive : colors.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  InputDecoration _inputDecoration(DynamicColors colors, {required String hint, IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: colors.mutedForeground, fontSize: 14),
      prefixIcon: icon != null
          ? Padding(
              padding: const EdgeInsets.only(left: 12, right: 8),
              child: Icon(icon, size: 18, color: colors.mutedForeground),
            )
          : null,
      prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.card,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: colors.foreground,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Publicar producto',
          style: GoogleFonts.dmSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colors.foreground,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: colors.border),
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
              // ── Image Picker ──────────────────────────────
              _SectionLabel(label: 'Foto del producto'),
              GestureDetector(
                onTap: _showImageSourceSheet,
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _selectedImage != null
                          ? colors.primary
                          : colors.border,
                      width: _selectedImage != null ? 2 : 1,
                    ),
                  ),
                  child: _selectedImageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.memory(_selectedImageBytes!, fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: colors.primaryLight,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 28,
                                color: colors.primary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Toca para agregar una foto',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: colors.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'JPG, PNG o WEBP',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: colors.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              if (_selectedImage != null) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _showImageSourceSheet,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.edit_outlined, size: 14, color: colors.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Cambiar foto',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: colors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // ── Product Info ──────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.border),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Información del producto',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 16),
                    _FieldLabel(label: 'Nombre'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _nombreController,
                      style: TextStyle(fontSize: 14, color: colors.foreground),
                      decoration: _inputDecoration(
                        colors,
                        hint: 'Ej: Camiseta azul talla M',
                        icon: Icons.label_outline_rounded,
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Campo requerido' : null,
                    ),
                    const SizedBox(height: 14),
                    _FieldLabel(label: 'Descripción'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _descripcionController,
                      maxLines: 3,
                      style: TextStyle(fontSize: 14, color: colors.foreground),
                      decoration: _inputDecoration(
                        colors,
                        hint: 'Describe tu producto, estado, características...',
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
                  color: colors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.border),
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
                              _FieldLabel(label: 'Precio'),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _precioController,
                                keyboardType: const TextInputType.numberWithOptions(
                                    decimal: true),
                                style: TextStyle(
                                    fontSize: 14, color: colors.foreground),
                                decoration: _inputDecoration(
                                  colors,
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
                              _FieldLabel(label: 'Cantidad'),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _cantidadController,
                                keyboardType: TextInputType.number,
                                style: TextStyle(
                                    fontSize: 14, color: colors.foreground),
                                decoration: _inputDecoration(
                                  colors,
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
                  color: colors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.border),
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
                              color: colors.secondary,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: colors.border),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<Category>(
                                value: _selectedCategory,
                                hint: Row(
                                  children: [
                                    Icon(
                                      Icons.category_outlined,
                                      size: 18,
                                      color: colors.mutedForeground,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Selecciona una categoria',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: colors.mutedForeground,
                                      ),
                                    ),
                                  ],
                                ),
                                isExpanded: true,
                                icon: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: colors.mutedForeground,
                                ),
                                items: _categories.map((cat) {
                                  return DropdownMenuItem<Category>(
                                    value: cat,
                                    child: Text(
                                      cat.nombre,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: colors.foreground,
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
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: colors.primary.withValues(alpha: 0.6),
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
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.upload_rounded, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Publicar producto',
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
}

// ── Helper Widgets ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: colors.foreground,
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
    final colors = context.colors;
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: colors.mutedForeground,
      ),
    );
  }
}

class _ImageSourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ImageSourceButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: colors.primaryLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: colors.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: colors.primary),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
