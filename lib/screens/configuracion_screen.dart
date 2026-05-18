import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/producto.dart';
import '../services/firestore_service.dart';

class ConfiguracionScreen extends StatefulWidget {
  const ConfiguracionScreen({super.key});

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _cargandoSeed = false;
  bool _cargandoListar = false;
  bool _cargandoAgregar = false;
  bool _cargandoEliminar = false;

  // ─── SEED ───
  Future<void> _cargarProductosIniciales() async {
    setState(() => _cargandoSeed = true);
    try {
      final count = await _firestoreService.cargarProductosIniciales();
      if (!mounted) return;
      if (count == -1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Ya existen productos en la base de datos.'),
            backgroundColor: MinimarketTheme.warning,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Se cargaron $count productos exitosamente.'),
            backgroundColor: MinimarketTheme.disponible,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: MinimarketTheme.error,
        ),
      );
    }
    setState(() => _cargandoSeed = false);
  }

  // ─── LISTAR ───
  Future<void> _listarProductos() async {
    setState(() => _cargandoListar = true);
    try {
      final productos = await _firestoreService.obtenerProductos();
      if (!mounted) return;
      _mostrarDialogProductos(productos);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: MinimarketTheme.error),
      );
    }
    setState(() => _cargandoListar = false);
  }

  void _mostrarDialogProductos(List<Producto> productos) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.list_alt, color: MinimarketTheme.secondaryNavy),
            const SizedBox(width: 8),
            Text('Productos (${productos.length})',
                style: const TextStyle(fontSize: 16)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: productos.isEmpty
              ? const Center(child: Text('No hay productos en Firestore'))
              : ListView.separated(
                  itemCount: productos.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final p = productos[index];
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: p.disponible
                            ? MinimarketTheme.disponible
                            : MinimarketTheme.sinStock,
                        child: Icon(
                          p.disponible ? Icons.check : Icons.close,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(p.nombre,
                          style: const TextStyle(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                        'S/ ${p.precio.toStringAsFixed(2)} — Stock: ${p.stock}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: Text(p.id.substring(0, 6),
                          style: const TextStyle(
                              fontSize: 10,
                              color: MinimarketTheme.textSecondary)),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  // ─── AGREGAR PRUEBA ───
  Future<void> _agregarProductoPrueba() async {
    setState(() => _cargandoAgregar = true);
    try {
      final producto = Producto(
        id: '',
        nombre: 'Producto de Prueba ${DateTime.now().millisecondsSinceEpoch}',
        descripcion: 'Producto creado desde la pantalla de configuración.',
        categoria: 'Test / Prueba',
        precio: 9.99,
        stock: 10,
        disponible: true,
      );
      final id = await _firestoreService.agregarProducto(producto);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Producto creado con ID: ${id.substring(0, 8)}...'),
          backgroundColor: MinimarketTheme.disponible,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e'), backgroundColor: MinimarketTheme.error),
      );
    }
    setState(() => _cargandoAgregar = false);
  }

  // ─── ELIMINAR ÚLTIMO ───
  Future<void> _eliminarUltimoProducto() async {
    setState(() => _cargandoEliminar = true);
    try {
      final productos = await _firestoreService.obtenerProductos();
      if (productos.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ No hay productos para eliminar.'),
            backgroundColor: MinimarketTheme.warning,
          ),
        );
      } else {
        final ultimo = productos.last;
        await _firestoreService.eliminarProducto(ultimo.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🗑️ Eliminado: ${ultimo.nombre}'),
            backgroundColor: MinimarketTheme.secondaryNavy,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e'), backgroundColor: MinimarketTheme.error),
      );
    }
    setState(() => _cargandoEliminar = false);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── Banner de Desarrollo ───
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: MinimarketTheme.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: MinimarketTheme.warning.withValues(alpha: 0.4)),
            ),
            child: const Row(
              children: [
                Icon(Icons.engineering, color: MinimarketTheme.warning),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Pantalla de desarrollo — será removida en producción',
                    style: TextStyle(
                      color: MinimarketTheme.warning,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ─── Sección: Carga Inicial ───
          const Text(
            'CARGA DE DATOS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: MinimarketTheme.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cargar Productos Iniciales',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: MinimarketTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Sube los 85 productos del datasheet a la colección "productos" de Firestore. Solo funciona si la colección está vacía.',
                    style: TextStyle(
                        fontSize: 13,
                        color: MinimarketTheme.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _cargandoSeed ? null : _cargarProductosIniciales,
                      icon: _cargandoSeed
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: MinimarketTheme.secondaryNavy))
                          : const Icon(Icons.cloud_upload_rounded),
                      label: Text(
                          _cargandoSeed ? 'Cargando...' : 'Cargar Datasheet'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ─── Sección: CRUD de Prueba ───
          const Text(
            'CRUD DE PRUEBA',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: MinimarketTheme.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Listar
                  _buildCrudButton(
                    icon: Icons.list_alt_rounded,
                    label: 'Listar Productos',
                    color: MinimarketTheme.secondaryNavy,
                    cargando: _cargandoListar,
                    onPressed: _listarProductos,
                  ),
                  const Divider(height: 20),

                  // Agregar
                  _buildCrudButton(
                    icon: Icons.add_circle_rounded,
                    label: 'Agregar Producto de Prueba',
                    color: MinimarketTheme.disponible,
                    cargando: _cargandoAgregar,
                    onPressed: _agregarProductoPrueba,
                  ),
                  const Divider(height: 20),

                  // Eliminar
                  _buildCrudButton(
                    icon: Icons.delete_rounded,
                    label: 'Eliminar Último Producto',
                    color: MinimarketTheme.error,
                    cargando: _cargandoEliminar,
                    onPressed: _eliminarUltimoProducto,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ─── Info ───
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'INFORMACIÓN',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: MinimarketTheme.textSecondary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow('Proyecto', 'Minimarket App'),
                  _buildInfoRow('Base de Datos', 'Cloud Firestore'),
                  _buildInfoRow('Colección', 'productos'),
                  _buildInfoRow('Versión', '1.0.0 (MVP)'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCrudButton({
    required IconData icon,
    required String label,
    required Color color,
    required bool cargando,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: cargando ? null : onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: cargando
                  ? Padding(
                      padding: const EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: color),
                    )
                  : Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: cargando
                      ? MinimarketTheme.textSecondary
                      : MinimarketTheme.textPrimary,
                ),
              ),
            ),
            Icon(Icons.chevron_right,
                color: MinimarketTheme.textSecondary.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: MinimarketTheme.textSecondary)),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: MinimarketTheme.textPrimary)),
        ],
      ),
    );
  }
}
