import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/producto.dart';
import '../widgets/producto_imagen.dart';

class CarritoScreen extends StatelessWidget {
  final List<Map<String, dynamic>> carrito;
  final Function(int index) onEliminar;
  final Function(int index, int cantidad) onCambiarCantidad;

  const CarritoScreen({
    super.key,
    required this.carrito,
    required this.onEliminar,
    required this.onCambiarCantidad,
  });

  double get _total {
    double total = 0;
    for (final item in carrito) {
      final producto = item['producto'] as Producto;
      final cantidad = item['cantidad'] as int;
      total += producto.precio * cantidad;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    if (carrito.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined,
                size: 80, color: MinimarketTheme.divider),
            SizedBox(height: 16),
            Text(
              'Tu carrito está vacío',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: MinimarketTheme.textSecondary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Agrega productos desde el catálogo',
              style: TextStyle(
                fontSize: 14,
                color: MinimarketTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // ─── Lista de Items ───
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            itemCount: carrito.length,
            itemBuilder: (context, index) {
              final item = carrito[index];
              final producto = item['producto'] as Producto;
              final cantidad = item['cantidad'] as int;

              return Dismissible(
                key: ValueKey('${producto.id}_$index'),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => onEliminar(index),
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: MinimarketTheme.error,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete_rounded,
                      color: Colors.white, size: 28),
                ),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // Imagen del producto
                        ProductoImagen(
                          imagenUrl: producto.imagenUrl,
                          width: 48,
                          height: 48,
                          borderRadius: 10,
                        ),
                        const SizedBox(width: 12),

                        // Nombre y precio unitario
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                producto.nombre,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: MinimarketTheme.textPrimary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'S/ ${producto.precio.toStringAsFixed(2)} c/u',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: MinimarketTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Controles de cantidad
                        Container(
                          decoration: BoxDecoration(
                            border:
                                Border.all(color: MinimarketTheme.divider),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: () => onCambiarCantidad(
                                    index, cantidad - 1),
                                borderRadius: const BorderRadius.horizontal(
                                    left: Radius.circular(8)),
                                child: const Padding(
                                  padding: EdgeInsets.all(6),
                                  child: Icon(Icons.remove, size: 18,
                                      color: MinimarketTheme.secondaryNavy),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10),
                                child: Text(
                                  '$cantidad',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: MinimarketTheme.secondaryNavy,
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () => onCambiarCantidad(
                                    index, cantidad + 1),
                                borderRadius: const BorderRadius.horizontal(
                                    right: Radius.circular(8)),
                                child: const Padding(
                                  padding: EdgeInsets.all(6),
                                  child: Icon(Icons.add, size: 18,
                                      color: MinimarketTheme.secondaryNavy),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Subtotal
                        Text(
                          'S/ ${(producto.precio * cantidad).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: MinimarketTheme.primaryYellowDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // ─── Barra Total ───
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: MinimarketTheme.secondaryNavy,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: MinimarketTheme.secondaryNavy.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      'S/ ${_total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: MinimarketTheme.primaryYellow,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${carrito.length} item${carrito.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
