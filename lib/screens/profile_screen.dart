import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/product_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import 'login_screen.dart';
import 'upload_product_screen.dart';
import 'my_products_screen.dart';
import 'favorites_screen.dart';
import 'notifications_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;

  final _nombreController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Stats
  int _ordersCount = 0;
  int _favoritesCount = 0;
  int _myProductsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidosController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _fetchProfile(),
      _fetchStats(),
    ]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchProfile() async {
    final data = await ProductService.getProfile();
    if (data != null && mounted) {
      setState(() {
        _profile = data;
        _nombreController.text = data['nombre'] ?? '';
        _apellidosController.text = data['apellidos'] ?? '';
        _emailController.text = data['email'] ?? '';
      });
    }
  }

  Future<void> _fetchStats() async {
    final orders = await ProductService.getOrders();
    final favorites = await ProductService.getFavorites();
    final myProducts = await ProductService.getMyProducts();
    if (mounted) {
      setState(() {
        _ordersCount = orders.length;
        _favoritesCount = favorites.length;
        _myProductsCount = myProducts.length;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_passwordController.text.isEmpty) {
      final colors = context.colors;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Ingresa tu contraseña para guardar cambios'),
          backgroundColor: colors.destructive,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final result = await ProductService.updateProfile(
      nombre: _nombreController.text.trim(),
      apellidos: _apellidosController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (mounted) {
      final colors = context.colors;
      setState(() {
        _isSaving = false;
        _isEditing = false;
        _passwordController.clear();
      });

      if (result != null && result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Perfil actualizado correctamente'),
            backgroundColor: colors.accent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        _fetchProfile();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error al actualizar el perfil'),
            backgroundColor: colors.destructive,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cerrar sesión'),
        content: const Text('Estas seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Cerrar sesión', style: TextStyle(color: context.colors.destructive)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await AuthService.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (_isLoading) {
      return Scaffold(
        backgroundColor: colors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final nombre = _profile?['nombre'] ?? '';
    final apellidos = _profile?['apellidos'] ?? '';
    final fullName = '$nombre $apellidos'.trim();
    final initials = '${nombre.isNotEmpty ? nombre[0] : ''}${apellidos.isNotEmpty ? apellidos[0] : ''}'.toUpperCase();
    final email = _profile?['email'] ?? '';

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 16),

              // Profile Header Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      // Avatar
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            initials.isNotEmpty ? initials : '?',
                            style: GoogleFonts.dmSans(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        fullName.isNotEmpty ? fullName : 'Usuario',
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Stats Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _StatItem(value: '$_ordersCount', label: 'Pedidos'),
                          Container(
                            width: 1,
                            height: 32,
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                          _StatItem(value: '$_favoritesCount', label: 'Favoritos'),
                          Container(
                            width: 1,
                            height: 32,
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                          _StatItem(value: '$_myProductsCount', label: 'Productos'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Edit Profile Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.border),
                  ),
                  child: Column(
                    children: [
                      // Section Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Información personal',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            GestureDetector(
                              onTap: () => setState(() => _isEditing = !_isEditing),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _isEditing ? colors.primaryLight : colors.secondary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _isEditing ? 'Cancelar' : 'Editar',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _isEditing ? colors.primary : colors.foreground,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Fields
                      _ProfileField(
                        label: 'Nombre',
                        controller: _nombreController,
                        icon: Icons.person_outline_rounded,
                        enabled: _isEditing,
                      ),
                      _ProfileField(
                        label: 'Apellidos',
                        controller: _apellidosController,
                        icon: Icons.person_outline_rounded,
                        enabled: _isEditing,
                      ),
                      _ProfileField(
                        label: 'Correo electrónico',
                        controller: _emailController,
                        icon: Icons.mail_outline_rounded,
                        enabled: _isEditing,
                        keyboardType: TextInputType.emailAddress,
                      ),

                      if (_isEditing) ...[
                        _ProfileField(
                          label: 'Contraseña actual',
                          controller: _passwordController,
                          icon: Icons.lock_outline_rounded,
                          enabled: true,
                          obscure: true,
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _saveProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                                  : const Text(
                                'Guardar cambios',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ),
                      ] else
                        const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Menu Items
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.border),
                  ),
                  child: Column(
                    children: [
                      _MenuItem(
                        icon: Icons.shopping_bag_outlined,
                        label: 'Mis productos',
                        subtitle: '$_myProductsCount productos publicados',
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MyProductsScreen(),
                            ),
                          );
                          _fetchStats();
                        },
                      ),
                      Divider(height: 1, indent: 56, color: colors.border),
                      _MenuItem(
                        icon: Icons.add_box_outlined,
                        label: 'Subir producto',
                        subtitle: 'Publica un nuevo articulo',
                        onTap: () async {
                          final uploaded = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const UploadProductScreen(),
                            ),
                          );
                          if (uploaded == true) _fetchStats();
                        },
                      ),
                      Divider(height: 1, indent: 56, color: colors.border),
                      _MenuItem(
                        icon: Icons.favorite_outline_rounded,
                        label: 'Mis favoritos',
                        subtitle: '$_favoritesCount productos guardados',
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const FavoritesScreen(),
                            ),
                          );
                          _fetchStats();
                        },
                      ),
                      Divider(height: 1, indent: 56, color: colors.border),
                      _MenuItem(
                        icon: Icons.notifications_outlined,
                        label: 'Notificaciones',
                        subtitle: 'Gestiona tus alertas',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NotificationsScreen(),
                            ),
                          );
                        },
                      ),
                      Divider(height: 1, indent: 56, color: colors.border),
                      _MenuItem(
                        icon: Icons.chat_outlined,
                        label: 'Mis chats',
                        subtitle: 'Conversaciones activas',
                        onTap: () {
                          final c = context.colors;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Chats disponible próximamente'),
                              backgroundColor: c.primary,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              margin: const EdgeInsets.all(16),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Apariencia
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.border),
                  ),
                  child: ListenableBuilder(
                    listenable: ThemeProvider.instance,
                    builder: (ctx, _) {
                      final provider = ThemeProvider.instance;
                      final isDark = provider.isDark ||
                          (provider.isSystem &&
                              MediaQuery.platformBrightnessOf(ctx) ==
                                  Brightness.dark);
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: colors.secondary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                isDark
                                    ? Icons.dark_mode_rounded
                                    : Icons.light_mode_rounded,
                                size: 18,
                                color: colors.foreground,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Modo oscuro',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: colors.foreground,
                                    ),
                                  ),
                                  Text(
                                    isDark ? 'Activado' : 'Desactivado',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: colors.mutedForeground),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: isDark,
                              onChanged: (_) =>
                                  ThemeProvider.instance.toggleTheme(),
                              activeThumbColor: colors.primary,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Logout
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GestureDetector(
                  onTap: _handleLogout,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: colors.destructive.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colors.destructive.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout_rounded, size: 18, color: colors.destructive),
                        const SizedBox(width: 8),
                        Text(
                          'Cerrar sesión',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colors.destructive,
                          ),
                        ),
                      ],
                    ),
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

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.dmSans(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _ProfileField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final bool enabled;
  final bool obscure;
  final TextInputType? keyboardType;

  const _ProfileField({
    required this.label,
    required this.controller,
    required this.icon,
    required this.enabled,
    this.obscure = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.mutedForeground,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: enabled ? colors.card : colors.secondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.border),
            ),
            child: TextField(
              controller: controller,
              enabled: enabled,
              obscureText: obscure,
              keyboardType: keyboardType,
              style: TextStyle(
                fontSize: 14,
                color: enabled ? colors.foreground : colors.mutedForeground,
              ),
              decoration: InputDecoration(
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 12, right: 8),
                  child: Icon(icon, size: 18, color: colors.mutedForeground),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colors.secondary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: colors.foreground),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.foreground,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: colors.mutedForeground),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: colors.mutedForeground),
          ],
        ),
      ),
    );
  }
}
