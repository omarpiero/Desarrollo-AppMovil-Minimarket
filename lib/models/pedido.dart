import 'package:cloud_firestore/cloud_firestore.dart';
import 'producto.dart';

enum EstadoPedido {
  pendiente,
  confirmado,
  preparando,
  enCamino,
  entregado,
  cancelado,
}

extension EstadoPedidoExt on EstadoPedido {
  String get label {
    switch (this) {
      case EstadoPedido.pendiente:
        return 'Pendiente';
      case EstadoPedido.confirmado:
        return 'Confirmado';
      case EstadoPedido.preparando:
        return 'Preparando';
      case EstadoPedido.enCamino:
        return 'En camino';
      case EstadoPedido.entregado:
        return 'Entregado';
      case EstadoPedido.cancelado:
        return 'Cancelado';
    }
  }

  String get icono {
    switch (this) {
      case EstadoPedido.pendiente:
        return '⏳';
      case EstadoPedido.confirmado:
        return '✅';
      case EstadoPedido.preparando:
        return '👨‍🍳';
      case EstadoPedido.enCamino:
        return '🛵';
      case EstadoPedido.entregado:
        return '📦';
      case EstadoPedido.cancelado:
        return '❌';
    }
  }

  String get descripcion {
    switch (this) {
      case EstadoPedido.pendiente:
        return 'Tu pedido está siendo revisado';
      case EstadoPedido.confirmado:
        return 'Tu pedido fue confirmado';
      case EstadoPedido.preparando:
        return 'Estamos preparando tu pedido';
      case EstadoPedido.enCamino:
        return 'Tu pedido está en camino';
      case EstadoPedido.entregado:
        return '¡Tu pedido fue entregado!';
      case EstadoPedido.cancelado:
        return 'El pedido fue cancelado';
    }
  }

  static EstadoPedido fromString(String value) {
    return EstadoPedido.values.firstWhere(
      (e) => e.name == value,
      orElse: () => EstadoPedido.pendiente,
    );
  }
}

class ItemPedido {
  final String productoId;
  final String nombre;
  final double precio;
  final int cantidad;
  final String imagenUrl;

  const ItemPedido({
    required this.productoId,
    required this.nombre,
    required this.precio,
    required this.cantidad,
    this.imagenUrl = '',
  });

  double get subtotal => precio * cantidad;

  factory ItemPedido.fromProducto(Producto producto, int cantidad) {
    return ItemPedido(
      productoId: producto.id,
      nombre: producto.nombre,
      precio: producto.precio,
      cantidad: cantidad,
      imagenUrl: producto.imagenUrl,
    );
  }

  Map<String, dynamic> toMap() => {
        'productoId': productoId,
        'nombre': nombre,
        'precio': precio,
        'cantidad': cantidad,
        'imagenUrl': imagenUrl,
      };

  factory ItemPedido.fromMap(Map<String, dynamic> map) {
    return ItemPedido(
      productoId: map['productoId'] ?? '',
      nombre: map['nombre'] ?? '',
      precio: (map['precio'] ?? 0).toDouble(),
      cantidad: (map['cantidad'] ?? 1).toInt(),
      imagenUrl: map['imagenUrl'] ?? '',
    );
  }
}

class Pedido {
  final String id;
  final List<ItemPedido> items;
  final String nombreCliente;
  final String telefono;
  final String direccionEntrega;
  final String referencia;
  final String metodoPago;
  final double total;
  final double costoDelivery;
  final EstadoPedido estado;
  final DateTime creadoEn;
  final DateTime? actualizadoEn;
  final String? notasAdicionales;

  const Pedido({
    required this.id,
    required this.items,
    required this.nombreCliente,
    required this.telefono,
    required this.direccionEntrega,
    required this.referencia,
    required this.metodoPago,
    required this.total,
    required this.costoDelivery,
    required this.estado,
    required this.creadoEn,
    this.actualizadoEn,
    this.notasAdicionales,
  });

  double get totalConDelivery => total + costoDelivery;

  Map<String, dynamic> toMap() => {
        'items': items.map((i) => i.toMap()).toList(),
        'nombreCliente': nombreCliente,
        'telefono': telefono,
        'direccionEntrega': direccionEntrega,
        'referencia': referencia,
        'metodoPago': metodoPago,
        'total': total,
        'costoDelivery': costoDelivery,
        'estado': estado.name,
        'creadoEn': Timestamp.fromDate(creadoEn),
        'actualizadoEn':
            actualizadoEn != null ? Timestamp.fromDate(actualizadoEn!) : null,
        'notasAdicionales': notasAdicionales,
      };

  factory Pedido.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final itemsList = (data['items'] as List<dynamic>? ?? [])
        .map((i) => ItemPedido.fromMap(i as Map<String, dynamic>))
        .toList();

    return Pedido(
      id: doc.id,
      items: itemsList,
      nombreCliente: data['nombreCliente'] ?? '',
      telefono: data['telefono'] ?? '',
      direccionEntrega: data['direccionEntrega'] ?? '',
      referencia: data['referencia'] ?? '',
      metodoPago: data['metodoPago'] ?? 'efectivo',
      total: (data['total'] ?? 0).toDouble(),
      costoDelivery: (data['costoDelivery'] ?? 0).toDouble(),
      estado: EstadoPedidoExt.fromString(data['estado'] ?? 'pendiente'),
      creadoEn: (data['creadoEn'] as Timestamp?)?.toDate() ?? DateTime.now(),
      actualizadoEn: (data['actualizadoEn'] as Timestamp?)?.toDate(),
      notasAdicionales: data['notasAdicionales'],
    );
  }

  Pedido copyWith({EstadoPedido? estado, DateTime? actualizadoEn}) {
    return Pedido(
      id: id,
      items: items,
      nombreCliente: nombreCliente,
      telefono: telefono,
      direccionEntrega: direccionEntrega,
      referencia: referencia,
      metodoPago: metodoPago,
      total: total,
      costoDelivery: costoDelivery,
      estado: estado ?? this.estado,
      creadoEn: creadoEn,
      actualizadoEn: actualizadoEn ?? this.actualizadoEn,
      notasAdicionales: notasAdicionales,
    );
  }
}
