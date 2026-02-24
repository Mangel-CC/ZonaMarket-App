class Product {
  final int id;
  final String nombre;
  final double precio;
  final String? imagen;

  const Product({
    required this.id,
    required this.nombre,
    required this.precio,
    this.imagen,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      nombre: json['nombre'] as String? ?? '',
      precio: json['precio'] is double
          ? json['precio']
          : double.tryParse(json['precio'].toString()) ?? 0.0,
      imagen: json['imagen'] as String?,
    );
  }
}

class Category {
  final int id;
  final String nombre;

  const Category({required this.id, required this.nombre});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      nombre: json['nombre'] as String? ?? '',
    );
  }
}
