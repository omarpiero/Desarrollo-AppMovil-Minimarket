import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/pedido.dart';
import '../services/delivery_service.dart';

class SeguimientoScreen extends StatelessWidget {
  final String pedidoId;

  const SeguimientoScreen({super.key, required this.pedidoId});

  @override
  Widget build(BuildContext context) {
    final deliveryService = DeliveryService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seguimiento de Pedido'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
            icon: const Icon(Icons.home_rounded, color: MinimarketTheme.primaryYellow),
            label: const Text(
              'Inicio',
              style: TextStyle(color: MinimarketTheme.primaryYellow),
            ),
          ),
        ],
      ),
      body: StreamBuilder<Pedido?>(
        stream: deliveryService.streamPedido(pedidoId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Text('No se pudo cargar el pedido'),
            );
          }

          final pedido = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ─── Header del estado ───
                _EstadoHeader(pedido: pedido),

                const SizedBox(height: 20),

                // ─── Timeline de estados ───
                _TimelineEstados(estadoActual: pedido.estado),

                const SizedBox(height: 20),

                // ─── Detalles del pedido ───
                _DetalleCard(
                  titulo: 'Número de pedido',
                  contenido: '#${pedido.id.substring(0, 8).toUpperCase()}',
                  icono: Icons.tag_rounded,
                ),

                const SizedBox(height: 12),

                _DetalleCard(
                  titulo: 'Dirección de entrega',
                  contenido: pedido.direccionEntrega,
                  subtitulo: pedido.referencia.isNotEmpty ? pedido.referencia : null,
                  icono: Icons.location_on_rounded,
                ),

                const SizedBox(height: 12),

                _DetalleCard(
                  titulo: 'Método de pago',
                  contenido: _labelMetodoPago(pedido.metodoPago),
                  icono: Icons.payment_rounded,
                ),

                const SizedBox(height: 12),

                // ─── Resumen de productos ───
                _ResumenProductos(pedido: pedido),

                const SizedBox(height: 12),

                // ─── Total ───
                _TotalCard(pedido: pedido),

                const SizedBox(height: 20),

                if (pedido.estado == EstadoPedido.pendiente ||
                    pedido.estado == EstadoPedido.confirmado) ...[
                  OutlinedButton.icon(
                    onPressed: () => _cancelarPedido(context, pedido.id, deliveryService),
                    icon: const Icon(Icons.cancel_rounded, color: MinimarketTheme.error),
                    label: const Text(
                      'Cancelar pedido',
                      style: TextStyle(color: MinimarketTheme.error),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: MinimarketTheme.error),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }

  String _labelMetodoPago(String metodo) {
    switch (metodo) {
      case 'yape':
        return 'Yape / Plin';
      case 'tarjeta':
        return 'Tarjeta de crédito/débito';
      default:
        return 'Efectivo';
    }
  }

  Future<void> _cancelarPedido(
    BuildContext context,
    String id,
    DeliveryService service,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Cancelar pedido?'),
        content: const Text(
          'Esta acción no se puede deshacer. ¿Estás seguro de cancelar tu pedido?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No, mantener'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: MinimarketTheme.error),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );

    if (confirmar == true && context.mounted) {
      final ok = await service.cancelarPedido(id);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo cancelar el pedido')),
        );
      }
    }
  }
}

// ─── Widgets internos ───

class _EstadoHeader extends StatelessWidget {
  final Pedido pedido;

  const _EstadoHeader({required this.pedido});

  Color _colorEstado(EstadoPedido estado) {
    switch (estado) {
      case EstadoPedido.entregado:
        return MinimarketTheme.success;
      case EstadoPedido.cancelado:
        return MinimarketTheme.error;
      case EstadoPedido.enCamino:
        return MinimarketTheme.primaryYellowDark;
      default:
        return MinimarketTheme.secondaryNavy;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorEstado(pedido.estado);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            pedido.estado.icono,
            style: const TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 8),
          Text(
            pedido.estado.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            pedido.estado.descripcion,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _TimelineEstados extends StatelessWidget {
  final EstadoPedido estadoActual;

  const _TimelineEstados({required this.estadoActual});

  static const _pasos = [
    EstadoPedido.pendiente,
    EstadoPedido.confirmado,
    EstadoPedido.preparando,
    EstadoPedido.enCamino,
    EstadoPedido.entregado,
  ];

  int _indicePaso(EstadoPedido e) => _pasos.indexOf(e);

  @override
  Widget build(BuildContext context) {
    if (estadoActual == EstadoPedido.cancelado) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: MinimarketTheme.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: MinimarketTheme.error.withValues(alpha: 0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.cancel_rounded, color: MinimarketTheme.error),
            SizedBox(width: 8),
            Text(
              'Este pedido fue cancelado',
              style: TextStyle(color: MinimarketTheme.error, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    final indiceActual = _indicePaso(estadoActual);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: List.generate(_pasos.length, (i) {
            final paso = _pasos[i];
            final completado = i <= indiceActual;
            final esActual = i == indiceActual;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: completado
                            ? MinimarketTheme.secondaryNavy
                            : MinimarketTheme.divider,
                      ),
                      child: Center(
                        child: completado
                            ? (esActual
                                ? Text(
                                    paso.icono,
                                    style: const TextStyle(fontSize: 16),
                                  )
                                : const Icon(Icons.check_rounded,
                                    color: Colors.white, size: 18))
                            : Text(
                                '${i + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                    if (i < _pasos.length - 1)
                      Container(
                        width: 2,
                        height: 28,
                        color: i < indiceActual
                            ? MinimarketTheme.secondaryNavy
                            : MinimarketTheme.divider,
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          paso.label,
                          style: TextStyle(
                            fontWeight: esActual
                                ? FontWeight.w800
                                : FontWeight.w500,
                            fontSize: 14,
                            color: completado
                                ? MinimarketTheme.textPrimary
                                : MinimarketTheme.textSecondary,
                          ),
                        ),
                        if (esActual)
                          Text(
                            paso.descripcion,
                            style: const TextStyle(
                              fontSize: 12,
                              color: MinimarketTheme.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _DetalleCard extends StatelessWidget {
  final String titulo;
  final String contenido;
  final String? subtitulo;
  final IconData icono;

  const _DetalleCard({
    required this.titulo,
    required this.contenido,
    this.subtitulo,
    required this.icono,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icono, color: MinimarketTheme.secondaryNavy, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 12,
                      color: MinimarketTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    contenido,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: MinimarketTheme.textPrimary,
                    ),
                  ),
                  if (subtitulo != null)
                    Text(
                      subtitulo!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: MinimarketTheme.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResumenProductos extends StatelessWidget {
  final Pedido pedido;

  const _ResumenProductos({required this.pedido});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Productos',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: MinimarketTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            ...pedido.items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.nombre,
                        style: const TextStyle(
                            fontSize: 12, color: MinimarketTheme.textPrimary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      'x${item.cantidad}',
                      style: const TextStyle(
                          fontSize: 12, color: MinimarketTheme.textSecondary),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'S/ ${item.subtotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: MinimarketTheme.primaryYellowDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  final Pedido pedido;

  const _TotalCard({required this.pedido});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MinimarketTheme.secondaryNavy,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total pagado',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'S/ ${pedido.totalConDelivery.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: MinimarketTheme.primaryYellow,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (pedido.costoDelivery == 0)
                const Text(
                  'Delivery gratis ✓',
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
