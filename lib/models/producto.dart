import 'package:cloud_firestore/cloud_firestore.dart';

class Producto {
  final String id;
  final String nombre;
  final String descripcion;
  final String categoria;
  final double precio;
  final int stock;
  final bool disponible;

  const Producto({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.categoria,
    required this.precio,
    this.stock = 0,
    this.disponible = true,
  });

  /// Crea un Producto desde un DocumentSnapshot de Firestore.
  factory Producto.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Producto(
      id: doc.id,
      nombre: data['nombre'] ?? 'Sin nombre',
      descripcion: data['descripcion'] ?? '',
      categoria: data['categoria'] ?? 'Sin categoría',
      precio: (data['precio'] ?? 0).toDouble(),
      stock: (data['stock'] ?? 0).toInt(),
      disponible: data['disponible'] ?? true,
    );
  }

  /// Convierte el Producto a un Map para guardar en Firestore.
  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
      'categoria': categoria,
      'precio': precio,
      'stock': stock,
      'disponible': disponible,
    };
  }

  /// Crea una copia del Producto con campos modificados.
  Producto copyWith({
    String? id,
    String? nombre,
    String? descripcion,
    String? categoria,
    double? precio,
    int? stock,
    bool? disponible,
  }) {
    return Producto(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      categoria: categoria ?? this.categoria,
      precio: precio ?? this.precio,
      stock: stock ?? this.stock,
      disponible: disponible ?? this.disponible,
    );
  }

  /// Indica si el producto tiene stock bajo (< 5 unidades).
  bool get stockBajo => disponible && stock > 0 && stock < 5;

  /// Indica si el producto se puede agregar al carrito.
  bool get puedeAgregar => disponible && stock > 0;

  @override
  String toString() =>
      'Producto(id: $id, nombre: $nombre, precio: $precio, stock: $stock, disponible: $disponible)';
}
