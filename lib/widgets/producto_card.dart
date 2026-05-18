import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/producto.dart';

class ProductoCard extends StatelessWidget {
  final Producto producto;
  final VoidCallback? onAgregar;
  final VoidCallback? onTap;

  const ProductoCard({
    super.key,
    required this.producto,
    this.onAgregar,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool activo = producto.puedeAgregar;

    return Opacity(
      opacity: activo ? 1.0 : 0.55,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Categoría + Estado ───
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: MinimarketTheme.secondaryNavy
                              .withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          producto.categoria,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: MinimarketTheme.secondaryNavyLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    _buildEstadoBadge(),
                  ],
                ),
                const SizedBox(height: 8),

                // ─── Nombre ───
                Text(
                  producto.nombre,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: MinimarketTheme.textPrimary,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),

                // ─── Precio + Botón ───
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Precio
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: MinimarketTheme.primaryYellowSurface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'S/ ${producto.precio.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: MinimarketTheme.primaryYellowDark,
                        ),
                      ),
                    ),
                    // Botón agregar
                    if (activo)
                      Material(
                        color: MinimarketTheme.primaryYellow,
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: onAgregar,
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(
                              Icons.add_shopping_cart_rounded,
                              size: 20,
                              color: MinimarketTheme.secondaryNavy,
                            ),
                          ),
                        ),
                      )
                    else
                      const Icon(
                        Icons.remove_shopping_cart_outlined,
                        size: 20,
                        color: MinimarketTheme.sinStock,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEstadoBadge() {
    if (!producto.disponible || producto.stock <= 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: MinimarketTheme.sinStock,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'Sin Stock',
          style: TextStyle(
              fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white),
        ),
      );
    }
    if (producto.stockBajo) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: MinimarketTheme.stockBajo,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          'Quedan ${producto.stock}',
          style: const TextStyle(
              fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: MinimarketTheme.disponible,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'Disponible',
        style: TextStyle(
            fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white),
      ),
    );
  }
}
