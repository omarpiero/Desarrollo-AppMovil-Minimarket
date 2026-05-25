import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Mapas y tiendas Wisa — solo Huancayo, Junín (Perú).
///
/// Sucursales tomadas de Google Maps (capturas del equipo).
/// Coordenadas vía Geocoding API de Google.
class MapsConfig {
  static const String googleMapsApiKey = 'AIzaSyBIZrptkE0IGakPhzMzMpq4PaW_gw_D1vk';

  static const String ciudad = 'Huancayo';
  static const String departamento = 'Junín';
  static const String pais = 'Perú';

  static const LatLng centroHuancayo = LatLng(-12.066667, -75.216667);
  static const double radioCiudadMetros = 25000;

  static const LatLng universidadContinental = LatLng(-12.0475111, -75.1990635);

  static const List<TiendaWisaData> tiendasHuancayo = [
    TiendaWisaData(
      id: 'wisa-real-sumar',
      nombre: 'Wisa Real y Sumar',
      direccion: 'Mariscal Castilla (Real) 1976, Huancayo 12001',
      ciudad: ciudad,
      ubicacion: LatLng(-12.0498924, -75.2217852),
    ),
    TiendaWisaData(
      id: 'wisa-chilca',
      nombre: 'Wisa Chilca',
      direccion: 'Av. Huancavelica 723, Chilca 12003',
      ciudad: ciudad,
      ubicacion: LatLng(-12.086691, -75.208143),
    ),
    TiendaWisaData(
      id: 'wisa-upla',
      nombre: 'Wisa Upla',
      direccion: 'Av. Calmell del Solar 1811, Huancayo 12001',
      ciudad: ciudad,
      ubicacion: LatLng(-12.0431966, -75.1935853),
    ),
    TiendaWisaData(
      id: 'wisa-centenario',
      nombre: 'Wisa Centenario',
      direccion: 'Jr. José Gálvez 257, Huancayo 12001',
      ciudad: ciudad,
      ubicacion: LatLng(-12.0597394, -75.2005457),
    ),
    TiendaWisaData(
      id: 'wisa-real-tello',
      nombre: 'Wisa Real y Tello',
      direccion: 'Calle Real 701, Huancayo 12004',
      ciudad: ciudad,
      ubicacion: LatLng(-12.059707, -75.2159385),
    ),
    TiendaWisaData(
      id: 'wisa-hvca-brena',
      nombre: 'Wisa Hvca y Breña',
      direccion: 'Pasaje La Breña 340, Huancayo 12001',
      ciudad: ciudad,
      ubicacion: LatLng(-12.069652, -75.2123137),
    ),
    TiendaWisaData(
      id: 'wisa-francisca-calle',
      nombre: 'Wisa Francisca de la Calle',
      direccion: 'Av. Francisca de la Calle 197, Huancayo 12001',
      ciudad: ciudad,
      ubicacion: LatLng(-12.0445515, -75.2032689),
    ),
  ];

  static const CameraPosition camaraInicialHuancayo = CameraPosition(
    target: centroHuancayo,
    zoom: 13,
  );
}

class TiendaWisaData {
  const TiendaWisaData({
    required this.id,
    required this.nombre,
    required this.direccion,
    required this.ciudad,
    required this.ubicacion,
  });

  final String id;
  final String nombre;
  final String direccion;
  final String ciudad;
  final LatLng ubicacion;

  String get etiquetaCompleta =>
      '$nombre — $ciudad, ${MapsConfig.departamento}';
}
