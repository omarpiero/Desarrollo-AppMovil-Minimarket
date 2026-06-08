import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/producto.dart';
import '../services/firestore_service.dart';
import '../widgets/producto_card.dart';
import '../widgets/producto_detalle.dart';

class OfertasScreen extends StatefulWidget {
  final Function(Producto, int cantidad) onAgregarAlCarrito;
  const OfertasScreen({super.key, required this.onAgregarAlCarrito});

  @override
  State<OfertasScreen> createState() => _OfertasScreenState();
}

class _OfertasScreenState extends State<OfertasScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  void _mostrarDetalle(Producto producto) {
    ProductoDetalle.mostrar(
      context,
      producto: producto,
      onAgregarAlCarrito: (p, cantidad) {
        widget.onAgregarAlCarrito(p, cantidad);
      },
    );
  }

  void _agregarAlCarrito(Producto producto) {
    widget.onAgregarAlCarrito(producto, 1);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 120,
          left: 16,
          right: 16,
        ),
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: MinimarketTheme.primaryYellow, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${producto.nombre} agregado al carrito',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ofertas Wisa de la Semana'),
      ),
      body: StreamBuilder<List<Producto>>(
        stream: _firestoreService.streamOfertas(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: MinimarketTheme.primaryRed),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'Error al cargar ofertas: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: MinimarketTheme.textSecondary),
                ),
              ),
            );
          }

          final ofertas = snapshot.data ?? [];

          if (ofertas.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.discount_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'No hay ofertas activas en este momento.',
                    style: TextStyle(color: MinimarketTheme.textSecondary),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Container(
                width: double.infinity,
                color: MinimarketTheme.primaryYellowSurface,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.flash_on_rounded, color: MinimarketTheme.primaryYellowDark, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '¡Aprovecha 20% de descuento en productos seleccionados!',
                        style: TextStyle(
                          color: Colors.amber.shade900,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.68,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: ofertas.length,
                  itemBuilder: (context, index) {
                    final producto = ofertas[index];
                    return ProductoCard(
                      producto: producto,
                      onTap: () => _mostrarDetalle(producto),
                      onAgregar: producto.puedeAgregar ? () => _agregarAlCarrito(producto) : null,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
