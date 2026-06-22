import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../models/producto.dart';
import '../../services/firestore_service.dart';
import '../../config/theme.dart';

class AdminProductosScreen extends StatefulWidget {
  const AdminProductosScreen({super.key});

  @override
  State<AdminProductosScreen> createState() => _AdminProductosScreenState();
}

class _AdminProductosScreenState extends State<AdminProductosScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final ImagePicker _picker = ImagePicker();

  void _mostrarDialogoFormulario({Producto? producto}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _FormularioProductoDialog(
        producto: producto,
        firestoreService: _firestoreService,
        picker: _picker,
      ),
    );
  }

  void _confirmarEliminar(Producto producto) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar Producto'),
        content: Text('¿Estás seguro de que deseas eliminar "${producto.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await _firestoreService.eliminarProducto(producto.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Producto eliminado'), backgroundColor: MinimarketTheme.disponible),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: MinimarketTheme.error),
                  );
                }
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: MinimarketTheme.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Gestión de Productos',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: MinimarketTheme.textPrimary,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _mostrarDialogoFormulario(),
                icon: const Icon(Icons.add),
                label: const Text('Nuevo Producto'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MinimarketTheme.disponible,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: StreamBuilder<List<Producto>>(
                stream: _firestoreService.streamProductos(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: MinimarketTheme.primaryRed));
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error al cargar datos: ${snapshot.error}', style: const TextStyle(color: MinimarketTheme.error)));
                  }
                  
                  final productos = snapshot.data ?? [];
                  if (productos.isEmpty) {
                    return const Center(child: Text('No hay productos registrados.', style: TextStyle(color: MinimarketTheme.textSecondary)));
                  }

                  return SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(MinimarketTheme.background),
                        columns: const [
                          DataColumn(label: Text('Imagen')),
                          DataColumn(label: Text('Nombre')),
                          DataColumn(label: Text('Categoría')),
                          DataColumn(label: Text('Precio (S/)')),
                          DataColumn(label: Text('Stock')),
                          DataColumn(label: Text('Estado')),
                          DataColumn(label: Text('Acciones')),
                        ],
                        rows: productos.map((prod) {
                          return DataRow(
                            cells: [
                              DataCell(
                                prod.imagenUrl.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: Image.network(prod.imagenUrl, width: 40, height: 40, fit: BoxFit.cover,
                                        errorBuilder: (c, e, s) => const Icon(Icons.broken_image, color: Colors.grey)),
                                      )
                                    : const Icon(Icons.image_not_supported, color: Colors.grey),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 250,
                                  child: Text(prod.nombre, maxLines: 2, overflow: TextOverflow.ellipsis),
                                ),
                              ),
                              DataCell(Text(prod.categoria)),
                              DataCell(Text(prod.precio.toStringAsFixed(2))),
                              DataCell(Text(prod.stock.toString())),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: prod.disponible ? MinimarketTheme.disponible.withValues(alpha: 0.1) : MinimarketTheme.sinStock.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    prod.disponible ? 'Disponible' : 'Agotado',
                                    style: TextStyle(
                                      color: prod.disponible ? MinimarketTheme.disponible : MinimarketTheme.sinStock,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                                      tooltip: 'Editar',
                                      onPressed: () => _mostrarDialogoFormulario(producto: prod),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: MinimarketTheme.error),
                                      tooltip: 'Eliminar',
                                      onPressed: () => _confirmarEliminar(prod),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormularioProductoDialog extends StatefulWidget {
  final Producto? producto;
  final FirestoreService firestoreService;
  final ImagePicker picker;

  const _FormularioProductoDialog({this.producto, required this.firestoreService, required this.picker});

  @override
  State<_FormularioProductoDialog> createState() => _FormularioProductoDialogState();
}

class _FormularioProductoDialogState extends State<_FormularioProductoDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreCtrl;
  late TextEditingController _descripcionCtrl;
  late TextEditingController _categoriaCtrl;
  late TextEditingController _precioCtrl;
  late TextEditingController _stockCtrl;
  late TextEditingController _urlCtrl;
  bool _disponible = true;
  bool _guardando = false;
  bool _subiendoImagen = false;

  Uint8List? _imagenBytes;
  String _nombreArchivo = '';

  @override
  void initState() {
    super.initState();
    final p = widget.producto;
    _nombreCtrl = TextEditingController(text: p?.nombre ?? '');
    _descripcionCtrl = TextEditingController(text: p?.descripcion ?? '');
    _categoriaCtrl = TextEditingController(text: p?.categoria ?? '');
    _precioCtrl = TextEditingController(text: p != null ? p.precio.toString() : '');
    _stockCtrl = TextEditingController(text: p != null ? p.stock.toString() : '');
    _urlCtrl = TextEditingController(text: p?.imagenUrl ?? '');
    _disponible = p?.disponible ?? true;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    _categoriaCtrl.dispose();
    _precioCtrl.dispose();
    _stockCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarImagen() async {
    try {
      final XFile? image = await widget.picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _imagenBytes = bytes;
          _nombreArchivo = image.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al seleccionar imagen: $e')));
      }
    }
  }

  Future<String?> _subirImagenStorage() async {
    if (_imagenBytes == null) return null;
    try {
      setState(() => _subiendoImagen = true);
      // Crear una referencia única en Firebase Storage
      final ref = FirebaseStorage.instance
          .ref()
          .child('productos')
          .child('${DateTime.now().millisecondsSinceEpoch}_$_nombreArchivo');
      
      final uploadTask = ref.putData(_imagenBytes!, SettableMetadata(contentType: 'image/jpeg'));
      final snapshot = await uploadTask;
      final urlDescarga = await snapshot.ref.getDownloadURL();
      return urlDescarga;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al subir a Storage: $e')));
      }
      return null;
    } finally {
      if (mounted) setState(() => _subiendoImagen = false);
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);

    try {
      String finalImageUrl = _urlCtrl.text.trim();

      // Si seleccionó una imagen física, subirla primero
      if (_imagenBytes != null) {
        final urlSubida = await _subirImagenStorage();
        if (urlSubida != null) {
          finalImageUrl = urlSubida;
        } else {
          throw Exception("Fallo la subida de imagen");
        }
      }

      final prod = Producto(
        id: widget.producto?.id ?? '',
        nombre: _nombreCtrl.text.trim(),
        descripcion: _descripcionCtrl.text.trim(),
        categoria: _categoriaCtrl.text.trim(),
        precio: double.tryParse(_precioCtrl.text) ?? 0.0,
        stock: int.tryParse(_stockCtrl.text) ?? 0,
        disponible: _disponible,
        imagenUrl: finalImageUrl,
      );

      if (widget.producto == null) {
        await widget.firestoreService.agregarProducto(prod);
      } else {
        await widget.firestoreService.actualizarProducto(prod);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Producto guardado correctamente'), backgroundColor: MinimarketTheme.disponible),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e'), backgroundColor: MinimarketTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.producto != null;

    return AlertDialog(
      title: Text(esEdicion ? 'Editar Producto' : 'Nuevo Producto', style: const TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nombreCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre del Producto', prefixIcon: Icon(Icons.label_outline)),
                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descripcionCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Descripción', prefixIcon: Icon(Icons.description_outlined)),
                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _categoriaCtrl,
                  decoration: const InputDecoration(labelText: 'Categoría (Ej: Abarrotes / Lácteos)', prefixIcon: Icon(Icons.category_outlined)),
                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _precioCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Precio (S/)', prefixIcon: Icon(Icons.attach_money)),
                        validator: (v) => v!.isEmpty || double.tryParse(v) == null ? 'Inválido' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _stockCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Stock Físico', prefixIcon: Icon(Icons.inventory_2_outlined)),
                        validator: (v) => v!.isEmpty || int.tryParse(v) == null ? 'Inválido' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Disponible para venta'),
                  subtitle: const Text('Si se apaga, no aparecerá en el catálogo de clientes'),
                  value: _disponible,
                  activeColor: MinimarketTheme.disponible,
                  onChanged: (v) => setState(() => _disponible = v),
                ),
                const Divider(height: 32),
                const Text('Imagen del Producto', style: TextStyle(fontWeight: FontWeight.bold, color: MinimarketTheme.textSecondary)),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_imagenBytes != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(_imagenBytes!, width: 80, height: 80, fit: BoxFit.cover),
                      )
                    else if (_urlCtrl.text.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(_urlCtrl.text, width: 80, height: 80, fit: BoxFit.cover, errorBuilder: (c,e,s) => Container(width: 80, height: 80, color: Colors.grey[200], child: const Icon(Icons.broken_image))),
                      )
                    else
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.image_outlined, color: Colors.grey),
                      ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _guardando || _subiendoImagen ? null : _seleccionarImagen,
                            icon: const Icon(Icons.upload_file),
                            label: Text(_imagenBytes != null ? 'Cambiar archivo seleccionado' : 'Subir archivo (PNG/JPG)'),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _urlCtrl,
                            enabled: _imagenBytes == null && !_guardando,
                            decoration: InputDecoration(
                              labelText: _imagenBytes != null ? 'Imagen local seleccionada' : 'O usar URL directa',
                              hintText: 'https://...',
                              isDense: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando || _subiendoImagen ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: _guardando || _subiendoImagen ? null : _guardar,
          icon: _guardando || _subiendoImagen
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.save),
          label: Text(_subiendoImagen ? 'Subiendo imagen...' : 'Guardar Producto'),
          style: ElevatedButton.styleFrom(backgroundColor: MinimarketTheme.primaryRed),
        ),
      ],
    );
  }
}
