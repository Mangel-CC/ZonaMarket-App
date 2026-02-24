import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'main_shell.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;
  String? _errorMessage;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRememberedCredentials();
  }

  Future<void> _loadRememberedCredentials() async {
    final remembered = await AuthService.getRememberMe();
    if (remembered != null && mounted) {
      setState(() {
        _rememberMe = true;
        _emailController.text = remembered.email;
        _passwordController.text = remembered.password;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // Limpiar error previo
    setState(() => _errorMessage = null);

    // Validar campos
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Email y contraseña son requeridos');
      return;
    }

    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
      setState(() => _errorMessage = 'Ingresa un correo valido');
      return;
    }

    // Iniciar carga
    setState(() => _isLoading = true);

    final result = await AuthService.login(
      email: email,
      password: password,
    );

    // Si el widget ya no esta montado, no hacer nada
    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result.success && result.user != null) {
      // Save or clear "remember me" credentials
      await AuthService.setRememberMe(
        enabled: _rememberMe,
        email: email,
        password: password,
      );
      // Login exitoso: navegar al Home
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    } else {
      // Mostrar error
      setState(() => _errorMessage = result.error ?? 'Error desconocido');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),

                // Logo and branding
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'JM',
                            style: GoogleFonts.dmSans(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -1,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'ZonaMarket',
                        style: GoogleFonts.dmSans(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.foreground,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tu mercado local, siempre cerca',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.mutedForeground,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Welcome text
                Text(
                  'Iniciar sesión',
                  style: GoogleFonts.dmSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.foreground,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ingresa tus datos para continuar',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.mutedForeground,
                  ),
                ),

                const SizedBox(height: 28),

                // Error message
                if (_errorMessage != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.destructive.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.destructive.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 18,
                          color: AppColors.destructive,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.destructive,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () =>
                              setState(() => _errorMessage = null),
                          child: Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: AppColors.destructive.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Email field
                _buildLabel('Correo electrónico'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _emailController,
                  hint: 'tu@correo.com',
                  icon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                ),

                const SizedBox(height: 20),

                // Password field
                _buildLabel('Contraseña'),
                const SizedBox(height: 8),
                _buildPasswordField(),

                const SizedBox(height: 16),

                // Remember me + Forgot password
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _rememberMe = !_rememberMe),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: _rememberMe
                                  ? AppColors.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: _rememberMe
                                    ? AppColors.primary
                                    : AppColors.border,
                                width: 1.5,
                              ),
                            ),
                            child: _rememberMe
                                ? const Icon(
                              Icons.check_rounded,
                              size: 14,
                              color: Colors.white,
                            )
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Recordarme',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.foreground,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        // TODO: Navigate to forgot password
                      },
                      child: Text(
                        'Olvidaste tu contraseña?',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // Login button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                      AppColors.primary.withValues(alpha: 0.6),
                      disabledForegroundColor:
                      Colors.white.withValues(alpha: 0.8),
                      elevation: 0,
                      shadowColor: AppColors.primary.withValues(alpha: 0.4),
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
                        : Text(
                      'Iniciar sesión',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider(color: AppColors.border)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'o continuar con',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider(color: AppColors.border)),
                  ],
                ),

                const SizedBox(height: 24),

                // Social login buttons
                Row(
                  children: [
                    Expanded(
                      child: _SocialButton(
                        label: 'Google',
                        customIcon: const _GoogleIcon(size: 20),
                        onTap: () {},
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SocialButton(
                        label: 'Apple',
                        icon: Icons.apple_rounded,
                        iconSize: 20,
                        onTap: () {},
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Sign up link
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'No tienes cuenta? ',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const RegisterScreen()),
                          );
                        },
                        child: Text(
                          'Registrate',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.foreground,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.foreground,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.mutedForeground.withValues(alpha: 0.7),
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 14, right: 10),
            child: Icon(icon, size: 20, color: AppColors.mutedForeground),
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

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        style: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.foreground,
        ),
        decoration: InputDecoration(
          hintText: 'Tu contraseña',
          hintStyle: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.mutedForeground.withValues(alpha: 0.7),
          ),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 14, right: 10),
            child: Icon(Icons.lock_outline_rounded, size: 20, color: AppColors.mutedForeground),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          suffixIcon: Padding(
            padding: const EdgeInsets.only(right: 4),
            child: IconButton(
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
                color: AppColors.mutedForeground,
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

class _SocialButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Widget? customIcon;
  final double iconSize;
  final VoidCallback onTap;

  const _SocialButton({
    required this.label,
    this.icon,
    this.customIcon,
    this.iconSize = 20,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (customIcon != null)
              customIcon!
            else if (icon != null)
              Icon(icon, size: iconSize, color: AppColors.foreground),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Official multicolor Google "G" icon painted via CustomPainter using the
/// exact SVG path data from the official Google logo.
class _GoogleIcon extends StatelessWidget {
  final double size;
  const _GoogleIcon({this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Scale factor: original SVG is 32x32
    final double s = size.width / 32;

    // Green path
    final greenPath = Path()
      ..moveTo(23.75 * s, 16 * s)
      ..cubicTo(23.53 * s, 20.24 * s, 20.12 * s, 23.75 * s, 16 * s, 23.75 * s)
      ..cubicTo(12.74 * s, 23.75 * s, 9.57 * s, 21.38 * s, 8.72 * s, 18.63 * s)
      ..lineTo(4.28 * s, 22.17 * s)
      ..cubicTo(6.65 * s, 26.44 * s, 11.02 * s, 29.25 * s, 16 * s, 29.25 * s)
      ..cubicTo(22.65 * s, 29.25 * s, 28.2 * s, 24.86 * s, 29.25 * s, 16 * s)
      ..close();
    canvas.drawPath(greenPath, Paint()..color = const Color(0xFF00AC47));

    // Blue top-right path
    final bluePath1 = Path()
      ..moveTo(23.75 * s, 16 * s)
      ..cubicTo(23.75 * s, 18.48 * s, 22.82 * s, 20.64 * s, 20.50 * s, 22.30 * s)
      ..lineTo(24.88 * s, 25.80 * s)
      ..cubicTo(27.63 * s, 23.55 * s, 29.25 * s, 20.04 * s, 29.25 * s, 16 * s)
      ..close();
    canvas.drawPath(bluePath1, Paint()..color = const Color(0xFF4285F4));

    // Yellow left path
    final yellowPath = Path()
      ..moveTo(8.25 * s, 16 * s)
      ..cubicTo(8.25 * s, 15.08 * s, 8.41 * s, 14.19 * s, 8.72 * s, 13.37 * s)
      ..lineTo(4.28 * s, 9.83 * s)
      ..cubicTo(2.82 * s, 12.66 * s, 2.82 * s, 19.34 * s, 4.28 * s, 22.17 * s)
      ..lineTo(8.72 * s, 18.63 * s)
      ..cubicTo(8.41 * s, 17.81 * s, 8.25 * s, 16.92 * s, 8.25 * s, 16 * s)
      ..close();
    canvas.drawPath(yellowPath, Paint()..color = const Color(0xFFFFBA00));

    // Red top-left path
    final redPath = Path()
      ..moveTo(16 * s, 8.25 * s)
      ..cubicTo(18.12 * s, 8.25 * s, 19.80 * s, 8.97 * s, 20.56 * s, 9.75 * s)
      ..lineTo(24.62 * s, 5.96 * s)
      ..cubicTo(22.39 * s, 3.81 * s, 19.45 * s, 2.75 * s, 16 * s, 2.75 * s)
      ..cubicTo(11.02 * s, 2.75 * s, 6.65 * s, 5.56 * s, 4.28 * s, 9.83 * s)
      ..lineTo(8.72 * s, 13.37 * s)
      ..cubicTo(9.68 * s, 10.41 * s, 12.59 * s, 8.25 * s, 16 * s, 8.25 * s)
      ..close();
    canvas.drawPath(redPath, Paint()..color = const Color(0xFFEA4435));

    // Blue bar (the horizontal bar of the G)
    final blueBarPath = Path()
      ..moveTo(29.25 * s, 15 * s)
      ..lineTo(29.25 * s, 16 * s)
      ..lineTo(27 * s, 19.5 * s)
      ..lineTo(16.5 * s, 19.5 * s)
      ..lineTo(16.5 * s, 14 * s)
      ..lineTo(28.25 * s, 14 * s)
      ..cubicTo(28.80 * s, 14 * s, 29.25 * s, 14.45 * s, 29.25 * s, 15 * s)
      ..close();
    canvas.drawPath(blueBarPath, Paint()..color = const Color(0xFF4285F4));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
