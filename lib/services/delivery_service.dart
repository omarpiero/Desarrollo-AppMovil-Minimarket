import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/pedido.dart';

class DeliveryService {
  final CollectionReference _pedidosRef =
      FirebaseFirestore.instance.collection('pedidos');

  static const double costoDeliveryFijo = 5.00;

  // ─── CREATE ───
  /// Crea un nuevo pedido en Firestore y retorna el ID generado.
  Future<String> crearPedido(Pedido pedido) async {
    final docRef = await _pedidosRef.add(pedido.toMap());
    return docRef.id;
  }

  // ─── READ ───
  /// Obtiene todos los pedidos ordenados por fecha descendente.
  Future<List<Pedido>> obtenerPedidos() async {
    final snapshot =
        await _pedidosRef.orderBy('creadoEn', descending: true).get();
    return snapshot.docs.map((doc) => Pedido.fromFirestore(doc)).toList();
  }

  /// Obtiene los pedidos de un usuario específico ordenados por fecha descendente.
  Future<List<Pedido>> obtenerPedidosPorUsuario(String userId) async {
    final snapshot = await _pedidosRef.where('userId', isEqualTo: userId).get();
    final list = snapshot.docs.map((doc) => Pedido.fromFirestore(doc)).toList();
    list.sort((a, b) => b.creadoEn.compareTo(a.creadoEn));
    return list;
  }

  /// Obtiene un pedido por su ID.
  Future<Pedido?> obtenerPedidoPorId(String id) async {
    final doc = await _pedidosRef.doc(id).get();
    if (!doc.exists) return null;
    return Pedido.fromFirestore(doc);
  }

  /// Stream en tiempo real de todos los pedidos (para panel admin).
  Stream<List<Pedido>> streamPedidos() {
    return _pedidosRef
        .orderBy('creadoEn', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => Pedido.fromFirestore(doc)).toList());
  }

  /// Verifica si el pedido debe avanzar de estado en base al tiempo transcurrido (cada 5 minutos).
  void _checkAndProgressOrder(Pedido pedido) {
    if (pedido.estado == EstadoPedido.cancelado) {
      return;
    }
    final diffInSecs = DateTime.now().difference(pedido.creadoEn).inSeconds;
    
    EstadoPedido targetEstado = pedido.estado;
    if (diffInSecs >= 1200) {
      targetEstado = EstadoPedido.entregado;
    } else if (diffInSecs >= 900) {
      targetEstado = EstadoPedido.enCamino;
    } else if (diffInSecs >= 600) {
      targetEstado = EstadoPedido.preparando;
    } else if (diffInSecs >= 300) {
      targetEstado = EstadoPedido.confirmado;
    }

    if (targetEstado.index > pedido.estado.index) {
      _pedidosRef.doc(pedido.id).update({
        'estado': targetEstado.name,
        'actualizadoEn': Timestamp.fromDate(DateTime.now()),
      }).catchError((e) {
        debugPrint('Error actualizando estado automático del pedido ${pedido.id}: $e');
      });
    }
  }

  /// Stream de un pedido específico para seguimiento en tiempo real.
  Stream<Pedido?> streamPedido(String id) {
    return _pedidosRef.doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      final data = doc.data() as Map<String, dynamic>?;
      if (data?['visibleParaUsuario'] == false) return null;
      final pedido = Pedido.fromFirestore(doc);
      _checkAndProgressOrder(pedido);
      return pedido;
    });
  }

  /// Stream en tiempo real de pedidos de un usuario específico.
  Stream<List<Pedido>> streamPedidosPorUsuario(String userId) {
    return _pedidosRef
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) {
            final p = Pedido.fromFirestore(doc);
            _checkAndProgressOrder(p);
            final data = doc.data() as Map<String, dynamic>?;
            return MapEntry(p, data?['visibleParaUsuario'] != false);
          })
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();
      list.sort((a, b) => b.creadoEn.compareTo(a.creadoEn));
      return list;
    });
  }

  // ─── UPDATE ───
  /// Actualiza el estado de un pedido.
  Future<void> actualizarEstado(String pedidoId, EstadoPedido nuevoEstado) async {
    await _pedidosRef.doc(pedidoId).update({
      'estado': nuevoEstado.name,
      'actualizadoEn': Timestamp.fromDate(DateTime.now()),
    });
  }

  // ─── DELETE ───
  /// Cancela un pedido (solo si está en estado pendiente o confirmado y dentro del plazo de 5 minutos).
  /// Restaura el stock de los productos e incrementa/devuelve los puntos utilizados.
  Future<bool> cancelarPedido(String pedidoId) async {
    final doc = await _pedidosRef.doc(pedidoId).get();
    if (!doc.exists) return false;

    final pedido = Pedido.fromFirestore(doc);
    
    // Validar límite de 5 minutos desde la creación
    final diferencia = DateTime.now().difference(pedido.creadoEn);
    if (diferencia.inMinutes > 5) {
      return false; // Tiempo de cancelación expirado
    }

    if (pedido.estado == EstadoPedido.preparando ||
        pedido.estado == EstadoPedido.enCamino ||
        pedido.estado == EstadoPedido.entregado ||
        pedido.estado == EstadoPedido.cancelado) {
      return false; // No se puede cancelar
    }

    try {
      final userQuery = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('uid', isEqualTo: pedido.userId)
          .limit(1)
          .get();

      DocumentReference<Map<String, dynamic>>? userRef;
      String? userDni;

      if (userQuery.docs.isNotEmpty) {
        final userDoc = userQuery.docs.first;
        userRef = userDoc.reference;
        userDni = userDoc.id;
      }

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // 1. Ejecutar READS primero
        final List<DocumentSnapshot<Map<String, dynamic>>> prodSnapshots = [];
        final List<DocumentReference<Map<String, dynamic>>> prodRefs = [];
        for (final item in pedido.items) {
          final prodRef = FirebaseFirestore.instance.collection('productos').doc(item.productoId);
          final prodSnapshot = await transaction.get(prodRef);
          prodSnapshots.add(prodSnapshot);
          prodRefs.add(prodRef);
        }

        DocumentSnapshot<Map<String, dynamic>>? userSnapshot;
        if (userRef != null) {
          userSnapshot = await transaction.get(userRef);
        }

        // 2. Ejecutar WRITES
        // Actualizar estado del pedido
        transaction.update(_pedidosRef.doc(pedidoId), {
          'estado': EstadoPedido.cancelado.name,
          'actualizadoEn': Timestamp.fromDate(DateTime.now()),
        });

        // Restaurar Stock
        for (int i = 0; i < pedido.items.length; i++) {
          final item = pedido.items[i];
          final prodRef = prodRefs[i];
          final prodSnapshot = prodSnapshots[i];

          if (prodSnapshot.exists) {
            int stockActual = (prodSnapshot.data()?['stock'] ?? 0).toInt();
            int nuevoStock = stockActual + item.cantidad;
            transaction.update(prodRef, {
              'stock': nuevoStock,
              'disponible': true,
            });
          }
        }

        // Devolver puntos
        if (userRef != null && userSnapshot != null && userSnapshot.exists) {
          int puntosActuales = userSnapshot.data()?['puntosAcumulados'] ?? 0;
          int nuevosPuntos = puntosActuales + pedido.puntosUtilizados - pedido.puntosGanados;
          if (nuevosPuntos < 0) nuevosPuntos = 0;
          transaction.update(userRef, {'puntosAcumulados': nuevosPuntos});
        }
      });

      // Agregar registros al historial de puntos
      if (userDni != null) {
        if (pedido.puntosUtilizados > 0) {
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(userDni)
              .collection('historialPuntos')
              .add({
            'puntos': pedido.puntosUtilizados,
            'tipo': 'reembolso',
            'motivo': 'Reembolso por cancelación de pedido ${pedido.id.substring(0, 8).toUpperCase()}',
            'fecha': Timestamp.fromDate(DateTime.now()),
          });
        }
        if (pedido.puntosGanados > 0) {
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(userDni)
              .collection('historialPuntos')
              .add({
            'puntos': -pedido.puntosGanados,
            'tipo': 'descuento',
            'motivo': 'Deducción de puntos por cancelación de pedido ${pedido.id.substring(0, 8).toUpperCase()}',
            'fecha': Timestamp.fromDate(DateTime.now()),
          });
        }
      }

      return true;
    } catch (e) {
      debugPrint('Error en la transacción de cancelación de pedido: $e');
      return false;
    }
  }

  /// Elimina un pedido de la vista del usuario (soft delete si está entregado o cancelado).
  Future<bool> eliminarPedido(String pedidoId) async {
    try {
      final doc = await _pedidosRef.doc(pedidoId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        final estado = data?['estado'] ?? 'pendiente';

        if (estado == 'entregado' || estado == 'cancelado') {
          // Soft delete para mantener el pedido en Firestore para el panel admin
          await _pedidosRef.doc(pedidoId).update({
            'visibleParaUsuario': false,
            'actualizadoEn': Timestamp.fromDate(DateTime.now()),
          });
          return true;
        }
      }
      // Depuración: eliminación física si no está cancelado/entregado
      await _pedidosRef.doc(pedidoId).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  // ─── HELPERS ───
  /// Calcula el costo de delivery según la distancia, puntos (nivel) y total de productos.
  static double calcularCostoDelivery({
    required double distanciaKm,
    required int puntosUsuario,
    required double totalProductos,
  }) {
    // Rango
    String rango = 'Vecino';
    if (puntosUsuario >= 150) {
      rango = 'El Caserito';
    } else if (puntosUsuario >= 50) {
      rango = 'Amigo de la casa';
    }

    // Caserito es siempre gratis (100% descuento en delivery!)
    if (rango == 'El Caserito') {
      return 0.0;
    }
    
    // Amigo de la casa es gratis > S/40
    if (rango == 'Amigo de la casa' && totalProductos >= 40.0) {
      return 0.0;
    }
    
    // Cualquier usuario es gratis > S/50
    if (totalProductos >= 50.0) {
      return 0.0;
    }

    // Costo base según distancia
    double costoBase = 5.0;
    if (distanciaKm <= 2.0) {
      costoBase = 3.0;
    } else if (distanciaKm <= 5.0) {
      costoBase = 5.0;
    } else if (distanciaKm <= 10.0) {
      costoBase = 8.0;
    } else {
      costoBase = 12.0;
    }

    // Amigo de la casa obtiene 50% de descuento en el costo calculado
    if (rango == 'Amigo de la casa') {
      return costoBase * 0.5;
    }

    return costoBase;
  }
}
