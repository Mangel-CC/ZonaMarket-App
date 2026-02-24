class ApiConfig {
  static const String baseUrl = 'https://api.mangelcc.dev';

  static const String loginEndpoint = '$baseUrl/login';
  static const String registerEndpoint = '$baseUrl/register';
  static const String getUserDataEndpoint = '$baseUrl/getUserData';
  static const String productosEndpoint = '$baseUrl/productos';
  static const String categoriasEndpoint = '$baseUrl/categorias';
  static const String productDetailEndpoint = '$baseUrl/product'; // + /{id}
  static const String favoritesEndpoint = '$baseUrl/favorites';
  static const String favoritesAddEndpoint = '$baseUrl/favorites/add';
  static const String favoritesToggleEndpoint = '$baseUrl/favorites/toggle';
  static const String notificationsCountEndpoint = '$baseUrl/notifications/count';
  static const String notificationsEndpoint = '$baseUrl/notifications';
  static const String notificationsMarkReadEndpoint = '$baseUrl/notifications/mark-read';
  static const String chatListEndpoint = '$baseUrl/chat/list';
  static const String chatStartEndpoint = '$baseUrl/chat/start';

  // Profile
  static const String profileEndpoint = '$baseUrl/profile';
  static const String profileUpdateEndpoint = '$baseUrl/profile/update';

  // Cart
  static const String cartEndpoint = '$baseUrl/cart';
  static const String cartAddEndpoint = '$baseUrl/cart/add';
  static const String cartRemoveEndpoint = '$baseUrl/cart/remove';
  static const String cartClearEndpoint = '$baseUrl/cart/clear';

  // Orders
  static const String ordersEndpoint = '$baseUrl/orders';
  static const String ordersCreateEndpoint = '$baseUrl/orders/create';

  // Notifications
  static const String notificationsDeleteEndpoint = '$baseUrl/notifications/delete';
  static const String notificationsDeleteAllEndpoint = '$baseUrl/notifications/delete-all';

  // My Products
  static const String myProductsEndpoint = '$baseUrl/my-products';
  static const String myProductsDeleteEndpoint = '$baseUrl/my-products/delete';

  // Products Upload
  static const String productsUploadEndpoint = '$baseUrl/products/upload';


  static const Duration timeout = Duration(seconds: 15);
}
