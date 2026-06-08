
// lib/screens/checkout_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../config/theme.dart';
import '../models/pedido.dart';
import '../models/producto.dart';
import '../services/delivery_service.dart';
import '../utils/geo_utils.dart';
import '../widgets/producto_imagen.dart';
import 'seguimiento_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final List<Map<String, dynamic>> carrito;
  final VoidCallback onPedidoConfirmado;

  const CheckoutScreen({
    super.key,
    required this.carrito,
    required this.onPedidoConfirmado,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();
  final _referenciaController = TextEditingController();
  final _notasController = TextEditingController();

  String _metodoPago = 'efectivo';
  bool _enviando = false;

  int _puntosDisponibles = 0;
  bool _aplicarDescuento = false;
  final double _conversionPuntosASoles = 100.0; // 1 punto = S/ 0.01
  final double _puntosPorSolGanado = 1.0;      

  final DeliveryService _deliveryService = DeliveryService();
  double? _latitudUsuario;
  double? _longitudUsuario;
  double _distanciaTiendaKm = 0.0;
  bool _cargandoDistancia = false;

  @override
  void initState() {
    super.initState();
    _cargarPuntosUsuario();
  }

  Future<void> _cargarPuntosUsuario() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('usuarios')
            .where('uid', isEqualTo: user.uid)
            .limit(1)
            .get();
        if (querySnapshot.docs.isNotEmpty) {
          final userDoc = querySnapshot.docs.first;
          final data = userDoc.data();
          setState(() {
            _puntosDisponibles = data['puntosAcumulados'] ?? 0;
            _latitudUsuario = (data['latitud'] as num?)?.toDouble();
            _longitudUsuario = (data['longitud'] as num?)?.toDouble();
            
            if (_nombreController.text.isEmpty) {
              _nombreController.text = data['nombreCompleto'] ?? '';
            }
            if (_telefonoController.text.isEmpty) {
              _telefonoController.text = data['telefono'] ?? '';
            }
            if (_direccionController.text.isEmpty) {
              _direccionController.text = data['direccion'] ?? '';
            }
            if (_referenciaController.text.isEmpty) {
              _referenciaController.text = data['referencia'] ?? '';
            }
          });
          await _calcularDistancia();
        }
      }
    } catch (e) {
      debugPrint('Error al cargar puntos: $e');
    }
  }

  Future<void> _calcularDistancia() async {
    double? lat = _latitudUsuario;
    double? lng = _longitudUsuario;
    
    if (lat == null || lng == null) {
      setState(() => _cargandoDistancia = true);
      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 5),
          ),
        );
        lat = position.latitude;
        lng = position.longitude;
      } catch (e) {
        debugPrint('No se pudo obtener ubicación en tiempo real: $e');
      } finally {
        setState(() => _cargandoDistancia = false);
      }
    }
    
    if (lat != null && lng != null) {
      final userLoc = LatLng(lat, lng);
      final tienda = tiendaMasCercanaHuancayo(userLoc);
      final distMetros = distanciaMetros(userLoc, tienda.ubicacion);
      setState(() {
        _distanciaTiendaKm = distMetros / 1000.0;
      });
    } else {
      setState(() {
        _distanciaTiendaKm = 2.0;
      });
    }
  }

  double get _subtotal {
    double total = 0;
    for (final item in widget.carrito) {
      final producto = item['producto'] as Producto;
      total += producto.precio * (item['cantidad'] as int);
    }
    return total;
  }

  double get _porcentajeDescuentoRango {
    if (_puntosDisponibles >= 150) return 0.10;
    if (_puntosDisponibles >= 50) return 0.05;
    return 0.0;
  }

  double get _descuentoRangoSoles {
    return _subtotal * _porcentajeDescuentoRango;
  }

  double get _subtotalConDescuentoRango {
    final res = _subtotal - _descuentoRangoSoles;
    return res < 0 ? 0.0 : res;
  }

  double get _costoDelivery {
    return DeliveryService.calcularCostoDelivery(
      distanciaKm: _distanciaTiendaKm,
      puntosUsuario: _puntosDisponibles,
      totalProductos: _subtotalConDescuentoRango,
    );
  }
  
  int get _puntosAUtilizar {
    if (!_aplicarDescuento) return 0;
    
    double totalMaximo = _subtotalConDescuentoRango + _costoDelivery;
    int puntosEquivalentes = (totalMaximo * _conversionPuntosASoles).toInt();
    
    if (_puntosDisponibles > puntosEquivalentes) {
      return puntosEquivalentes;
    }
    return _puntosDisponibles;
  }

  double get _descuentoPuntosSoles {
    return _puntosAUtilizar / _conversionPuntosASoles;
  }

  int get _puntosAGanar {
    double subtotalFinal = _subtotalConDescuentoRango - _descuentoPuntosSoles;
    if (subtotalFinal < 0) subtotalFinal = 0;
    return (subtotalFinal * _puntosPorSolGanado).toInt();
  }

  double get _total {
    double resultado = (_subtotalConDescuentoRango + _costoDelivery) - _descuentoPuntosSoles;
    return resultado < 0 ? 0.0 : resultado;
  }

  String _obtenerRango(int puntos) {
    if (puntos < 50) return 'Vecino';
    if (puntos < 150) return 'Amigo de la casa';
    return 'El Caserito';
  }

  Future<void> _mostrarAlertaNivelUp(String anterior, String nuevo) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.stars_rounded, color: MinimarketTheme.primaryYellow, size: 28),
              SizedBox(width: 8),
              Text('¡Felicidades!', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '¡Has subido de nivel en el Club Caserito!',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(anterior, style: const TextStyle(color: Colors.grey, decoration: TextDecoration.lineThrough)),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, color: MinimarketTheme.primaryRed),
                  const SizedBox(width: 8),
                  Text(nuevo, style: const TextStyle(color: MinimarketTheme.primaryRed, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Ahora disfruta de mayores descuentos en tus productos y delivery.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: MinimarketTheme.textSecondary),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('¡ESTUPENDO!'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    _referenciaController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  Future<void> _confirmarPedido() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _enviando = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid ?? 'anonimo';

      final items = widget.carrito.map((item) {
        final producto = item['producto'] as Producto;
        final cantidad = item['cantidad'] as int;
        return ItemPedido.fromProducto(producto, cantidad);
      }).toList();

      final pedido = Pedido(
        id: '',
        userId: userId, 
        items: items,
        nombreCliente: _nombreController.text.trim(),
        telefono: _telefonoController.text.trim(),
        direccionEntrega: _direccionController.text.trim(),
        referencia: _referenciaController.text.trim(),
        metodoPago: _metodoPago,
        total: _subtotalConDescuentoRango,
        costoDelivery: _costoDelivery,
        descuentoAplicado: _descuentoPuntosSoles + _descuentoRangoSoles, 
        puntosUtilizados: _puntosAUtilizar,   
        puntosGanados: _puntosAGanar,         
        estado: EstadoPedido.pendiente,
        creadoEn: DateTime.now(),
        notasAdicionales: _notasController.text.trim().isEmpty
            ? null
            : _notasController.text.trim(),
      );

      final pedidoId = await _deliveryService.crearPedido(pedido);

      if (user != null) {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('usuarios')
            .where('uid', isEqualTo: user.uid)
            .limit(1)
            .get();
        if (querySnapshot.docs.isNotEmpty) {
          final userDoc = querySnapshot.docs.first;
          final userRef = userDoc.reference;
          final dni = userDoc.id;

          final int puntosAnteriores = userDoc.data()['puntosAcumulados'] ?? 0;
          final rangoAnterior = _obtenerRango(puntosAnteriores);

          await FirebaseFirestore.instance.runTransaction((transaction) async {
            // 1. Ejecutar todos los READS primero
            final userSnapshot = await transaction.get(userRef);
            
            final List<DocumentSnapshot<Map<String, dynamic>>> prodSnapshots = [];
            final List<DocumentReference<Map<String, dynamic>>> prodRefs = [];
            for (final item in widget.carrito) {
              final prod = item['producto'] as Producto;
              final prodRef = FirebaseFirestore.instance.collection('productos').doc(prod.id);
              final prodSnapshot = await transaction.get(prodRef);
              prodSnapshots.add(prodSnapshot);
              prodRefs.add(prodRef);
            }

            // 2. Ejecutar todos los WRITES después
            if (userSnapshot.exists) {
              int puntosActuales = userSnapshot.data()?['puntosAcumulados'] ?? 0;
              int nuevosPuntos = puntosActuales - _puntosAUtilizar + _puntosAGanar;
              if (nuevosPuntos < 0) nuevosPuntos = 0;
              
              transaction.update(userRef, {'puntosAcumulados': nuevosPuntos});
            }

            for (int i = 0; i < widget.carrito.length; i++) {
              final item = widget.carrito[i];
              final cant = item['cantidad'] as int;
              final prodRef = prodRefs[i];
              final prodSnapshot = prodSnapshots[i];

              if (prodSnapshot.exists) {
                int stockActual = (prodSnapshot.data()?['stock'] ?? 0).toInt();
                int nuevoStock = stockActual - cant;
                if (nuevoStock < 0) nuevoStock = 0;
                bool disponible = nuevoStock > 0;
                
                transaction.update(prodRef, {
                  'stock': nuevoStock,
                  'disponible': disponible,
                });
              }
            }
          });

          if (_puntosAUtilizar > 0) {
            await FirebaseFirestore.instance
                .collection('usuarios')
                .doc(dni)
                .collection('historialPuntos')
                .add({
              'puntos': _puntosAUtilizar,
              'tipo': 'canjeado',
              'motivo': 'Canje por descuento en pedido $pedidoId',
              'fecha': Timestamp.fromDate(DateTime.now()),
            });
          }
          if (_puntosAGanar > 0) {
            await FirebaseFirestore.instance
                .collection('usuarios')
                .doc(dni)
                .collection('historialPuntos')
                .add({
              'puntos': _puntosAGanar,
              'tipo': 'ganado',
              'motivo': 'Puntos ganados por pedido $pedidoId',
              'fecha': Timestamp.fromDate(DateTime.now()),
            });
          }

          final int puntosNuevos = puntosAnteriores - _puntosAUtilizar + _puntosAGanar;
          final rangoNuevo = _obtenerRango(puntosNuevos);
          if (rangoNuevo != rangoAnterior) {
            await _mostrarAlertaNivelUp(rangoAnterior, rangoNuevo);
          }
        }
      }

      if (!mounted) return;
      widget.onPedidoConfirmado();

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => SeguimientoScreen(pedidoId: pedidoId),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al enviar el pedido: $e'),
          backgroundColor: MinimarketTheme.error,
        ),
      );
    } finally { 
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmar Pedido'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionTitle(title: 'Resumen del pedido', icon: Icons.receipt_rounded),
            const SizedBox(height: 8),
            ...widget.carrito.map((item) {
              final producto = item['producto'] as Producto;
              final cantidad = item['cantidad'] as int;
              return _ItemResumen(
                producto: producto,
                cantidad: cantidad,
              );
            }),

            const SizedBox(height: 16),

            if (_puntosDisponibles >= 20) ...[
              _SectionTitle(title: 'Club Caserito', icon: Icons.stars_rounded),
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: MinimarketTheme.primaryYellow),
                ),
                color: MinimarketTheme.primaryYellowSurface.withValues(alpha: 0.4),
                child: SwitchListTile(
                  title: const Text(
                    '¿Usar tus puntos?',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: MinimarketTheme.primaryRed,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    'Tienes $_puntosDisponibles puntos.\nCanjea $_puntosAUtilizar puntos por un dscto. de S/ ${_descuentoPuntosSoles.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 12, color: MinimarketTheme.textSecondary),
                  ),
                  isThreeLine: true,
                  value: _aplicarDescuento,
                  activeColor: MinimarketTheme.primaryRed,
                  onChanged: (bool value) {
                    setState(() {
                      _aplicarDescuento = value;
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (_cargandoDistancia) ...[
              const Padding(
                padding: EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 1.5, color: MinimarketTheme.primaryRed),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Calculando costo de envío por distancia...',
                      style: TextStyle(fontSize: 12, color: MinimarketTheme.textSecondary, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
            _TotalesCard(
              subtotal: _subtotal,
              costoDelivery: _costoDelivery,
              descuentoPuntos: _descuentoPuntosSoles, 
              descuentoNivel: _descuentoRangoSoles,
              puntosAGanar: _puntosAGanar, 
              total: _total,
              distanciaKm: _distanciaTiendaKm,
            ),

            const SizedBox(height: 20),

            _SectionTitle(title: 'Datos de entrega', icon: Icons.location_on_rounded),
            const SizedBox(height: 12),

            _CampoTexto(
              controller: _nombreController,
              label: 'Nombre completo',
              icono: Icons.person_rounded,
              validador: (v) =>
                  v == null || v.trim().isEmpty ? 'Ingresa tu nombre' : null,
            ),
            const SizedBox(height: 12),

            _CampoTexto(
              controller: _telefonoController,
              label: 'Teléfono de contacto',
              icono: Icons.phone_rounded,
              teclado: TextInputType.phone,
              validador: (v) {
                if (v == null || v.trim().isEmpty) return 'Ingresa tu teléfono';
                if (v.trim().length < 9) return 'Teléfono inválido';
                return null;
              },
            ),
            const SizedBox(height: 12),

            _CampoTexto(
              controller: _direccionController,
              label: 'Dirección de entrega',
              icono: Icons.home_rounded,
              maxLineas: 2,
              validador: (v) =>
                  v == null || v.trim().isEmpty ? 'Ingresa tu dirección' : null,
            ),
            const SizedBox(height: 12),

            _CampoTexto(
              controller: _referenciaController,
              label: 'Referencia (ej: frente al parque)',
              icono: Icons.location_searching_rounded,
              validador: null,
            ),
            const SizedBox(height: 12),

            _CampoTexto(
              controller: _notasController,
              label: 'Notas adicionales (opcional)',
              icono: Icons.note_rounded,
              maxLineas: 2,
              validador: null,
            ),

            const SizedBox(height: 20),

            _SectionTitle(title: 'Método de pago', icon: Icons.payment_rounded),
            const SizedBox(height: 12),

            _MetodoPagoSelector(
              seleccionado: _metodoPago,
              onCambio: (v) => setState(() => _metodoPago = v),
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _enviando ? null : _confirmarPedido,
                icon: _enviando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: MinimarketTheme.primaryRed,
                        ),
                      )
                    : const Icon(Icons.check_circle_rounded),
                label: Text(
                  _enviando ? 'Enviando pedido...' : 'Confirmar Pedido • S/ ${_total.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: MinimarketTheme.primaryRed, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: MinimarketTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _ItemResumen extends StatelessWidget {
  final Producto producto;
  final int cantidad;

  const _ItemResumen({required this.producto, required this.cantidad});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          ProductoImagen(
            imagenUrl: producto.imagenUrl,
            width: 40,
            height: 40,
            borderRadius: 8,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              producto.nombre,
              style: const TextStyle(fontSize: 12, color: MinimarketTheme.textPrimary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'x$cantidad',
            style: const TextStyle(
              fontSize: 12,
              color: MinimarketTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'S/ ${(producto.precio * cantidad).toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: MinimarketTheme.primaryYellowDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalesCard extends StatelessWidget {
  final double subtotal;
  final double costoDelivery;
  final double descuentoPuntos;
  final double descuentoNivel;
  final int puntosAGanar;
  final double total;
  final double distanciaKm;

  const _TotalesCard({
    required this.subtotal,
    required this.costoDelivery,
    required this.descuentoPuntos,
    required this.descuentoNivel,
    required this.puntosAGanar,
    required this.total,
    required this.distanciaKm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MinimarketTheme.primaryYellowSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MinimarketTheme.primaryYellow),
      ),
      child: Column(
        children: [
          _FilaTotal('Subtotal', 'S/ ${subtotal.toStringAsFixed(2)}'),
          
          if (descuentoNivel > 0) ...[
            const SizedBox(height: 6),
            _FilaTotal(
              'Descuento por Nivel',
              '- S/ ${descuentoNivel.toStringAsFixed(2)}',
              valorColor: MinimarketTheme.error,
            ),
          ],
          
          const SizedBox(height: 6),
          _FilaTotal(
            'Delivery (${distanciaKm.toStringAsFixed(1)} km)',
            costoDelivery == 0 ? '¡Gratis!' : 'S/ ${costoDelivery.toStringAsFixed(2)}',
            valorColor: costoDelivery == 0 ? MinimarketTheme.success : null,
          ),
          
          if (descuentoPuntos > 0) ...[
            const SizedBox(height: 6),
            _FilaTotal(
              'Descuento por Puntos', 
              '- S/ ${descuentoPuntos.toStringAsFixed(2)}',
              valorColor: MinimarketTheme.error,
            ),
          ],
          
          const Divider(height: 16),
          _FilaTotal(
            'Total',
            'S/ ${total.toStringAsFixed(2)}',
            etiquetaNegrita: true,
            valorColor: MinimarketTheme.primaryRed,
            fontSize: 16,
          ),
          
          if (puntosAGanar > 0) ...[
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_circle_outline_rounded, size: 16, color: MinimarketTheme.success),
                const SizedBox(width: 4),
                Text(
                  '¡Ganarás $puntosAGanar puntos con esta compra!',
                  style: const TextStyle(
                    fontSize: 12, 
                    fontWeight: FontWeight.w600, 
                    color: MinimarketTheme.success
                  ),
                ),
              ],
            )
          ]
        ],
      ),
    );
  }
}

class _FilaTotal extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final bool etiquetaNegrita;
  final Color? valorColor;
  final double fontSize;

  const _FilaTotal(
    this.etiqueta,
    this.valor, {
    this.etiquetaNegrita = false,
    this.valorColor,
    this.fontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          etiqueta,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: etiquetaNegrita ? FontWeight.w700 : FontWeight.normal,
            color: MinimarketTheme.textPrimary,
          ),
        ),
        Text(
          valor,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: valorColor ?? MinimarketTheme.primaryYellowDark,
          ),
        ),
      ],
    );
  }
}

class _CampoTexto extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icono;
  final TextInputType teclado;
  final int maxLineas;
  final String? Function(String?)? validador;

  const _CampoTexto({
    required this.controller,
    required this.label,
    required this.icono,
    this.teclado = TextInputType.text,
    this.maxLineas = 1,
    required this.validador,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: teclado,
      maxLines: maxLineas,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icono),
      ),
      validator: validador,
    );
  }
}

class _MetodoPagoSelector extends StatelessWidget {
  final String seleccionado;
  final ValueChanged<String> onCambio;

  const _MetodoPagoSelector({
    required this.seleccionado,
    required this.onCambio,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _OpcionPago(
            titulo: 'Efectivo',
            icono: Icons.payments_rounded,
            valor: 'efectivo',
            seleccionado: seleccionado == 'efectivo',
            onTap: () => onCambio('efectivo'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _OpcionPago(
            titulo: 'Yape / Plin',
            icono: Icons.phone_android_rounded,
            valor: 'yape',
            seleccionado: seleccionado == 'yape',
            onTap: () => onCambio('yape'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _OpcionPago(
            titulo: 'Tarjeta',
            icono: Icons.credit_card_rounded,
            valor: 'tarjeta',
            seleccionado: seleccionado == 'tarjeta',
            onTap: () => onCambio('tarjeta'),
          ),
        ),
      ],
    );
  }
}

class _OpcionPago extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final String valor;
  final bool seleccionado;
  final VoidCallback onTap;

  const _OpcionPago({
    required this.titulo,
    required this.icono,
    required this.valor,
    required this.seleccionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: seleccionado
              ? MinimarketTheme.primaryRed
              : MinimarketTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: seleccionado
                ? MinimarketTheme.primaryRed
                : MinimarketTheme.divider,
            width: seleccionado ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icono,
              color: seleccionado ? MinimarketTheme.primaryYellow : MinimarketTheme.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              titulo,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: seleccionado ? Colors.white : MinimarketTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}