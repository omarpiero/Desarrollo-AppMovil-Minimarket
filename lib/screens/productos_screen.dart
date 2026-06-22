// lib/screens/productos_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/producto.dart';
import '../services/firestore_service.dart';
import '../widgets/producto_card.dart';
import '../widgets/categoria_chip.dart';
import '../widgets/producto_detalle.dart';
import 'ofertas_screen.dart';

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

  // Categorías jerárquicas
  List<String> _categoriasPrincipales = [];
  String? _categoriaPrincipalSeleccionada;
  List<String> _subcategorias = [];
  String? _subcategoriaSeleccionada;

  bool _cargando = true;
  String? _error;

  StreamSubscription<List<Producto>>? _productosSub;
  DateTime? _lastUpdate;



  @override
  void initState() {
    super.initState();
    _iniciarEscuchaProductos();
  }

  @override
  void dispose() {
    _productosSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// Extrae la categoría principal (parte antes de " / ")
  static String _categoriaPrincipal(String categoria) {
    final parts = categoria.split(' / ');
    return parts.first.trim();
  }

  /// Extrae la subcategoría (parte después de " / "), o null si no hay
  static String? _subcategoria(String categoria) {
    final parts = categoria.split(' / ');
    if (parts.length > 1) {
      return parts.sublist(1).join(' / ').trim();
    }
    return null;
  }

  void _iniciarEscuchaProductos() {
    setState(() {
      _cargando = true;
      _error = null;
    });
    _productosSub = _firestoreService.streamProductos().listen((productos) {
      if (mounted) {
        setState(() {
          _productos = productos;

          // Extraer categorías principales únicas
          final principalesSet = <String>{};
          for (final p in productos) {
            principalesSet.add(_categoriaPrincipal(p.categoria));
          }
          _categoriasPrincipales = principalesSet.toList()..sort();

          // Actualizar subcategorías si hay principal seleccionada
          _actualizarSubcategorias();

          _filtrarProductos(_searchController.text);
          _lastUpdate = DateTime.now();
          _cargando = false;
        });
      }
    }, onError: (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al cargar productos: $e';
          _cargando = false;
        });
      }
    });
  }

  /// Actualiza la lista de subcategorías basándose en la categoría principal seleccionada
  void _actualizarSubcategorias() {
    if (_categoriaPrincipalSeleccionada == null) {
      _subcategorias = [];
      _subcategoriaSeleccionada = null;
      return;
    }

    final subcatsSet = <String>{};
    for (final p in _productos) {
      if (_categoriaPrincipal(p.categoria) == _categoriaPrincipalSeleccionada) {
        final sub = _subcategoria(p.categoria);
        if (sub != null) {
          subcatsSet.add(sub);
        }
      }
    }
    _subcategorias = subcatsSet.toList()..sort();

    // Si la subcategoría seleccionada ya no existe, deseleccionarla
    if (_subcategoriaSeleccionada != null &&
        !_subcategorias.contains(_subcategoriaSeleccionada)) {
      _subcategoriaSeleccionada = null;
    }
  }

  Future<void> _cargarProductos() async {
    _productosSub?.cancel();
    _iniciarEscuchaProductos();
  }

  void _filtrarProductos(String texto) {
    setState(() {
      _productosFiltrados = _productos.where((p) {
        final coincideTexto =
            p.nombre.toLowerCase().startsWith(texto.toLowerCase());

        // Filtrar por categoría jerárquica
        bool coincideCategoria = true;
        if (_categoriaPrincipalSeleccionada != null) {
          coincideCategoria =
              _categoriaPrincipal(p.categoria) == _categoriaPrincipalSeleccionada;
          if (coincideCategoria && _subcategoriaSeleccionada != null) {
            coincideCategoria =
                _subcategoria(p.categoria) == _subcategoriaSeleccionada;
          }
        }

        return coincideTexto && coincideCategoria;
      }).toList();
    });
  }

  void _seleccionarCategoriaPrincipal(String? categoria) {
    setState(() {
      if (_categoriaPrincipalSeleccionada == categoria) {
        // Deseleccionar
        _categoriaPrincipalSeleccionada = null;
        _subcategoriaSeleccionada = null;
        _subcategorias = [];
      } else {
        _categoriaPrincipalSeleccionada = categoria;
        _subcategoriaSeleccionada = null;
        _actualizarSubcategorias();
      }
    });
    _filtrarProductos(_searchController.text);
  }

  void _seleccionarSubcategoria(String? subcategoria) {
    setState(() {
      _subcategoriaSeleccionada =
          _subcategoriaSeleccionada == subcategoria ? null : subcategoria;
    });
    _filtrarProductos(_searchController.text);
  }

  void _agregarAlCarrito(Producto producto, [int cantidad = 1]) {
    widget.onAgregarAlCarrito(producto, cantidad);
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
            CircularProgressIndicator(color: MinimarketTheme.primaryRed),
            SizedBox(height: 16),
            Text('Cargando productos...', style: TextStyle(color: MinimarketTheme.textSecondary)),
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
              const Icon(Icons.error_outline, size: 64, color: MinimarketTheme.error),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: MinimarketTheme.textSecondary)),
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

        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
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

        // ─── Categorías Principales ───
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              CategoriaChip(
                label: 'Todos',
                selected: _categoriaPrincipalSeleccionada == null,
                onSelected: (_) => _seleccionarCategoriaPrincipal(null),
              ),
              CategoriaChip(
                label: '🔥 Ofertas Wisa',
                selected: false,
                onSelected: (_) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OfertasScreen(
                        onAgregarAlCarrito: widget.onAgregarAlCarrito,
                      ),
                    ),
                  );
                },
              ),
              ..._categoriasPrincipales.map((cat) => CategoriaChip(
                    label: cat,
                    selected: _categoriaPrincipalSeleccionada == cat,
                    onSelected: (_) => _seleccionarCategoriaPrincipal(cat),
                  )),
            ],
          ),
        ),

        // ─── Subcategorías (solo visible si hay categoría principal seleccionada y subcategorías) ───
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: _categoriaPrincipalSeleccionada != null && _subcategorias.isNotEmpty
              ? Column(
                  children: [
                    const SizedBox(height: 2),
                    SizedBox(
                      height: 42,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        children: [
                          CategoriaChip(
                            label: 'Todas',
                            selected: _subcategoriaSeleccionada == null,
                            onSelected: (_) => _seleccionarSubcategoria(null),
                          ),
                          ..._subcategorias.map((sub) => CategoriaChip(
                                label: sub,
                                selected: _subcategoriaSeleccionada == sub,
                                onSelected: (_) => _seleccionarSubcategoria(sub),
                              )),
                        ],
                      ),
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ),

        const SizedBox(height: 4),
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
              const SizedBox(width: 8),
              if (_lastUpdate != null)
                Text(
                  '• Sinc. ${_lastUpdate!.hour.toString().padLeft(2, '0')}:${_lastUpdate!.minute.toString().padLeft(2, '0')}:${_lastUpdate!.second.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    color: MinimarketTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                color: MinimarketTheme.primaryRed,
                onPressed: _cargarProductos,
                tooltip: 'Actualizar',
              ),
            ],
          ),
        ),
        Expanded(
          child: _productosFiltrados.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: MinimarketTheme.divider),
                      SizedBox(height: 12),
                      Text('No se encontraron productos', style: TextStyle(color: MinimarketTheme.textSecondary)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargarProductos,
                  color: MinimarketTheme.primaryRed,
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 80),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.68,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                    ),
                    itemCount: _productosFiltrados.length,
                    itemBuilder: (context, index) {
                      final producto = _productosFiltrados[index];
                      return ProductoCard(
                        producto: producto,
                        onTap: () => _mostrarDetalle(producto),
                        onAgregar: producto.puedeAgregar ? () => _agregarAlCarrito(producto) : null,
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}