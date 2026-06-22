import 'package:cloud_firestore/cloud_firestore.dart';

class Producto {
  final String id;
  final String nombre;
  final String descripcion;
  final String categoria;
  final double precio;
  final int stock;
  final bool disponible;
  final String imagenUrl;
  final double? precioOriginal; // ──> NUEVO: Campo de descuento opcional

  const Producto({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.categoria,
    required this.precio,
    this.stock = 0,
    this.disponible = true,
    this.imagenUrl = '',
    this.precioOriginal,
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
      imagenUrl: data['imagenUrl'] ?? '',
      precioOriginal: (data['precioOriginal'] as num?)?.toDouble(),
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
      'imagenUrl': imagenUrl,
      if (precioOriginal != null) 'precioOriginal': precioOriginal,
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
    String? imagenUrl,
    double? precioOriginal,
  }) {
    return Producto(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      categoria: categoria ?? this.categoria,
      precio: precio ?? this.precio,
      stock: stock ?? this.stock,
      disponible: disponible ?? this.disponible,
      imagenUrl: imagenUrl ?? this.imagenUrl,
      precioOriginal: precioOriginal ?? this.precioOriginal,
    );
  }

  /// Indica si el producto tiene stock bajo (< 5 unidades).
  bool get stockBajo => disponible && stock > 0 && stock < 5;

  /// Indica si el producto se puede agregar al carrito.
  bool get puedeAgregar => disponible && stock > 0;

  /// Calcula el porcentaje de descuento si existe precio original.
  int? get porcentajeDescuento {
    if (precioOriginal == null || precioOriginal! <= precio) return null;
    return (((precioOriginal! - precio) / precioOriginal!) * 100).round();
  }

  @override
  String toString() =>
      'Producto(id: $id, nombre: $nombre, precio: $precio, stock: $stock, disponible: $disponible, imagenUrl: $imagenUrl, precioOriginal: $precioOriginal)';
}
