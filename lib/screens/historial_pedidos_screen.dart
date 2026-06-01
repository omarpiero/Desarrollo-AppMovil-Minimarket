import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../config/theme.dart';
import '../models/pedido.dart';
import '../services/delivery_service.dart';
import 'seguimiento_screen.dart';
import 'login_screen.dart';

class HistorialPedidosScreen extends StatefulWidget {
  const HistorialPedidosScreen({super.key});

  @override
  State<HistorialPedidosScreen> createState() => _HistorialPedidosScreenState();
}

class _HistorialPedidosScreenState extends State<HistorialPedidosScreen> {
  final DeliveryService _service = DeliveryService();
  List<Pedido>? _pedidos;
  bool _cargando = true;
  String? _error;
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      _cargarPedidos();
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _cargarPedidos() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final pedidos = await _service.obtenerPedidosPorUsuario(user.uid);
        setState(() {
          _pedidos = pedidos;
          _cargando = false;
        });
      } else {
        setState(() {
          _pedidos = [];
          _cargando = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Pedidos'),
        actions: [
          if (user != null)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _cargarPedidos,
              tooltip: 'Actualizar',
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.moped_rounded,
                size: 80,
                color: MinimarketTheme.divider,
              ),
              const SizedBox(height: 16),
              const Text(
                'Inicia sesión para ver tus pedidos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: MinimarketTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Podrás realizar el seguimiento de tus compras y ver tu historial de pedidos.',
                style: TextStyle(
                  fontSize: 14,
                  color: MinimarketTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LoginScreen(),
                      ),
                    );
                  },
                  child: const Text('INICIAR SESIÓN'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: MinimarketTheme.error),
            const SizedBox(height: 12),
            Text('Error: $_error'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _cargarPedidos,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_pedidos == null || _pedidos!.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.moped_rounded, size: 80, color: MinimarketTheme.divider),
            SizedBox(height: 16),
            Text(
              'Aún no tienes pedidos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: MinimarketTheme.textSecondary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Haz tu primer pedido desde el carrito',
              style: TextStyle(color: MinimarketTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarPedidos,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _pedidos!.length,
        itemBuilder: (context, index) {
          final pedido = _pedidos![index];
          return _TarjetaPedido(
            pedido: pedido,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SeguimientoScreen(pedidoId: pedido.id),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TarjetaPedido extends StatelessWidget {
  final Pedido pedido;
  final VoidCallback onTap;

  const _TarjetaPedido({required this.pedido, required this.onTap});

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

  String _formatFecha(DateTime fecha) {
    final meses = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
    ];
    return '${fecha.day} ${meses[fecha.month - 1]} ${fecha.year}, ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorEstado(pedido.estado);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // ID del pedido
                  Expanded(
                    child: Text(
                      '#${pedido.id.substring(0, 8).toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: MinimarketTheme.textPrimary,
                      ),
                    ),
                  ),
                  // Badge de estado
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(pedido.estado.icono, style: const TextStyle(fontSize: 12)),
                        const SizedBox(width: 4),
                        Text(
                          pedido.estado.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Fecha
              Text(
                _formatFecha(pedido.creadoEn),
                style: const TextStyle(
                  fontSize: 12,
                  color: MinimarketTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),

              // Productos resumidos
              Text(
                pedido.items.map((i) => i.nombre.split(' ').take(3).join(' ')).join(', '),
                style: const TextStyle(
                  fontSize: 12,
                  color: MinimarketTheme.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const Divider(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${pedido.items.length} producto${pedido.items.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: MinimarketTheme.textSecondary,
                    ),
                  ),
                  Text(
                    'S/ ${pedido.totalConDelivery.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: MinimarketTheme.primaryYellowDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
