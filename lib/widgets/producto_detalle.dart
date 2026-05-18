import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/producto.dart';

class ProductoDetalle extends StatefulWidget {
  final Producto producto;
  final Function(Producto producto, int cantidad)? onAgregarAlCarrito;

  const ProductoDetalle({
    super.key,
    required this.producto,
    this.onAgregarAlCarrito,
  });

  /// Muestra el bottom sheet de detalle del producto.
  static void mostrar(
    BuildContext context, {
    required Producto producto,
    required Function(Producto producto, int cantidad) onAgregarAlCarrito,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProductoDetalle(
        producto: producto,
        onAgregarAlCarrito: onAgregarAlCarrito,
      ),
    );
  }

  @override
  State<ProductoDetalle> createState() => _ProductoDetalleState();
}

class _ProductoDetalleState extends State<ProductoDetalle> {
  int _cantidad = 1;

  bool get _puedeAgregar => widget.producto.puedeAgregar;
  int get _maxStock => widget.producto.stock;

  @override
  Widget build(BuildContext context) {
    final producto = widget.producto;

    return Container(
      decoration: const BoxDecoration(
        color: MinimarketTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ─── Handle ───
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: MinimarketTheme.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Header: Categoría + Estado + Cerrar ───
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: MinimarketTheme.secondaryNavy
                            .withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        producto.categoria,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: MinimarketTheme.secondaryNavyLight,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildEstadoBadge(),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                        padding: const EdgeInsets.all(4),
                        minimumSize: const Size(32, 32),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ─── Nombre ───
                Text(
                  producto.nombre,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: MinimarketTheme.textPrimary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),

                // ─── Descripción ───
                Text(
                  producto.descripcion,
                  style: const TextStyle(
                    fontSize: 14,
                    color: MinimarketTheme.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),

                // ─── Info Grid ───
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: MinimarketTheme.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: MinimarketTheme.divider),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          Icons.monetization_on_rounded,
                          'Precio',
                          'S/ ${producto.precio.toStringAsFixed(2)}',
                          MinimarketTheme.primaryYellowDark,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: MinimarketTheme.divider,
                      ),
                      Expanded(
                        child: _buildInfoItem(
                          Icons.inventory_2_rounded,
                          'Stock',
                          '${producto.stock} unid.',
                          producto.stockBajo
                              ? MinimarketTheme.stockBajo
                              : producto.puedeAgregar
                                  ? MinimarketTheme.disponible
                                  : MinimarketTheme.sinStock,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: MinimarketTheme.divider,
                      ),
                      Expanded(
                        child: _buildInfoItem(
                          producto.disponible
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          'Estado',
                          producto.disponible ? 'Disponible' : 'No disponible',
                          producto.disponible
                              ? MinimarketTheme.disponible
                              : MinimarketTheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ─── Selector de Cantidad + Botón Agregar ───
                if (_puedeAgregar) ...[
                  Row(
                    children: [
                      // Selector de cantidad
                      const Text(
                        'Cantidad:',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: MinimarketTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: MinimarketTheme.secondaryNavy,
                              width: 1.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: _cantidad > 1
                                  ? () =>
                                      setState(() => _cantidad--)
                                  : null,
                              borderRadius: const BorderRadius.horizontal(
                                  left: Radius.circular(9)),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                child: Icon(Icons.remove,
                                    size: 20,
                                    color: _cantidad > 1
                                        ? MinimarketTheme.secondaryNavy
                                        : MinimarketTheme.divider),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 14),
                              child: Text(
                                '$_cantidad',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                  color: MinimarketTheme.secondaryNavy,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: _cantidad < _maxStock
                                  ? () =>
                                      setState(() => _cantidad++)
                                  : null,
                              borderRadius: const BorderRadius.horizontal(
                                  right: Radius.circular(9)),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                child: Icon(Icons.add,
                                    size: 20,
                                    color: _cantidad < _maxStock
                                        ? MinimarketTheme.secondaryNavy
                                        : MinimarketTheme.divider),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Subtotal
                      Text(
                        'S/ ${(producto.precio * _cantidad).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: MinimarketTheme.primaryYellowDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Botón agregar al carrito
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        widget.onAgregarAlCarrito?.call(producto, _cantidad);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle,
                                    color: MinimarketTheme.primaryYellow,
                                    size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '$_cantidad x ${producto.nombre} agregado al carrito',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_shopping_cart_rounded),
                      label: Text(
                          'Agregar $_cantidad al carrito'),
                    ),
                  ),
                ] else ...[
                  // Producto no disponible
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: MinimarketTheme.sinStock.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.remove_shopping_cart_outlined,
                            color: MinimarketTheme.sinStock),
                        SizedBox(width: 8),
                        Text(
                          'Producto no disponible',
                          style: TextStyle(
                            color: MinimarketTheme.sinStock,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(
      IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: MinimarketTheme.textSecondary)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEstadoBadge() {
    final producto = widget.producto;
    if (!producto.disponible || producto.stock <= 0) {
      return _badge('Sin Stock', MinimarketTheme.sinStock);
    }
    if (producto.stockBajo) {
      return _badge('Quedan ${producto.stock}', MinimarketTheme.stockBajo);
    }
    return _badge('Disponible', MinimarketTheme.disponible);
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
      ),
    );
  }
}
