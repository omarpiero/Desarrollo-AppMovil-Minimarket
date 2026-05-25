import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/producto.dart';

const String imagenIncaKolaPrueba =
    'https://res.cloudinary.com/dznotodst/image/upload/q_auto/f_auto/v1779212420/20109402_nsr6uj.webp';

const Map<String, String> imagenesProductosPrueba = {
  'Gaseosa INCA KOLA sin Azúcar Botella 300ml': imagenIncaKolaPrueba,
  'Leche Reconstituida Entera GLORIA Lata 390g': 'https://res.cloudinary.com/dznotodst/image/upload/q_auto/f_auto/v1779485738/leche_sycetv.webp',
  'Fideos DON VITTORIO Spaghetti Bolsa 500g': 'https://res.cloudinary.com/dznotodst/image/upload/q_auto/f_auto/v1779485738/don_victorio_nsaidi.webp',
  'Aceite Vegetal PRIMOR Clásico Botella 900ml': 'https://res.cloudinary.com/dznotodst/image/upload/q_auto/f_auto/v1779485738/aceite_primor_ns2fsq.webp',
  'Arroz Extra COSTEÑO Bolsa 1Kg': 'https://res.cloudinary.com/dznotodst/image/upload/q_auto/f_auto/v1779485738/arroz_coste%C3%B1a_vgwuev.webp',
  'Lenteja Bebé Costeño Bolsa 500g': 'https://res.cloudinary.com/dznotodst/image/upload/q_auto/f_auto/v1779486467/LENTEJA-BEBE-X-500-GRS-COSTE-O-1-366083_j4obwm.webp',
  'Fideos ANITA Codito Bolsa 250g': 'https://res.cloudinary.com/dznotodst/image/upload/q_auto/f_auto/v1779486467/322624_fmej3c.webp',
  'Colorante PANCA SIN PICANTE Sibarita Sobre 10g': 'https://res.cloudinary.com/dznotodst/image/upload/q_auto/f_auto/v1779486467/bb75757fd62cd5fb9868e70a3cdb6f53_q11f6f.jpg',
  'Pimienta Sibarita Sobre 10g': 'https://res.cloudinary.com/dznotodst/image/upload/q_auto/f_auto/v1779486467/1701804852819_1701804847311_1701804847075_dhxgma.png',
  'Caldo de Gallina MAGGI Cubito': 'https://res.cloudinary.com/dznotodst/image/upload/q_auto/f_auto/v1779486467/sin_titulo-removebg-preview0265_mtdio9.png',
  'Sazonador AJINOMOTO Sobre 50g': 'https://res.cloudinary.com/dznotodst/image/upload/q_auto/f_auto/v1779486467/ajinomoto_kqnxos.jpg',
  'Vinagre Tinto BULNES Botella 500ml': 'https://res.cloudinary.com/dznotodst/image/upload/q_auto/f_auto/v1779486468/7791720035993_01_dh6evf.webp',
  'Sillao KIKKO Botella Plástica 250ml': 'https://res.cloudinary.com/dznotodst/image/upload/q_auto/f_auto/v1779486468/409125-800-auto_l1g9q1.webp',
  'Pasta de Tomate POMAROLA Sobre 145g': 'https://res.cloudinary.com/dznotodst/image/upload/q_auto/f_auto/v1779486468/20284370_zxdfwx.webp',
  'Salsa de Ají TARÍ Doypack 85g': 'https://res.cloudinary.com/dznotodst/image/upload/q_auto/f_auto/v1779486468/20039446_bs9ynp.webp',
  'Mostaza ALACENA Doypack 100g': 'https://res.cloudinary.com/dznotodst/image/upload/q_auto/f_auto/v1779486468/20112945_dlag6b.webp',
  "Ketchup LIBBY'S Doypack 100g": 'https://res.cloudinary.com/dznotodst/image/upload/q_auto/f_auto/v1779486468/118110_jlepqq.webp',
  'Mayonesa ALACENA Doypack 95g': 'https://res.cloudinary.com/dznotodst/image/upload/q_auto/f_auto/v1779486468/20057318_w32ysr.webp',
  'Duraznos en Mitades ACONCAGUA Lata 820g': 'https://res.cloudinary.com/dznotodst/image/upload/q_auto/f_auto/v1779486468/Duraznos-en-Almibar-Aconcagua-820g_wjhurt.webp',
  'Filete de Caballa CAMPOMAR Lata 170g': 'https://res.cloudinary.com/dznotodst/image/upload/q_auto/f_auto/v1779486468/IMG-2258_1200x1200_vshva5.webp',
  'Atún en Aceite FLORIDA Lata 170g': 'https://res.cloudinary.com/dznotodst/image/upload/q_auto/f_auto/v1779486469/957951_peanpk.webp',
  'Huevos de Gallina Pardos LA CALERA Plancha x 30': 'https://res.cloudinary.com/dznotodst/image/upload/q_auto/f_auto/v1779486469/20138032_mrbba7.webp',
  'Yogurt BATIMIX GLORIA Vainilla con Hojuelas 145g': 'https://res.cloudinary.com/dznotodst/image/upload/q_auto/f_auto/v1779486469/w_800_h_800_fit_pad_2_b1ucqv.webp',
  'Yogurt Bebible GLORIA Fresa Botella 1Kg': 'https://res.cloudinary.com/dznotodst/image/upload/q_auto/f_auto/v1779486469/20326320_owzjqp.webp',
  'Queso Fresco Pasteurizado BONLÉ Molde 250g': 'https://res.cloudinary.com/dznotodst/image/upload/q_auto/f_auto/v1779486469/w_800_h_800_fit_pad_1_fgzdwj.webp',
  'Queso Edam LAIVE Tajadas Paquete 150g': 'https://res.cloudinary.com/dznotodst/image/upload/q_auto/f_auto/v1779486469/20147402_tx6ukr.webp',
  'Margarina MANTY Clásica Pote 225g': 'https://res.cloudinary.com/dznotodst/image/upload/q_auto/f_auto/v1779486470/7750243052054_avao4t.webp',
  'Mantequilla GLORIA con Sal Pote 200g': 'https://res.cloudinary.com/dznotodst/image/upload/q_auto/f_auto/v1779486470/918175_a9kfqt.webp',
  'Chifles KARINTO Bolsa 45g': 'https://res.cloudinary.com/dznotodst/image/upload/q_auto/f_auto/v1779486470/w_1500_h_1500_fit_cover_ysd20h.webp',
  'Papas Fritas LAYS Clásicas Bolsa 36g': 'https://res.cloudinary.com/dznotodst/image/upload/q_auto/f_auto/v1779486470/20352713_utggqv.webp',
  'Tortillas de Maíz CUATES Picantes Bolsa 40g': 'https://res.cloudinary.com/dznotodst/image/upload/q_auto/f_auto/v1779486470/953473128847_wmyamtfrogmc_391917896934_zkwjbixvhsga_51774_1_ldbged.jpg',
  'Galletas DOÑA PEPA Paquete 23g': 'https://res.cloudinary.com/dznotodst/image/upload/q_auto/f_auto/v1779486470/580535-800-auto_cdfrxd.webp',
  'Galletas MOROCHAS Nestlé Paquete 30g': 'https://res.cloudinary.com/dznotodst/image/upload/q_auto/f_auto/v1779486471/7613035963948_5d17a937-ba96-4518-b348-3c6b17e56f82_i9a2i5.webp',
  'Galletas CASINO Fresa Paquete 43g': 'https://res.cloudinary.com/dznotodst/image/upload/q_auto/f_auto/v1779486471/579283-800-auto_ctwb6a.webp',
  'Galletas RITZ Taco 67g': 'https://res.cloudinary.com/dznotodst/image/upload/q_auto/f_auto/v1779486471/1596228249-63-nabisco-ritz-taco-jpg_u5xhyb.jpg',
  'Galletas Soda FIELD Paquete 6x34g': 'https://res.cloudinary.com/dznotodst/image/upload/q_auto/f_auto/v1779486471/bolsa-de-galletas-soda-A_700x700_d7mcyi.webp',
  'Cacao en polvo MILO Sobre 18g': 'https://res.cloudinary.com/dznotodst/image/upload/q_auto/f_auto/v1779486471/w_800_h_800_fit_pad_xz1oeg.webp',
  'Café Tostado y Molido CAFETAL Sobre 50g': 'https://res.cloudinary.com/dznotodst/image/upload/q_auto/f_auto/v1779486471/7754308000172_wvekmi.webp',
  'Avena Clásica SANTA CATALINA Bolsa 100g': 'https://res.cloudinary.com/dznotodst/image/upload/q_auto/f_auto/v1779486471/avena_pdbcnr.webp',
  'Azúcar Rubia CARTAVIO Bolsa 1Kg': 'https://res.cloudinary.com/dznotodst/image/upload/q_auto/f_auto/v1779486472/cartavio_n1cruq.webp',
};


class FirestoreService {
  final CollectionReference _productosRef =
      FirebaseFirestore.instance.collection('productos');

  // ─── READ ───
  /// Obtiene todos los productos de Firestore.
  Future<List<Producto>> obtenerProductos() async {
    final snapshot = await _productosRef.orderBy('categoria').get();
    return snapshot.docs.map((doc) => Producto.fromFirestore(doc)).toList();
  }

  // ─── CREATE ───
  /// Agrega un producto a Firestore y retorna el ID generado.
  Future<String> agregarProducto(Producto producto) async {
    final docRef = await _productosRef.add(producto.toMap());
    return docRef.id;
  }

  // ─── UPDATE ───
  /// Actualiza un producto existente por su ID.
  Future<void> actualizarProducto(Producto producto) async {
    await _productosRef.doc(producto.id).update(producto.toMap());
  }

  // ─── DELETE ───
  /// Elimina un producto por su ID.
  Future<void> eliminarProducto(String id) async {
    await _productosRef.doc(id).delete();
  }

  // ─── UPDATE IMAGEN DE PRUEBA ───
  /// Asigna la URL de imagen de prueba al primer producto Inca Kola encontrado.
  Future<bool> asignarImagenIncaKolaPrueba() async {
    final snapshot = await _productosRef
        .where('nombre', isGreaterThanOrEqualTo: 'Gaseosa INCA KOLA')
        .where('nombre', isLessThan: 'Gaseosa INCA KOLA\uf8ff')
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return false;
    }

    await snapshot.docs.first.reference.update({
      'imagenUrl': imagenIncaKolaPrueba,
    });
    return true;
  }


  // ─── UPDATE IMÁGENES DE PRODUCTOS ───
  /// Asigna las URLs de Cloudinary a todos los productos encontrados en Firestore.
  /// Retorna la cantidad de documentos actualizados.
  Future<int> asignarImagenesProductosPrueba() async {
    final snapshot = await _productosRef.get();
    if (snapshot.docs.isEmpty) return 0;

    final batch = FirebaseFirestore.instance.batch();
    int actualizados = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final nombre = (data['nombre'] ?? '').toString();
      final imagenUrl = _buscarImagenPorNombre(nombre);

      if (imagenUrl.isNotEmpty && data['imagenUrl'] != imagenUrl) {
        batch.update(doc.reference, {'imagenUrl': imagenUrl});
        actualizados++;
      }
    }

    if (actualizados > 0) {
      await batch.commit();
    }
    return actualizados;
  }

  static String _normalizarNombre(String value) {
    return value
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _buscarImagenPorNombre(String nombreProducto) {
    final nombreNormalizado = _normalizarNombre(nombreProducto);
    for (final entry in imagenesProductosPrueba.entries) {
      final keyNormalizado = _normalizarNombre(entry.key);
      if (nombreNormalizado == keyNormalizado ||
          nombreNormalizado.contains(keyNormalizado) ||
          keyNormalizado.contains(nombreNormalizado)) {
        return entry.value;
      }
    }
    return '';
  }

  // ─── SEED ───
  /// Carga los productos iniciales del datasheet a Firestore.
  /// Verifica si ya existen productos para no duplicar.
  Future<int> cargarProductosIniciales() async {
    // Verificar si ya hay productos cargados
    final existing = await _productosRef.limit(1).get();
    if (existing.docs.isNotEmpty) {
      return -1; // Ya existen productos
    }

    final batch = FirebaseFirestore.instance.batch();
    int count = 0;

    for (final item in _datosIniciales) {
      final docRef = _productosRef.doc();
      final itemConImagen = Map<String, dynamic>.from(item);
      final imagenUrl = _buscarImagenPorNombre(
        (itemConImagen['nombre'] ?? '').toString(),
      );
      if (imagenUrl.isNotEmpty) {
        itemConImagen['imagenUrl'] = imagenUrl;
      }
      batch.set(docRef, itemConImagen);
      count++;
    }

    await batch.commit();
    return count;
  }

  // ─── DATOS INICIALES (85 productos del datasheet) ───
  static final List<Map<String, dynamic>> _datosIniciales = [
    {'nombre': 'Gaseosa INCA KOLA sin Azúcar Botella 300ml (Pack de 6)', 'descripcion': 'Bebida gaseosa personal sin azúcar en paquete de 6 unidades, ideal para stock de bodega.', 'categoria': 'Bebidas / Gaseosas', 'precio': 8.50, 'stock': 25, 'disponible': true, 'imagenUrl': imagenIncaKolaPrueba},
    {'nombre': 'Leche Reconstituida Entera GLORIA Lata 390g', 'descripcion': 'Leche evaporada tradicional en lata grande, un producto básico para el desayuno.', 'categoria': 'Lácteos / Leche', 'precio': 4.20, 'stock': 40, 'disponible': true},
    {'nombre': 'Fideos DON VITTORIO Spaghetti Bolsa 500g', 'descripcion': 'Fideos largos clásicos de trigo, presentación estándar para venta al por menor.', 'categoria': 'Abarrotes / Pastas', 'precio': 3.10, 'stock': 35, 'disponible': true},
    {'nombre': 'Aceite Vegetal PRIMOR Clásico Botella 900ml', 'descripcion': 'Aceite de uso diario en envase personal, indispensable en cualquier cocina.', 'categoria': 'Abarrotes / Aceites', 'precio': 9.70, 'stock': 20, 'disponible': true},
    {'nombre': 'Arroz Extra COSTEÑO Bolsa 1Kg', 'descripcion': 'Arroz de grano largo y rendidor ideal para el menú diario.', 'categoria': 'Abarrotes / Arroz', 'precio': 4.50, 'stock': 50, 'disponible': true},
    {'nombre': 'Azúcar Rubia CARTAVIO Bolsa 1Kg', 'descripcion': 'Azúcar rubia doméstica para endulzar bebidas y postres.', 'categoria': 'Abarrotes / Azúcar', 'precio': 4.00, 'stock': 30, 'disponible': true},
    {'nombre': 'Avena Clásica SANTA CATALINA Bolsa 100g', 'descripcion': 'Avena tradicional en hojuelas rápidas para el desayuno.', 'categoria': 'Desayuno / Avena', 'precio': 1.50, 'stock': 45, 'disponible': true},
    {'nombre': 'Café Tostado y Molido CAFETAL Sobre 50g', 'descripcion': 'Café peruano de consumo masivo para pasar.', 'categoria': 'Desayuno / Café', 'precio': 3.50, 'stock': 20, 'disponible': true},
    {'nombre': 'Cacao en polvo MILO Sobre 18g', 'descripcion': 'Modificador de leche sabor a chocolate en sachet.', 'categoria': 'Desayuno / Modificadores', 'precio': 1.00, 'stock': 60, 'disponible': true},
    {'nombre': 'Galletas Soda FIELD Paquete 6x34g', 'descripcion': 'Galleta salada clásica, infaltable para el desayuno o lonchera.', 'categoria': 'Snacks / Galletas', 'precio': 3.50, 'stock': 30, 'disponible': true},
    {'nombre': 'Galletas RITZ Taco 67g', 'descripcion': 'Galletas saladas con sabor a mantequilla de alta rotación.', 'categoria': 'Snacks / Galletas', 'precio': 1.20, 'stock': 40, 'disponible': true},
    {'nombre': 'Galletas CASINO Fresa Paquete 43g', 'descripcion': 'Galleta dulce rellena sabor a fresa, favorita de los niños.', 'categoria': 'Snacks / Galletas', 'precio': 0.80, 'stock': 50, 'disponible': true},
    {'nombre': 'Galletas MOROCHAS Nestlé Paquete 30g', 'descripcion': 'Galletas cubiertas con sabor a chocolate.', 'categoria': 'Snacks / Galletas', 'precio': 0.80, 'stock': 3, 'disponible': true},
    {'nombre': 'Galletas DOÑA PEPA Paquete 23g', 'descripcion': 'Galleta bañada en chocolate con grageas de colores.', 'categoria': 'Snacks / Galletas', 'precio': 1.00, 'stock': 35, 'disponible': true},
    {'nombre': 'Tortillas de Maíz CUATES Picantes Bolsa 40g', 'descripcion': 'Snack picante muy popular entre jóvenes.', 'categoria': 'Snacks / Piqueos', 'precio': 1.50, 'stock': 25, 'disponible': true},
    {'nombre': 'Papas Fritas LAYS Clásicas Bolsa 36g', 'descripcion': 'Snack de papas fritas saladas en formato personal.', 'categoria': 'Snacks / Piqueos', 'precio': 1.80, 'stock': 30, 'disponible': true},
    {'nombre': 'Chifles KARINTO Bolsa 45g', 'descripcion': 'Hojuelas de plátano frito salado.', 'categoria': 'Snacks / Piqueos', 'precio': 1.50, 'stock': 0, 'disponible': false},
    {'nombre': 'Mantequilla GLORIA con Sal Pote 200g', 'descripcion': 'Mantequilla de leche de vaca para untar.', 'categoria': 'Lácteos / Mantequilla', 'precio': 8.50, 'stock': 12, 'disponible': true},
    {'nombre': 'Margarina MANTY Clásica Pote 225g', 'descripcion': 'Margarina vegetal económica para panes y repostería.', 'categoria': 'Lácteos / Margarina', 'precio': 4.50, 'stock': 15, 'disponible': true},
    {'nombre': 'Queso Edam LAIVE Tajadas Paquete 150g', 'descripcion': 'Queso madurado en tajadas listo para sándwiches.', 'categoria': 'Lácteos / Quesos', 'precio': 7.50, 'stock': 10, 'disponible': true},
    {'nombre': 'Queso Fresco Pasteurizado BONLÉ Molde 250g', 'descripcion': 'Queso fresco de textura suave para consumo diario.', 'categoria': 'Lácteos / Quesos', 'precio': 6.80, 'stock': 8, 'disponible': true},
    {'nombre': 'Yogurt Bebible GLORIA Fresa Botella 1Kg', 'descripcion': 'Yogurt frutado familiar de alto rendimiento.', 'categoria': 'Lácteos / Yogurt', 'precio': 6.90, 'stock': 18, 'disponible': true},
    {'nombre': 'Yogurt BATIMIX GLORIA Vainilla con Hojuelas 145g', 'descripcion': 'Yogurt personal con cereal, ideal para loncheras.', 'categoria': 'Lácteos / Yogurt', 'precio': 3.50, 'stock': 22, 'disponible': true},
    {'nombre': 'Huevos de Gallina Pardos LA CALERA Plancha x 30 un', 'descripcion': 'Cartón de huevos frescos medianos.', 'categoria': 'Abarrotes / Frescos', 'precio': 16.50, 'stock': 5, 'disponible': true},
    {'nombre': 'Atún en Aceite FLORIDA Lata 170g', 'descripcion': 'Trozos de atún en aceite vegetal, indispensable en despensa.', 'categoria': 'Abarrotes / Conservas', 'precio': 6.50, 'stock': 28, 'disponible': true},
    {'nombre': 'Filete de Caballa CAMPOMAR Lata 170g', 'descripcion': 'Pescado en conserva rico en Omega 3, alternativa económica.', 'categoria': 'Abarrotes / Conservas', 'precio': 4.20, 'stock': 15, 'disponible': true},
    {'nombre': 'Duraznos en Mitades ACONCAGUA Lata 820g', 'descripcion': 'Conserva de fruta dulce en almíbar.', 'categoria': 'Abarrotes / Conservas', 'precio': 9.50, 'stock': 10, 'disponible': true},
    {'nombre': 'Mayonesa ALACENA Doypack 95g', 'descripcion': 'Mayonesa con toque de limón peruano en sachet.', 'categoria': 'Salsas / Mayonesa', 'precio': 2.80, 'stock': 35, 'disponible': true},
    {'nombre': "Ketchup LIBBY'S Doypack 100g", 'descripcion': 'Salsa de tomate dulce para acompañar comidas.', 'categoria': 'Salsas / Ketchup', 'precio': 2.50, 'stock': 20, 'disponible': true},
    {'nombre': 'Mostaza ALACENA Doypack 100g', 'descripcion': 'Salsa de mostaza tradicional.', 'categoria': 'Salsas / Mostaza', 'precio': 2.20, 'stock': 18, 'disponible': true},
    {'nombre': 'Salsa de Ají TARÍ Doypack 85g', 'descripcion': 'Crema de ají con receta de pollería peruana.', 'categoria': 'Salsas / Cremas', 'precio': 3.00, 'stock': 25, 'disponible': true},
    {'nombre': 'Pasta de Tomate POMAROLA Sobre 145g', 'descripcion': 'Salsa lista para aderezos y tallarines.', 'categoria': 'Salsas / Tomate', 'precio': 2.50, 'stock': 22, 'disponible': true},
    {'nombre': 'Sillao KIKKO Botella Plástica 250ml', 'descripcion': 'Salsa de soya oscura para comidas orientales y criollas.', 'categoria': 'Salsas / Sillao', 'precio': 3.80, 'stock': 14, 'disponible': true},
    {'nombre': 'Vinagre Tinto BULNES Botella 500ml', 'descripcion': 'Vinagre para aderezos y ensaladas.', 'categoria': 'Abarrotes / Aderezos', 'precio': 2.50, 'stock': 12, 'disponible': true},
    {'nombre': 'Sazonador AJINOMOTO Sobre 50g', 'descripcion': 'Glutamato monosódico para realzar el sabor.', 'categoria': 'Abarrotes / Aderezos', 'precio': 1.50, 'stock': 45, 'disponible': true},
    {'nombre': 'Caldo de Gallina MAGGI Cubito (Display x 8)', 'descripcion': 'Cubitos concentrados para sopas y guisos.', 'categoria': 'Abarrotes / Aderezos', 'precio': 2.50, 'stock': 30, 'disponible': true},
    {'nombre': 'Pimienta Sibarita Sobre 10g', 'descripcion': 'Pimienta negra molida lista para usar.', 'categoria': 'Abarrotes / Condimentos', 'precio': 0.50, 'stock': 55, 'disponible': true},
    {'nombre': 'Colorante PANCA SIN PICANTE Sibarita Sobre 10g', 'descripcion': 'Ají panca molido sin picante para aderezos de color.', 'categoria': 'Abarrotes / Condimentos', 'precio': 0.50, 'stock': 50, 'disponible': true},
    {'nombre': 'Fideos ANITA Codito Bolsa 250g', 'descripcion': 'Pasta corta ideal para sopas y guisos.', 'categoria': 'Abarrotes / Pastas', 'precio': 1.80, 'stock': 28, 'disponible': true},
    {'nombre': 'Lenteja Bebé Costeño Bolsa 500g', 'descripcion': 'Menestra de cocción rápida y alto valor nutricional.', 'categoria': 'Abarrotes / Menestras', 'precio': 4.80, 'stock': 20, 'disponible': true},
    {'nombre': 'Arveja Partida Verde Costeño Bolsa 500g', 'descripcion': 'Menestra seca tradicional peruana.', 'categoria': 'Abarrotes / Menestras', 'precio': 3.50, 'stock': 18, 'disponible': true},
    {'nombre': 'Frijol Castilla Costeño Bolsa 500g', 'descripcion': 'Menestra suave muy consumida a nivel nacional.', 'categoria': 'Abarrotes / Menestras', 'precio': 4.50, 'stock': 15, 'disponible': true},
    {'nombre': 'Aceite COCINERO Botella 900ml', 'descripcion': 'Aceite de soya rendidor y económico.', 'categoria': 'Abarrotes / Aceites', 'precio': 8.50, 'stock': 22, 'disponible': true},
    {'nombre': 'Azúcar Blanca PARAMONGA Bolsa 1Kg', 'descripcion': 'Azúcar refinada para repostería y bebidas claras.', 'categoria': 'Abarrotes / Azúcar', 'precio': 4.50, 'stock': 25, 'disponible': true},
    {'nombre': 'Sal de Mesa MARINA Bolsa 1Kg', 'descripcion': 'Sal yodada y fluorada básica de cocina.', 'categoria': 'Abarrotes / Sal', 'precio': 1.50, 'stock': 40, 'disponible': true},
    {'nombre': 'Pan de Molde Blanco BIMBO Bolsa 480g', 'descripcion': 'Pan tajado clásico para el desayuno.', 'categoria': 'Panadería / Envasados', 'precio': 7.50, 'stock': 10, 'disponible': true},
    {'nombre': 'Pan Integral BIMBO Bolsa 480g', 'descripcion': 'Pan en tajadas con fibra dietética.', 'categoria': 'Panadería / Envasados', 'precio': 8.50, 'stock': 8, 'disponible': true},
    {'nombre': 'Mermelada de Fresa FANNY Pote 340g', 'descripcion': 'Mermelada untable tradicional de fruta.', 'categoria': 'Desayuno / Mermeladas', 'precio': 4.50, 'stock': 14, 'disponible': true},
    {'nombre': 'Manjarblanco NESTLÉ Pote 200g', 'descripcion': 'Dulce de leche para postres y panes.', 'categoria': 'Desayuno / Untables', 'precio': 5.50, 'stock': 12, 'disponible': true},
    {'nombre': 'Avena QUAKER Tradicional Bolsa 150g', 'descripcion': 'Hojuelas de avena para hervir.', 'categoria': 'Desayuno / Avena', 'precio': 2.50, 'stock': 30, 'disponible': true},
    {'nombre': 'Café NESCAFÉ Tradición Frasco 50g', 'descripcion': 'Café soluble instantáneo de sabor fuerte.', 'categoria': 'Desayuno / Café', 'precio': 8.50, 'stock': 15, 'disponible': true},
    {'nombre': 'Infusión Té y Canela MCCOLINS Caja 25 Sobres', 'descripcion': 'Té negro tradicional peruano en filtrantes.', 'categoria': 'Desayuno / Infusiones', 'precio': 3.50, 'stock': 20, 'disponible': true},
    {'nombre': 'Infusión Manzanilla HORNIMANS Caja 25 Sobres', 'descripcion': 'Hierba natural digestiva en filtrantes.', 'categoria': 'Desayuno / Infusiones', 'precio': 4.00, 'stock': 18, 'disponible': true},
    {'nombre': "Cocoa WINTER'S Sobre 50g", 'descripcion': 'Cacao endulzado para preparar bebida caliente.', 'categoria': 'Desayuno / Modificadores', 'precio': 2.00, 'stock': 25, 'disponible': true},
    {'nombre': 'Agua SAN LUIS Sin Gas Botella 625ml', 'descripcion': 'Agua de mesa purificada personal.', 'categoria': 'Bebidas / Aguas', 'precio': 1.50, 'stock': 48, 'disponible': true},
    {'nombre': 'Agua CIELO Sin Gas Botella 2.5 Litros', 'descripcion': 'Agua de mesa en formato familiar económico.', 'categoria': 'Bebidas / Aguas', 'precio': 3.00, 'stock': 20, 'disponible': true},
    {'nombre': 'Gaseosa COCA-COLA Botella 3 Litros', 'descripcion': 'Gaseosa oscura sabor cola formato familiar.', 'categoria': 'Bebidas / Gaseosas', 'precio': 11.50, 'stock': 15, 'disponible': true},
    {'nombre': 'Gaseosa INCA KOLA Botella 1.5 Litros', 'descripcion': 'Gaseosa amarilla de consumo masivo para almuerzos.', 'categoria': 'Bebidas / Gaseosas', 'precio': 6.50, 'stock': 20, 'disponible': true},
    {'nombre': 'Jugo FRUGOS DEL VALLE Durazno Caja 1 Litro', 'descripcion': 'Néctar de durazno en envase tetrapack.', 'categoria': 'Bebidas / Jugos', 'precio': 4.50, 'stock': 18, 'disponible': true},
    {'nombre': 'Bebida Rehidratante GATORADE Tropical Botella 500ml', 'descripcion': 'Bebida isotónica deportiva.', 'categoria': 'Bebidas / Rehidratantes', 'precio': 2.80, 'stock': 22, 'disponible': true},
    {'nombre': 'MALTIN POWER Botella 330ml', 'descripcion': 'Bebida de malta energizante sin alcohol.', 'categoria': 'Bebidas / Energizantes', 'precio': 2.00, 'stock': 30, 'disponible': true},
    {'nombre': 'Cerveza PILSEN CALLAO Lata 355ml (Six Pack)', 'descripcion': 'Cerveza rubia tradicional en lata.', 'categoria': 'Bebidas / Cervezas', 'precio': 22.00, 'stock': 10, 'disponible': true},
    {'nombre': 'Cerveza CRISTAL Botella 650ml', 'descripcion': 'Cerveza rubia formato grande (retornable).', 'categoria': 'Bebidas / Cervezas', 'precio': 6.50, 'stock': 2, 'disponible': true},
    {'nombre': 'Leche Purita Nutritiva PURA VIDA Lata 395g', 'descripcion': 'Mezcla láctea fortificada económica.', 'categoria': 'Lácteos / Leche', 'precio': 3.20, 'stock': 35, 'disponible': true},
    {'nombre': 'Chocolatina SUBLIME Clásico 30g', 'descripcion': 'Chocolate con maní de alta rotación.', 'categoria': 'Snacks / Chocolates', 'precio': 1.50, 'stock': 40, 'disponible': true},
    {'nombre': "Chocolate TRIÁNGULO D'Onofrio 30g", 'descripcion': 'Chocolate de leche macizo.', 'categoria': 'Snacks / Chocolates', 'precio': 1.50, 'stock': 35, 'disponible': true},
    {'nombre': "Besa de Moza D'ONOFRIO Caja x 9", 'descripcion': 'Dulce de merengue bañado en chocolate.', 'categoria': 'Snacks / Chocolates', 'precio': 10.50, 'stock': 8, 'disponible': true},
    {'nombre': 'Gelatina UNIVERSAL Fresa Sobre 150g', 'descripcion': 'Postre en polvo de rápida preparación.', 'categoria': 'Abarrotes / Postres', 'precio': 3.00, 'stock': 25, 'disponible': true},
    {'nombre': 'Flan Vainilla UNIVERSAL Sobre 100g', 'descripcion': 'Polvo para preparar flan clásico.', 'categoria': 'Abarrotes / Postres', 'precio': 3.00, 'stock': 20, 'disponible': true},
    {'nombre': 'Mazamorra Morada UNIVERSAL Sobre 150g', 'descripcion': 'Polvo para preparar postre tradicional limeño.', 'categoria': 'Abarrotes / Postres', 'precio': 3.50, 'stock': 18, 'disponible': true},
    {'nombre': 'Sopa Instantánea AJINOMEN Pollo Paquete 85g', 'descripcion': 'Fideos ramen de cocción rápida en 3 minutos.', 'categoria': 'Abarrotes / Sopas', 'precio': 1.20, 'stock': 45, 'disponible': true},
    {'nombre': 'Papel Higiénico SUAVE Doble Hoja Paquete 2 unidades', 'descripcion': 'Papel higiénico de hoja doble básico.', 'categoria': 'Limpieza / Papel', 'precio': 2.50, 'stock': 30, 'disponible': true},
    {'nombre': 'Papel Toalla ELITE Rollo Simple', 'descripcion': 'Rollo de papel absorbente para cocina.', 'categoria': 'Limpieza / Papel', 'precio': 3.00, 'stock': 20, 'disponible': true},
    {'nombre': 'Detergente en Polvo BOLÍVAR Active Care Bolsa 150g', 'descripcion': 'Detergente para lavado a mano o lavadora en sachet.', 'categoria': 'Limpieza / Detergentes', 'precio': 1.80, 'stock': 35, 'disponible': true},
    {'nombre': 'Detergente ARIEL Doble Poder Bolsa 140g', 'descripcion': 'Detergente con quitamanchas en presentación pequeña.', 'categoria': 'Limpieza / Detergentes', 'precio': 1.90, 'stock': 28, 'disponible': true},
    {'nombre': 'Lejía CLOROX Clásica Botella 1Kg', 'descripcion': 'Desinfectante y blanqueador multiusos.', 'categoria': 'Limpieza / Desinfectantes', 'precio': 3.20, 'stock': 18, 'disponible': true},
    {'nombre': 'Lavavajillas en Pasta AYUDÍN Limón Pote 350g', 'descripcion': 'Pasta lavavajillas de alta eficacia y rotación.', 'categoria': 'Limpieza / Lavavajillas', 'precio': 4.50, 'stock': 15, 'disponible': true},
    {'nombre': 'Jabón de Tocador PROTEX Avena Unidad 110g', 'descripcion': 'Jabón antibacterial de uso personal.', 'categoria': 'Cuidado Personal / Jabones', 'precio': 2.50, 'stock': 22, 'disponible': true},
    {'nombre': 'Jabón de Lavar BOLÍVAR Barra 160g', 'descripcion': 'Jabón de lavandería suave para la ropa.', 'categoria': 'Limpieza / Jabones', 'precio': 2.00, 'stock': 25, 'disponible': true},
    {'nombre': 'Pasta Dental COLGATE Triple Acción Tubo 75ml', 'descripcion': 'Crema dental de protección anticaries.', 'categoria': 'Cuidado Personal / Cuidado Bucal', 'precio': 3.50, 'stock': 20, 'disponible': true},
    {'nombre': 'Shampoo HEAD & SHOULDERS Limpieza Renovadora Sachet 15ml', 'descripcion': 'Shampoo anticaspa en presentación económica sachet.', 'categoria': 'Cuidado Personal / Cabello', 'precio': 1.00, 'stock': 50, 'disponible': true},
    {'nombre': 'Shampoo SEDAL Ceramidas Botella 340ml', 'descripcion': 'Shampoo para restauración del cabello.', 'categoria': 'Cuidado Personal / Cabello', 'precio': 14.50, 'stock': 0, 'disponible': false},
    {'nombre': 'Limpiador de Pisos POETT Bebé Botella 900ml', 'descripcion': 'Limpiador líquido aromatizante para el hogar.', 'categoria': 'Limpieza / Limpiadores', 'precio': 4.00, 'stock': 12, 'disponible': true},
    {'nombre': 'Fósforos INTI Caja chica', 'descripcion': 'Caja de fósforos de madera clásica.', 'categoria': 'Abarrotes / Básicos', 'precio': 0.50, 'stock': 60, 'disponible': true},
    {'nombre': 'Velas MISIONERA Paquete x 4', 'descripcion': 'Velas blancas de parafina estriadas.', 'categoria': 'Abarrotes / Básicos', 'precio': 2.50, 'stock': 20, 'disponible': true},
  ];
}
