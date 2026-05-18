import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/producto.dart';
import '../services/firestore_service.dart';
import '../widgets/producto_card.dart';
import '../widgets/categoria_chip.dart';
import '../widgets/producto_detalle.dart';

class ProductosScreen extends StatefulWidget {
  final Function(Producto, int cantidad) onAgregarAlCarrito;
  final int carritoCount;

  const ProductosScreen({
    super.key,
    required this.onAgregarAlCarrito,
    required this.carritoCount,
  });

  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();

  List<Producto> _productos = [];
  List<Producto> _productosFiltrados = [];
  List<String> _categorias = [];
  String? _categoriaSeleccionada;
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarProductos() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final productos = await _firestoreService.obtenerProductos();
      final categoriasSet = <String>{};
      for (final p in productos) {
        categoriasSet.add(p.categoria);
      }
      final categorias = categoriasSet.toList()..sort();

      setState(() {
        _productos = productos;
        _productosFiltrados = productos;
        _categorias = categorias;
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar productos: $e';
        _cargando = false;
      });
    }
  }

  void _filtrarProductos(String texto) {
    setState(() {
      _productosFiltrados = _productos.where((p) {
        final coincideTexto =
            p.nombre.toLowerCase().startsWith(texto.toLowerCase());
        final coincideCategoria = _categoriaSeleccionada == null ||
            p.categoria == _categoriaSeleccionada;
        return coincideTexto && coincideCategoria;
      }).toList();
    });
  }

  void _seleccionarCategoria(String? categoria) {
    setState(() {
      _categoriaSeleccionada =
          _categoriaSeleccionada == categoria ? null : categoria;
    });
    _filtrarProductos(_searchController.text);
  }

  void _agregarAlCarrito(Producto producto, [int cantidad = 1]) {
    widget.onAgregarAlCarrito(producto, cantidad);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: MinimarketTheme.primaryYellow,
                size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${cantidad > 1 ? '$cantidad x ' : ''}${producto.nombre} agregado al carrito',
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

  void _mostrarDetalle(Producto producto) {
    ProductoDetalle.mostrar(
      context,
      producto: producto,
      onAgregarAlCarrito: (p, cantidad) {
        _agregarAlCarrito(p, cantidad);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
                color: MinimarketTheme.secondaryNavy),
            SizedBox(height: 16),
            Text('Cargando productos...',
                style: TextStyle(color: MinimarketTheme.textSecondary)),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 64, color: MinimarketTheme.error),
              const SizedBox(height: 16),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style:
                      const TextStyle(color: MinimarketTheme.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _cargarProductos,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // ─── Barra de Búsqueda ───
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: TextField(
            controller: _searchController,
            onChanged: _filtrarProductos,
            decoration: const InputDecoration(
              labelText: 'Buscar producto...',
              prefixIcon: Icon(Icons.search),
              suffixIcon: Icon(Icons.filter_list_rounded),
            ),
          ),
        ),

        // ─── Chips de Categorías ───
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              CategoriaChip(
                label: 'Todos',
                selected: _categoriaSeleccionada == null,
                onSelected: (_) => _seleccionarCategoria(null),
              ),
              ..._categorias.map((cat) => CategoriaChip(
                    label: cat,
                    selected: _categoriaSeleccionada == cat,
                    onSelected: (_) => _seleccionarCategoria(cat),
                  )),
            ],
          ),
        ),
        const SizedBox(height: 4),

        // ─── Contador de Resultados ───
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                '${_productosFiltrados.length} productos',
                style: const TextStyle(
                  color: MinimarketTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                color: MinimarketTheme.secondaryNavy,
                onPressed: _cargarProductos,
                tooltip: 'Actualizar',
              ),
            ],
          ),
        ),

        // ─── Grid de Productos ───
        Expanded(
          child: _productosFiltrados.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off,
                          size: 64, color: MinimarketTheme.divider),
                      SizedBox(height: 12),
                      Text('No se encontraron productos',
                          style:
                              TextStyle(color: MinimarketTheme.textSecondary)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargarProductos,
                  color: MinimarketTheme.secondaryNavy,
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 80),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.78,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                    ),
                    itemCount: _productosFiltrados.length,
                    itemBuilder: (context, index) {
                      final producto = _productosFiltrados[index];
                      return ProductoCard(
                        producto: producto,
                        onTap: () => _mostrarDetalle(producto),
                        onAgregar: producto.puedeAgregar
                            ? () => _agregarAlCarrito(producto)
                            : null,
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
