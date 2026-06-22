import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/theme.dart';
import '../models/pedido.dart';
import '../services/delivery_service.dart';
import 'home_screen.dart';

class SeguimientoScreen extends StatefulWidget {
  final String pedidoId;

  const SeguimientoScreen({super.key, required this.pedidoId});

  @override
  State<SeguimientoScreen> createState() => _SeguimientoScreenState();
}

class _SeguimientoScreenState extends State<SeguimientoScreen> {
  Timer? _timer;
  late final Stream<Pedido?> _pedidoStream;
  final DeliveryService _deliveryService = DeliveryService();

  @override
  void initState() {
    super.initState();
    _pedidoStream = _deliveryService.streamPedido(widget.pedidoId);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seguimiento de Pedido'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton.icon(
            onPressed: () {
              HomeScreen.selectTab(0);
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
            icon: const Icon(Icons.home_rounded, color: MinimarketTheme.primaryYellow),
            label: const Text(
              'Inicio',
              style: TextStyle(color: MinimarketTheme.primaryYellow),
            ),
          ),
        ],
      ),
      body: StreamBuilder<Pedido?>(
        stream: _pedidoStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Text('No se pudo cargar el pedido o ha sido eliminado'),
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

                if (pedido.tiendaNombre != null) ...[
                  _RutaDeliveryCard(pedido: pedido),
                  const SizedBox(height: 12),
                ],

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

                if (pedido.estado == EstadoPedido.pendiente) ...[
                  Builder(
                    builder: (context) {
                      final diffInSecs = DateTime.now().difference(pedido.creadoEn).inSeconds;
                      final remainingSecs = 300 - diffInSecs;
                      if (remainingSecs <= 0) {
                        return const SizedBox.shrink();
                      }
                      
                      final mins = remainingSecs ~/ 60;
                      final secs = remainingSecs % 60;
                      final timeString = '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _cancelarPedido(context, pedido.id, _deliveryService),
                            icon: const Icon(Icons.cancel_rounded, color: MinimarketTheme.error),
                            label: Text(
                              'Cancelar pedido ($timeString)',
                              style: const TextStyle(color: MinimarketTheme.error),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: MinimarketTheme.error),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      );
                    }
                  ),
                ],

                if (pedido.estado == EstadoPedido.cancelado ||
                    pedido.estado == EstadoPedido.entregado) ...[
                  ElevatedButton.icon(
                    onPressed: () => _eliminarPedido(context, pedido.id, _deliveryService),
                    icon: const Icon(Icons.delete_forever_rounded, color: Colors.white),
                    label: Text(
                      pedido.estado == EstadoPedido.entregado
                          ? 'QUITAR PEDIDO DE MI HISTORIAL'
                          : 'ELIMINAR REGISTRO DE PEDIDO',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MinimarketTheme.error,
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
          const SnackBar(
            content: Text('No se pudo cancelar el pedido. Puede haber expirado el tiempo de 5 minutos.'),
            backgroundColor: MinimarketTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _eliminarPedido(
    BuildContext context,
    String id,
    DeliveryService service,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Quitar pedido del historial?'),
        content: const Text(
          'Esta acción ocultará el pedido de tu historial en la aplicación. Seguirá registrado de forma interna en nuestro sistema para fines administrativos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: MinimarketTheme.error),
            child: const Text('Sí, quitar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar == true && context.mounted) {
      final ok = await service.eliminarPedido(id);
      if (ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🗑️ Pedido quitado del historial.'),
            backgroundColor: MinimarketTheme.primaryRed,
          ),
        );
        HomeScreen.selectTab(0);
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo quitar el pedido.'),
            backgroundColor: MinimarketTheme.error,
          ),
        );
      }
    }
  }
}

Future<void> _abrirRutaPedido(BuildContext context, Pedido pedido) async {
  final tiendaLat = pedido.tiendaLatitud;
  final tiendaLng = pedido.tiendaLongitud;
  final clienteLat = pedido.clienteLatitud;
  final clienteLng = pedido.clienteLongitud;

  if (tiendaLat == null ||
      tiendaLng == null ||
      clienteLat == null ||
      clienteLng == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Este pedido no tiene coordenadas de ruta guardadas.'),
        backgroundColor: MinimarketTheme.error,
      ),
    );
    return;
  }

  final uri = Uri.https('www.google.com', '/maps/dir/', {
    'api': '1',
    'origin': '$tiendaLat,$tiendaLng',
    'destination': '$clienteLat,$clienteLng',
    'travelmode': 'driving',
  });

  if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
      context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No se pudo abrir la ruta en Google Maps.'),
        backgroundColor: MinimarketTheme.error,
      ),
    );
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
        return MinimarketTheme.primaryRed;
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
                            ? MinimarketTheme.primaryRed
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
                            ? MinimarketTheme.primaryRed
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
            Icon(icono, color: MinimarketTheme.primaryRed, size: 22),
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

class _RutaDeliveryCard extends StatelessWidget {
  final Pedido pedido;

  const _RutaDeliveryCard({required this.pedido});

  @override
  Widget build(BuildContext context) {
    final distancia = pedido.distanciaRutaTexto;
    final duracion = pedido.duracionRutaTexto;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.store_mall_directory_rounded,
                  color: MinimarketTheme.primaryRed,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tienda asignada',
                        style: TextStyle(
                          fontSize: 12,
                          color: MinimarketTheme.textSecondary,
                        ),
                      ),
                      Text(
                        pedido.tiendaNombre ?? 'Tienda Wisa',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: MinimarketTheme.textPrimary,
                        ),
                      ),
                      if (pedido.tiendaDireccion != null)
                        Text(
                          pedido.tiendaDireccion!,
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
            if (distancia != null || duracion != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  if (distancia != null)
                    Expanded(
                      child: _RutaInfo(
                        icono: Icons.route_rounded,
                        etiqueta: 'Distancia',
                        valor: distancia,
                      ),
                    ),
                  if (distancia != null && duracion != null)
                    const SizedBox(width: 10),
                  if (duracion != null)
                    Expanded(
                      child: _RutaInfo(
                        icono: Icons.schedule_rounded,
                        etiqueta: 'Tiempo',
                        valor: duracion,
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _abrirRutaPedido(context, pedido),
                icon: const Icon(Icons.map_rounded),
                label: const Text('Ver ruta en Google Maps'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RutaInfo extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final String valor;

  const _RutaInfo({
    required this.icono,
    required this.etiqueta,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: MinimarketTheme.primaryYellowSurface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icono, color: MinimarketTheme.secondaryNavy, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  etiqueta,
                  style: const TextStyle(
                    fontSize: 11,
                    color: MinimarketTheme.textSecondary,
                  ),
                ),
                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: MinimarketTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
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
        color: MinimarketTheme.primaryRed,
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
