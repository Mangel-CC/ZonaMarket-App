import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../services/auth_service.dart';

class ProductService {
  /// Fetch products with optional search and category filter.
  /// No auth required.
  static Future<List<Map<String, dynamic>>> getProducts({
    String? searchQuery,
    String? categoryId,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        queryParams['search_query'] = searchQuery.trim();
      }
      if (categoryId != null && categoryId.isNotEmpty) {
        queryParams['selected_category'] = categoryId;
      }

      final uri = Uri.parse(ApiConfig.productosEndpoint)
          .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Fetch categories. No auth required.
  static Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.categoriasEndpoint),
        headers: {'Accept': 'application/json'},
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Fetch product detail. Auth required.
  static Future<Map<String, dynamic>?> getProductDetail(int productId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('${ApiConfig.productDetailEndpoint}/$productId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Fetch product reviews. No auth required.
  /// Returns an empty list if there are no reviews or on error.
  static Future<List<Map<String, dynamic>>> getProductReviews(int productId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.productDetailEndpoint}/$productId/reviews'),
        headers: {'Accept': 'application/json'},
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          return decoded.cast<Map<String, dynamic>>();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Toggle product favorite status. Auth required.
  /// Returns a map with 'success' and 'is_favorito' keys, or null on failure.
  static Future<Map<String, dynamic>?> toggleFavorite({
    required int userId,
    required int productId,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return null;

      final response = await http.post(
        Uri.parse(ApiConfig.favoritesToggleEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'usuario_id': userId,
          'producto_id': productId,
        }),
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get user favorites list. Auth required.
  static Future<List<Map<String, dynamic>>> getFavorites() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return [];

      final response = await http.get(
        Uri.parse(ApiConfig.favoritesEndpoint),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Get unread notifications count. Auth required.
  static Future<int> getUnreadNotificationsCount() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return 0;

      final response = await http.get(
        Uri.parse(ApiConfig.notificationsCountEndpoint),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return body['unreadCount'] as int? ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Get notifications list. Auth required.
  static Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return [];

      final response = await http.get(
        Uri.parse(ApiConfig.notificationsEndpoint),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Mark all notifications as read. Auth required.
  static Future<bool> markNotificationsRead() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return false;

      final response = await http.post(
        Uri.parse(ApiConfig.notificationsMarkReadEndpoint),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(ApiConfig.timeout);

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Delete a single notification. Auth required.
  static Future<bool> deleteNotification(int id) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return false;

      final response = await http.post(
        Uri.parse(ApiConfig.notificationsDeleteEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'id': id}),
      ).timeout(ApiConfig.timeout);

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Delete all notifications. Auth required.
  static Future<bool> deleteAllNotifications() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return false;

      final response = await http.post(
        Uri.parse(ApiConfig.notificationsDeleteAllEndpoint),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(ApiConfig.timeout);

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get profile info. Auth required.
  static Future<Map<String, dynamic>?> getProfile() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse(ApiConfig.profileEndpoint),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['success'] == true) {
          return body['user'] as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Update profile. Auth required.
  static Future<Map<String, dynamic>?> updateProfile({
    required String nombre,
    required String apellidos,
    required String email,
    required String password,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return null;

      final response = await http.post(
        Uri.parse(ApiConfig.profileUpdateEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'nombre': nombre,
          'apellidos': apellidos,
          'email': email,
          'password': password,
        }),
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get orders list. Auth required.
  static Future<List<Map<String, dynamic>>> getOrders() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return [];

      final response = await http.get(
        Uri.parse(ApiConfig.ordersEndpoint),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['success'] == true) {
          final List<dynamic> data = body['orders'] ?? [];
          return data.cast<Map<String, dynamic>>();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Get order detail. Auth required.
  static Future<Map<String, dynamic>?> getOrderDetail(int orderId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('${ApiConfig.ordersEndpoint}/$orderId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['success'] == true) {
          return body['order'] as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Cancel order. Auth required.
  static Future<bool> cancelOrder(int orderId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return false;

      final response = await http.put(
        Uri.parse('${ApiConfig.ordersEndpoint}/$orderId/cancel'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(ApiConfig.timeout);

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get cart. Auth required.
  static Future<Map<String, dynamic>?> getCart(int userId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return null;

      final uri = Uri.parse(ApiConfig.cartEndpoint)
          .replace(queryParameters: {'usuario_id': userId.toString()});

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Add item to cart. Auth required.
  static Future<bool> addToCart({
    required int userId,
    required int productId,
    int cantidad = 1,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return false;

      final response = await http.post(
        Uri.parse(ApiConfig.cartAddEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'usuario_id': userId,
          'producto_id': productId,
          'cantidad': cantidad,
        }),
      ).timeout(ApiConfig.timeout);

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Remove item from cart. Auth required.
  static Future<bool> removeFromCart({
    required int itemId,
    required int userId,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return false;

      final request = http.Request('DELETE', Uri.parse(ApiConfig.cartRemoveEndpoint));
      request.headers.addAll({
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });
      request.body = jsonEncode({
        'item_id': itemId,
        'usuario_id': userId,
      });

      final streamedResponse = await request.send().timeout(ApiConfig.timeout);
      return streamedResponse.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Clear entire cart. Auth required.
  static Future<bool> clearCart(int userId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return false;

      final response = await http.post(
        Uri.parse(ApiConfig.cartClearEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'usuario_id': userId}),
      ).timeout(ApiConfig.timeout);

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Update cart item quantity. Auth required.
  static Future<bool> updateCartItem({
    required int itemId,
    required int userId,
    required int cantidad,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return false;

      final response = await http.put(
        Uri.parse('${ApiConfig.cartEndpoint}/update'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'item_id': itemId,
          'usuario_id': userId,
          'cantidad': cantidad,
        }),
      ).timeout(ApiConfig.timeout);

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get my products (as seller). Auth required.
  static Future<List<Map<String, dynamic>>> getMyProducts() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return [];

      final response = await http.get(
        Uri.parse(ApiConfig.myProductsEndpoint),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Delete my product. Auth required.
  static Future<bool> deleteMyProduct(int productId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return false;

      final response = await http.post(
        Uri.parse(ApiConfig.myProductsDeleteEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'product_id': productId}),
      ).timeout(ApiConfig.timeout);

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Update an existing product. Auth required.
  static Future<Map<String, dynamic>?> updateProduct({
    required int productId,
    required String nombre,
    required String descripcion,
    required double precio,
    required int cantidad,
    required int idCategoria,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return null;

      final response = await http.post(
        Uri.parse(ApiConfig.myProductsUpdateEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'product_id': productId,
          'nombre': nombre,
          'descripcion': descripcion,
          'precio': precio,
          'cantidad': cantidad,
          'id_categoria': idCategoria,
        }),
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Upload a new product with image. Auth required (multipart/form-data).
  static Future<Map<String, dynamic>?> uploadProduct({
    required String nombre,
    required String descripcion,
    required double precio,
    required int cantidad,
    required int idCategoria,
    required Uint8List imageBytes,
    required String imageName,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return null;

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.productsUploadEndpoint),
      );
      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      request.fields['nombre'] = nombre;
      request.fields['descripcion'] = descripcion;
      request.fields['precio'] = precio.toString();
      request.fields['cantidad'] = cantidad.toString();
      request.fields['id_categoria'] = idCategoria.toString();
      request.files.add(http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: imageName,
      ));

      final streamed = await request.send().timeout(ApiConfig.timeout);
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get user data from token. Auth required.
  static Future<Map<String, dynamic>?> getUserData() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return null;

      final response = await http.post(
        Uri.parse(ApiConfig.getUserDataEndpoint),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['success'] == true) {
          return body['user'] as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
