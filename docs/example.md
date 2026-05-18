Plaintext
Actúa como un desarrollador experto en Flutter y Firebase. Tu objetivo es desarrollar una aplicación móvil llamada "miempresa" siguiendo estrictamente los requerimientos, la estructura y los bloques de código que te proporcionaré a continuación. 

La aplicación debe permitir:
1. Mostrar una lista de productos desde Firestore.
2. Buscar productos.
3. Agregar productos a un carrito de compras (con una animación en el ícono del carrito).
4. Ver la ubicación de la tienda y la del usuario en un mapa (Google Maps), trazando la ruta entre ambos puntos.

A continuación, ejecuta la implementación paso a paso respetando el siguiente código y configuraciones:

### PASO 1: Configuración del Proyecto y Dependencias
Crea un proyecto Flutter llamado `miempresa`. En el archivo `pubspec.yaml`, asegúrate de incluir las siguientes dependencias y entorno:

```yaml
environment:
  sdk: 3.7.2

dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^3.13.0
  cloud_firestore: ^5.6.7
  google_maps_flutter: ^2.5.3 # Inferido para mapas
  geolocator: ^10.1.0 # Inferido para ubicación
  http: ^1.1.0 # Inferido para peticiones de ruta

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: 5.0.0
PASO 2: Configuración de Firebase y Android
Aplica la configuración de Google Services para Android.
En android/build.gradle:

Gradle
plugins {
    id("com.google.gms.google-services") version "4.4.2" apply false
}
En android/app/build.gradle:

Gradle
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:33.13.0"))
}
En android/app/src/main/AndroidManifest.xml, añade los permisos y el API Key de Google Maps (dentro del tag <application>):

XML
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" /> 
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>

<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="AIzaSyBIZrptkE0IGakPhzMzMpq4PaW_gw_Dlvk"/>
PASO 3: Implementación de la Pantalla de Productos (productos_screen.dart)
Crea un StatefulWidget llamado ProductosScreen. Debe tener:

Una lista productos y una lista productosFiltrados.

Una lista carrito para almacenar los items agregados.

Un método obtenerProductos() que use FirebaseFirestore.instance.collection('productos').get() para mapear los documentos a las listas.

Un TextEditingController y un método filtrarProductos(String texto) para buscar localmente por nombre.

Un método agregarAlCarrito(Map<String, dynamic> producto) que inserte el producto en la lista carrito y lance un SnackBar confirmando la acción.

Una animación (AnimationController y Tween<double> scaleAnimation) para hacer un efecto de rebote en el ícono del carrito en el AppBar cuando se agrega un producto.

Un botón en el AppBar (dentro de un Stack con un contador que indica carrito.length) que navegue a CarritoScreen(carrito: carrito) usando Navigator.push.

Respeta esta estructura para la UI de búsqueda y el listado en el body:

Dart
Column(
  children: [
    Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: searchController,
        onChanged: filtrarProductos,
        decoration: InputDecoration(
          labelText: 'Buscar producto...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    ),
    Expanded(
      child: productosFiltrados.isEmpty
          ? const Center(child: Text('No se encontraron productos'))
          : ListView.builder(
              itemCount: productosFiltrados.length,
              itemBuilder: (context, index) {
                final producto = productosFiltrados[index];
                return ListTile(
                  title: Text(producto['nombre'] ?? 'Sin nombre'),
                  subtitle: Text('S/\${producto['precio'] ?? '0.00'}'),
                  onTap: () => agregarAlCarrito(producto), // Asume onTap para agregar
                );
              },
            ),
    ),
  ],
)
PASO 4: Implementación de la Pantalla del Mapa (tienda_screen.dart)
Crea la clase TiendaScreen que reciba el carrito por parámetro:

Dart
class TiendaScreen extends StatefulWidget {
  final List<Map<String, dynamic>> carrito;
  const TiendaScreen({super.key, required this.carrito});
  
  @override
  State<TiendaScreen> createState() => _TiendaScreenState();
}
En el estado _TiendaScreenState, implementa lo siguiente:

Variables: LatLng? ubicacionUsuario, LatLng? ubicacionTienda, GoogleMapController? mapController, Set<Polyline> polylines = {}.

Un método obtenerUbicacionUsuario() usando Geolocator (verifica si el servicio está habilitado y si tienes permisos, si no, solicítalos. Luego usa Geolocator.getCurrentPosition()).

Un método obtenerRuta() que haga un GET a la API de Directions de Google Maps (https://maps.googleapis.com/maps/api/directions/json?origin=$origen&destination=$destino&key=$apiKey&mode=driving). Decodifica la respuesta JSON y extrae data["routes"][0]["overview_polyline"]["points"]. Utiliza el algoritmo estándar de decodificación de Polyline para rellenar el Set<Polyline> polylines.

El AppBar debe tener el ícono del carrito con el contador leyendo widget.carrito.length y navegando al carrito.

El body debe mostrar un CircularProgressIndicator si las ubicaciones son nulas, o un GoogleMap que muestre los markers correspondientes y las polylines generadas.