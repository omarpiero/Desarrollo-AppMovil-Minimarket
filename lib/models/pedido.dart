// lib/models/pedido.dart

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
  final String userId; // ──> NUEVO: ID del cliente de Firebase Auth
  final List<ItemPedido> items;
  final String nombreCliente;
  final String telefono;
  final String direccionEntrega;
  final String referencia;
  final String metodoPago;
  final double total;
  final double costoDelivery;
  final double descuentoAplicado; // ──> NUEVO: Descuento en soles por canje
  final int puntosUtilizados;     // ──> NUEVO: Puntos gastados en este pedido
  final int puntosGanados;         // ──> NUEVO: Puntos que otorga esta compra
  final EstadoPedido estado;
  final DateTime creadoEn;
  final DateTime? actualizadoEn;
  final String? notasAdicionales;
  final String? tiendaPlaceId;
  final String? tiendaId;
  final String? tiendaNombre;
  final String? tiendaDireccion;
  final double? tiendaLatitud;
  final double? tiendaLongitud;
  final double? clienteLatitud;
  final double? clienteLongitud;
  final int? distanciaRutaMetros;
  final int? duracionRutaSegundos;
  final String? distanciaRutaTexto;
  final String? duracionRutaTexto;

  const Pedido({
    required this.id,
    required this.userId, // ──> NUEVO
    required this.items,
    required this.nombreCliente,
    required this.telefono,
    required this.direccionEntrega,
    required this.referencia,
    required this.metodoPago,
    required this.total,
    required this.costoDelivery,
    this.descuentoAplicado = 0.0, // ──> NUEVO (por defecto 0)
    this.puntosUtilizados = 0,    // ──> NUEVO (por defecto 0)
    this.puntosGanados = 0,       // ──> NUEVO (por defecto 0)
    required this.estado,
    required this.creadoEn,
    this.actualizadoEn,
    this.notasAdicionales,
    this.tiendaPlaceId,
    this.tiendaId,
    this.tiendaNombre,
    this.tiendaDireccion,
    this.tiendaLatitud,
    this.tiendaLongitud,
    this.clienteLatitud,
    this.clienteLongitud,
    this.distanciaRutaMetros,
    this.duracionRutaSegundos,
    this.distanciaRutaTexto,
    this.duracionRutaTexto,
  });

  // Modificado: Ahora resta el descuento aplicado de los puntos al total final
  double get totalConDelivery => (total + costoDelivery) - descuentoAplicado;

  Map<String, dynamic> toMap() => {
        'userId': userId, // ──> NUEVO
        'items': items.map((i) => i.toMap()).toList(),
        'nombreCliente': nombreCliente,
        'telefono': telefono,
        'direccionEntrega': direccionEntrega,
        'referencia': referencia,
        'metodoPago': metodoPago,
        'total': total,
        'costoDelivery': costoDelivery,
        'descuentoAplicado': descuentoAplicado, // ──> NUEVO
        'puntosUtilizados': puntosUtilizados,   // ──> NUEVO
        'puntosGanados': puntosGanados,         // ──> NUEVO
        'estado': estado.name,
        'creadoEn': Timestamp.fromDate(creadoEn),
        'actualizadoEn':
            actualizadoEn != null ? Timestamp.fromDate(actualizadoEn!) : null,
        'notasAdicionales': notasAdicionales,
        'tiendaPlaceId': tiendaPlaceId,
        'tiendaId': tiendaId,
        'tiendaNombre': tiendaNombre,
        'tiendaDireccion': tiendaDireccion,
        'tiendaLatitud': tiendaLatitud,
        'tiendaLongitud': tiendaLongitud,
        'clienteLatitud': clienteLatitud,
        'clienteLongitud': clienteLongitud,
        'distanciaRutaMetros': distanciaRutaMetros,
        'duracionRutaSegundos': duracionRutaSegundos,
        'distanciaRutaTexto': distanciaRutaTexto,
        'duracionRutaTexto': duracionRutaTexto,
      };

  factory Pedido.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final itemsList = (data['items'] as List<dynamic>? ?? [])
        .map((i) => ItemPedido.fromMap(i as Map<String, dynamic>))
        .toList();

    return Pedido(
      id: doc.id,
      userId: data['userId'] ?? '', // ──> NUEVO
      items: itemsList,
      nombreCliente: data['nombreCliente'] ?? '',
      telefono: data['telefono'] ?? '',
      direccionEntrega: data['direccionEntrega'] ?? '',
      referencia: data['referencia'] ?? '',
      metodoPago: data['metodoPago'] ?? 'efectivo',
      total: (data['total'] ?? 0).toDouble(),
      costoDelivery: (data['costoDelivery'] ?? 0).toDouble(),
      descuentoAplicado: (data['descuentoAplicado'] ?? 0).toDouble(), // ──> NUEVO
      puntosUtilizados: (data['puntosUtilizados'] ?? 0).toInt(),       // ──> NUEVO
      puntosGanados: (data['puntosGanados'] ?? 0).toInt(),             // ──> NUEVO
      estado: EstadoPedidoExt.fromString(data['estado'] ?? 'pendiente'),
      creadoEn: (data['creadoEn'] as Timestamp?)?.toDate() ?? DateTime.now(),
      actualizadoEn: (data['actualizadoEn'] as Timestamp?)?.toDate(),
      notasAdicionales: data['notasAdicionales'],
      tiendaPlaceId: data['tiendaPlaceId'],
      tiendaId: data['tiendaId'],
      tiendaNombre: data['tiendaNombre'],
      tiendaDireccion: data['tiendaDireccion'],
      tiendaLatitud: (data['tiendaLatitud'] as num?)?.toDouble(),
      tiendaLongitud: (data['tiendaLongitud'] as num?)?.toDouble(),
      clienteLatitud: (data['clienteLatitud'] as num?)?.toDouble(),
      clienteLongitud: (data['clienteLongitud'] as num?)?.toDouble(),
      distanciaRutaMetros: (data['distanciaRutaMetros'] as num?)?.toInt(),
      duracionRutaSegundos: (data['duracionRutaSegundos'] as num?)?.toInt(),
      distanciaRutaTexto: data['distanciaRutaTexto'],
      duracionRutaTexto: data['duracionRutaTexto'],
    );
  }

  Pedido copyWith({EstadoPedido? estado, DateTime? actualizadoEn}) {
    return Pedido(
      id: id,
      userId: userId, // Mantiene el actual
      items: items,
      nombreCliente: nombreCliente,
      telefono: telefono,
      direccionEntrega: direccionEntrega,
      referencia: referencia,
      metodoPago: metodoPago,
      total: total,
      costoDelivery: costoDelivery,
      descuentoAplicado: descuentoAplicado, // Mantiene el actual
      puntosUtilizados: puntosUtilizados,   // Mantiene el actual
      puntosGanados: puntosGanados,         // Mantiene el actual
      estado: estado ?? this.estado,
      creadoEn: creadoEn,
      actualizadoEn: actualizadoEn ?? this.actualizadoEn,
      notasAdicionales: notasAdicionales,
      tiendaPlaceId: tiendaPlaceId,
      tiendaId: tiendaId,
      tiendaNombre: tiendaNombre,
      tiendaDireccion: tiendaDireccion,
      tiendaLatitud: tiendaLatitud,
      tiendaLongitud: tiendaLongitud,
      clienteLatitud: clienteLatitud,
      clienteLongitud: clienteLongitud,
      distanciaRutaMetros: distanciaRutaMetros,
      duracionRutaSegundos: duracionRutaSegundos,
      distanciaRutaTexto: distanciaRutaTexto,
      duracionRutaTexto: duracionRutaTexto,
    );
  }
}