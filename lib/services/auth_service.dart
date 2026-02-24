import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import '../models/user.dart';

class AuthResult {
  final bool success;
  final User? user;
  final String? error;

  const AuthResult({
    required this.success,
    this.user,
    this.error,
  });
}

class AuthService {
  static final _storage = FlutterSecureStorage();

  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';
  static const String _rememberMeKey = 'remember_me';
  static const String _rememberedEmailKey = 'remembered_email';
  static const String _rememberedPasswordKey = 'remembered_password';

  static Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
        Uri.parse(ApiConfig.loginEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      )
          .timeout(ApiConfig.timeout);

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final userData = body['user'] as Map<String, dynamic>;
        final user = User.fromJson(userData);

        await _saveSession(user);

        return AuthResult(success: true, user: user);
      }

      final errorMsg = body['error'] as String? ?? 'Error desconocido';
      return AuthResult(success: false, error: errorMsg);
    } on http.ClientException {
      return const AuthResult(
        success: false,
        error: 'No se pudo conectar al servidor. Verifica tu conexión.',
      );
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        return const AuthResult(
          success: false,
          error: 'El servidor tardo demasiado en responder.',
        );
      }
      return AuthResult(
        success: false,
        error: 'Error inesperado: ${e.toString()}',
      );
    }
  }

  static Future<AuthResult> register({
    required String name,
    required String lastname,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
        Uri.parse(ApiConfig.registerEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'lastname': lastname,
          'email': email,
          'password': password,
        }),
      )
          .timeout(ApiConfig.timeout);

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 201) {
        return const AuthResult(
          success: true,
          error: null,
        );
      }

      final errorMsg = body['message'] as String? ?? 'Error desconocido';
      return AuthResult(success: false, error: errorMsg);
    } on http.ClientException {
      return const AuthResult(
        success: false,
        error: 'No se pudo conectar al servidor. Verifica tu conexion.',
      );
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        return const AuthResult(
          success: false,
          error: 'El servidor tardo demasiado en responder.',
        );
      }
      return AuthResult(
        success: false,
        error: 'Error inesperado: ${e.toString()}',
      );
    }
  }

  static Future<void> _saveSession(User user) async {
    await _storage.write(key: _tokenKey, value: user.token);
    await _storage.write(key: _userIdKey, value: user.id.toString());
    await _storage.write(key: _userNameKey, value: user.nombre);
    await _storage.write(key: _userEmailKey, value: user.email);
  }

  static Future<String?> getToken() async {
    return _storage.read(key: _tokenKey);
  }

  static Future<User?> getSavedUser() async {
    final token = await _storage.read(key: _tokenKey);
    final idStr = await _storage.read(key: _userIdKey);
    final nombre = await _storage.read(key: _userNameKey);
    final email = await _storage.read(key: _userEmailKey);

    if (token == null || idStr == null || nombre == null || email == null) {
      return null;
    }

    final id = int.tryParse(idStr);
    if (id == null) return null;

    return User(id: id, nombre: nombre, email: email, token: token);
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  static Future<void> logout() async {
    // Preserve remember-me credentials across logout
    final rememberMe = await _storage.read(key: _rememberMeKey);
    final rememberedEmail = await _storage.read(key: _rememberedEmailKey);
    final rememberedPassword = await _storage.read(key: _rememberedPasswordKey);

    await _storage.deleteAll();

    // Restore remember-me data if it was set
    if (rememberMe == 'true' && rememberedEmail != null && rememberedPassword != null) {
      await _storage.write(key: _rememberMeKey, value: 'true');
      await _storage.write(key: _rememberedEmailKey, value: rememberedEmail);
      await _storage.write(key: _rememberedPasswordKey, value: rememberedPassword);
    }
  }

  /// Save or clear "remember me" credentials.
  static Future<void> setRememberMe({
    required bool enabled,
    required String email,
    required String password,
  }) async {
    if (enabled) {
      await _storage.write(key: _rememberMeKey, value: 'true');
      await _storage.write(key: _rememberedEmailKey, value: email);
      await _storage.write(key: _rememberedPasswordKey, value: password);
    } else {
      await _storage.delete(key: _rememberMeKey);
      await _storage.delete(key: _rememberedEmailKey);
      await _storage.delete(key: _rememberedPasswordKey);
    }
  }

  /// Get saved "remember me" data. Returns null if not set.
  static Future<({bool enabled, String email, String password})?> getRememberMe() async {
    final flag = await _storage.read(key: _rememberMeKey);
    if (flag != 'true') return null;

    final email = await _storage.read(key: _rememberedEmailKey);
    final password = await _storage.read(key: _rememberedPasswordKey);
    if (email == null || password == null) return null;

    return (enabled: true, email: email, password: password);
  }
}
