import 'package:flutter/material.dart';
import '../../models/pedido.dart';
import '../../services/delivery_service.dart';
import '../../config/theme.dart';
import 'package:intl/intl.dart';

class AdminPedidosScreen extends StatefulWidget {
  const AdminPedidosScreen({super.key});

  @override
  State<AdminPedidosScreen> createState() => _AdminPedidosScreenState();
}

class _AdminPedidosScreenState extends State<AdminPedidosScreen> {
  final DeliveryService _deliveryService = DeliveryService();

  Color _getColorParaEstado(EstadoPedido estado) {
    switch (estado) {
      case EstadoPedido.pendiente:
        return Colors.grey;
      case EstadoPedido.confirmado:
        return Colors.blue;
      case EstadoPedido.preparando:
        return Colors.orange;
      case EstadoPedido.enCamino:
        return Colors.purple;
      case EstadoPedido.entregado:
        return MinimarketTheme.disponible;
      case EstadoPedido.cancelado:
        return MinimarketTheme.error;
    }
  }

  void _mostrarDialogoDetalle(Pedido pedido) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Pedido ${pedido.id.substring(0, 8).toUpperCase()}'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Detalle de Productos:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...pedido.items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text('${item.cantidad}x ${item.nombre}')),
                          Text('S/ ${item.subtotal.toStringAsFixed(2)}'),
                        ],
                      ),
                    );
                  }),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal:'),
                      Text('S/ ${pedido.total.toStringAsFixed(2)}'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Delivery:'),
                      Text('S/ ${pedido.costoDelivery.toStringAsFixed(2)}'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Descuento:'),
                      Text('-S/ ${pedido.descuentoAplicado.toStringAsFixed(2)}', style: const TextStyle(color: MinimarketTheme.disponible)),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('TOTAL:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('S/ ${pedido.totalConDelivery.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  void _cambiarEstado(Pedido pedido, EstadoPedido nuevoEstado) async {
    try {
      await _deliveryService.actualizarEstado(pedido.id, nuevoEstado);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Estado cambiado a ${nuevoEstado.name}'),
            backgroundColor: MinimarketTheme.disponible,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cambiar estado: $e'), backgroundColor: MinimarketTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Gestión de Pedidos',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: MinimarketTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: StreamBuilder<List<Pedido>>(
                stream: _deliveryService.streamPedidos(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: MinimarketTheme.primaryRed));
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error al cargar datos: ${snapshot.error}', style: const TextStyle(color: MinimarketTheme.error)));
                  }
                  
                  final pedidos = snapshot.data ?? [];
                  if (pedidos.isEmpty) {
                    return const Center(child: Text('No hay pedidos registrados.', style: TextStyle(color: MinimarketTheme.textSecondary)));
                  }

                  return SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(MinimarketTheme.background),
                        columns: const [
                          DataColumn(label: Text('ID')),
                          DataColumn(label: Text('Fecha')),
                          DataColumn(label: Text('Cliente (DNI)')),
                          DataColumn(label: Text('Monto Total')),
                          DataColumn(label: Text('Estado')),
                          DataColumn(label: Text('Acciones')),
                        ],
                        rows: pedidos.map((pedido) {
                          return DataRow(
                            cells: [
                              DataCell(Text(pedido.id.substring(0, 8).toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold))),
                              DataCell(Text(DateFormat('dd/MM/yyyy HH:mm').format(pedido.creadoEn))),
                              DataCell(Text(pedido.userId)),
                              DataCell(Text('S/ ${pedido.total.toStringAsFixed(2)}')),
                              DataCell(
                                DropdownButton<EstadoPedido>(
                                  value: pedido.estado,
                                  dropdownColor: Colors.white,
                                  style: TextStyle(
                                    color: _getColorParaEstado(pedido.estado),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                  underline: Container(height: 1, color: _getColorParaEstado(pedido.estado).withValues(alpha: 0.3)),
                                  items: EstadoPedido.values.map((estado) {
                                    return DropdownMenuItem(
                                      value: estado,
                                      child: Text(estado.name.toUpperCase()),
                                    );
                                  }).toList(),
                                  onChanged: (nuevoEstado) {
                                    if (nuevoEstado != null && nuevoEstado != pedido.estado) {
                                      _cambiarEstado(pedido, nuevoEstado);
                                    }
                                  },
                                ),
                              ),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.receipt_long_outlined, color: MinimarketTheme.primaryRed),
                                      tooltip: 'Ver Detalle',
                                      onPressed: () => _mostrarDialogoDetalle(pedido),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
