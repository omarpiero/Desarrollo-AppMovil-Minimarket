import 'package:cloud_firestore/cloud_firestore.dart';
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

  /// Stream de un pedido específico para seguimiento en tiempo real.
  Stream<Pedido?> streamPedido(String id) {
    return _pedidosRef.doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Pedido.fromFirestore(doc);
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
  /// Cancela un pedido (solo si está en estado pendiente o confirmado).
  Future<bool> cancelarPedido(String pedidoId) async {
    final doc = await _pedidosRef.doc(pedidoId).get();
    if (!doc.exists) return false;

    final pedido = Pedido.fromFirestore(doc);
    if (pedido.estado == EstadoPedido.preparando ||
        pedido.estado == EstadoPedido.enCamino ||
        pedido.estado == EstadoPedido.entregado) {
      return false; // No se puede cancelar
    }

    await _pedidosRef.doc(pedidoId).update({
      'estado': EstadoPedido.cancelado.name,
      'actualizadoEn': Timestamp.fromDate(DateTime.now()),
    });
    return true;
  }

  // ─── HELPERS ───
  /// Calcula el costo de delivery según el total del pedido.
  static double calcularCostoDelivery(double totalProductos) {
    if (totalProductos >= 50.0) return 0.0; // Delivery gratis sobre S/ 50
    return costoDeliveryFijo;
  }
}
