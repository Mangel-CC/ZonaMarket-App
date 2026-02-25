  import 'package:flutter/material.dart';
  import 'package:google_fonts/google_fonts.dart';
  import '../theme/app_theme.dart';
  import '../services/auth_service.dart';
  import 'login_screen.dart';

  class RegisterScreen extends StatefulWidget {
    const RegisterScreen({super.key});

    @override
    State<RegisterScreen> createState() => _RegisterScreenState();
  }

  class _RegisterScreenState extends State<RegisterScreen> {
    bool _obscurePassword = true;
    bool _obscureConfirm = true;
    bool _isLoading = false;
    bool _acceptTerms = false;
    String? _errorMessage;

    final _nameController = TextEditingController();
    final _lastnameController = TextEditingController();
    final _emailController = TextEditingController();
    final _passwordController = TextEditingController();
    final _confirmPasswordController = TextEditingController();

    @override
    void dispose() {
      _nameController.dispose();
      _lastnameController.dispose();
      _emailController.dispose();
      _passwordController.dispose();
      _confirmPasswordController.dispose();
      super.dispose();
    }

    Future<void> _handleRegister() async {
      setState(() => _errorMessage = null);

      final name = _nameController.text.trim();
      final lastname = _lastnameController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final confirmPassword = _confirmPasswordController.text;

      if (name.isEmpty || lastname.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
        setState(() => _errorMessage = 'Todos los campos son obligatorios');
        return;
      }

      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
        setState(() => _errorMessage = 'Ingresa un correo valido');
        return;
      }

      if (password.length < 6) {
        setState(() => _errorMessage = 'La contraseña debe tener al menos 6 caracteres');
        return;
      }

      if (password != confirmPassword) {
        setState(() => _errorMessage = 'Las contraseñas no coinciden');
        return;
      }

      if (!_acceptTerms) {
        setState(() => _errorMessage = 'Debes aceptar los términos y condiciones');
        return;
      }

      setState(() => _isLoading = true);

      final result = await AuthService.register(
        name: name,
        lastname: lastname,
        email: email,
        password: password,
      );

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (result.success) {
        final colors = context.colors;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cuenta creada exitosamente. Inicia sesión.',
              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
            ),
            backgroundColor: colors.accent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      } else {
        setState(() => _errorMessage = result.error ?? 'Error desconocido');
      }
    }

    @override
    Widget build(BuildContext context) {
      final colors = context.colors;
      return Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 36),

                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
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

                  const SizedBox(height: 24),

                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: colors.primary,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: colors.primary.withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'JM',
                              style: GoogleFonts.dmSans(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -1,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Crear cuenta',
                          style: GoogleFonts.dmSans(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: colors.foreground,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Unete a ZonaMarket y empieza a explorar',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: colors.mutedForeground,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  if (_errorMessage != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: colors.destructive.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.destructive.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline_rounded, size: 18, color: colors.destructive),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: colors.destructive,
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _errorMessage = null),
                            child: Icon(Icons.close_rounded, size: 16, color: colors.destructive.withValues(alpha: 0.6)),
                          ),
                        ],
                      ),
                    ),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel(colors, 'Nombre'),
                            const SizedBox(height: 8),
                            _buildTextField(colors: colors, controller: _nameController, hint: 'Juan', icon: Icons.person_outline_rounded),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel(colors, 'Apellido'),
                            const SizedBox(height: 8),
                            _buildTextField(colors: colors, controller: _lastnameController, hint: 'Perez', icon: Icons.person_outline_rounded),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  _buildLabel(colors, 'Correo electrónico'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    colors: colors,
                    controller: _emailController,
                    hint: 'tu@correo.com',
                    icon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 18),

                  _buildLabel(colors, 'Contraseña'),
                  const SizedBox(height: 8),
                  _buildPasswordField(
                    colors: colors,
                    controller: _passwordController,
                    hint: 'Minimo 6 caracteres',
                    obscure: _obscurePassword,
                    onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),

                  const SizedBox(height: 18),

                  _buildLabel(colors, 'Confirmar contraseña'),
                  const SizedBox(height: 8),
                  _buildPasswordField(
                    colors: colors,
                    controller: _confirmPasswordController,
                    hint: 'Repite tu contraseña',
                    obscure: _obscureConfirm,
                    onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),

                  const SizedBox(height: 20),

                  GestureDetector(
                    onTap: () => setState(() => _acceptTerms = !_acceptTerms),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 20,
                          height: 20,
                          margin: const EdgeInsets.only(top: 1),
                          decoration: BoxDecoration(
                            color: _acceptTerms ? colors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _acceptTerms ? colors.primary : colors.border,
                              width: 1.5,
                            ),
                          ),
                          child: _acceptTerms
                              ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: GoogleFonts.inter(fontSize: 13, color: colors.mutedForeground, height: 1.4),
                              children: [
                                const TextSpan(text: 'Acepto los '),
                                TextSpan(
                                  text: 'Términos y Condiciones',
                                  style: GoogleFonts.inter(fontSize: 13, color: colors.primary, fontWeight: FontWeight.w600),
                                ),
                                const TextSpan(text: ' y la '),
                                TextSpan(
                                  text: 'Política de Privacidad',
                                  style: GoogleFonts.inter(fontSize: 13, color: colors.primary, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: colors.primary.withValues(alpha: 0.6),
                        disabledForegroundColor: Colors.white.withValues(alpha: 0.8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                          : Text(
                        'Crear cuenta',
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Ya tienes cuenta? ',
                          style: GoogleFonts.inter(fontSize: 14, color: colors.mutedForeground),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Text(
                            'Inicia sesión',
                            style: GoogleFonts.inter(fontSize: 14, color: colors.primary, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      );
    }

    Widget _buildLabel(DynamicColors colors, String text) {
      return Text(
        text,
        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: colors.foreground),
      );
    }

    Widget _buildTextField({
      required DynamicColors colors,
      required TextEditingController controller,
      required String hint,
      required IconData icon,
      TextInputType? keyboardType,
    }) {
      return Container(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border),
        ),
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.inter(fontSize: 14, color: colors.foreground),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(fontSize: 14, color: colors.mutedForeground.withValues(alpha: 0.7)),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 14, right: 10),
              child: Icon(icon, size: 20, color: colors.mutedForeground),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      );
    }

    Widget _buildPasswordField({
      required DynamicColors colors,
      required TextEditingController controller,
      required String hint,
      required bool obscure,
      required VoidCallback onToggle,
    }) {
      return Container(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border),
        ),
        child: TextField(
          controller: controller,
          obscureText: obscure,
          style: GoogleFonts.inter(fontSize: 14, color: colors.foreground),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(fontSize: 14, color: colors.mutedForeground.withValues(alpha: 0.7)),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 14, right: 10),
              child: Icon(Icons.lock_outline_rounded, size: 20, color: colors.mutedForeground),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: IconButton(
                onPressed: onToggle,
                icon: Icon(
                  obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 20,
                  color: colors.mutedForeground,
                ),
              ),
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      );
    }
  }
