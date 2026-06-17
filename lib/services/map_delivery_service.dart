import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../config/maps_config.dart';
import '../utils/geo_utils.dart';
import 'directions_service.dart';
import 'google_places_service.dart';

class RutaTiendaResultado {
  const RutaTiendaResultado({
    required this.tienda,
    required this.origen,
    required this.distanciaLineaMetros,
    required this.tiendasDisponibles,
    required this.radioBusquedaMetros,
    this.ruta,
    this.esFallback = false,
    this.aviso,
  });

  final TiendaWisaData tienda;
  final LatLng origen;
  final double distanciaLineaMetros;
  final List<TiendaWisaData> tiendasDisponibles;
  final int radioBusquedaMetros;
  final RutaDirections? ruta;
  final bool esFallback;
  final String? aviso;

  int get distanciaDeliveryMetros =>
      ruta?.distanciaMetros ?? distanciaLineaMetros.round();

  double get distanciaDeliveryKm => distanciaDeliveryMetros / 1000.0;

  int? get duracionDeliverySegundos => ruta?.duracionSegundos;

  String get distanciaDeliveryTexto =>
      ruta?.distanciaTexto ?? formatearDistanciaCorta(distanciaLineaMetros);

  String? get duracionDeliveryTexto => ruta?.duracionTexto;
}

class MapDeliveryService {
  MapDeliveryService({
    DirectionsService? directionsService,
    GooglePlacesService? placesService,
  })  : _directionsService = directionsService ?? DirectionsService(),
        _placesService = placesService ?? GooglePlacesService();

  final DirectionsService _directionsService;
  final GooglePlacesService _placesService;

  Future<RutaTiendaResultado> asignarTiendaOptima({
    required LatLng origen,
    ModoTransporte modo = ModoTransporte.driving,
  }) async {
    final resultadoTiendas = await _obtenerTiendasDisponibles(origen);
    final tiendas = resultadoTiendas.tiendas;
    if (tiendas.isEmpty) {
      throw Exception('No hay tiendas Wisa configuradas en Huancayo.');
    }

    final resultados = await Future.wait(
      tiendas.map(
        (tienda) => _consultarRuta(origen: origen, tienda: tienda, modo: modo),
      ),
    );

    final conRuta = resultados.whereType<RutaTiendaResultado>().toList()
      ..sort(
        (a, b) => a.distanciaDeliveryMetros.compareTo(b.distanciaDeliveryMetros),
      );

    if (conRuta.isNotEmpty) {
      final mejorRuta = conRuta.first;
      return RutaTiendaResultado(
        tienda: mejorRuta.tienda,
        origen: origen,
        distanciaLineaMetros: mejorRuta.distanciaLineaMetros,
        tiendasDisponibles: tiendas,
        radioBusquedaMetros: resultadoTiendas.radioBusquedaMetros,
        ruta: mejorRuta.ruta,
        esFallback: resultadoTiendas.esFallback,
        aviso: resultadoTiendas.aviso,
      );
    }

    final fallback = tiendaMasCercana(origen, tiendas);
    return RutaTiendaResultado(
      tienda: fallback,
      origen: origen,
      distanciaLineaMetros: distanciaMetros(origen, fallback.ubicacion),
      tiendasDisponibles: tiendas,
      radioBusquedaMetros: resultadoTiendas.radioBusquedaMetros,
      esFallback: true,
      aviso: resultadoTiendas.aviso ??
          'No se pudo calcular una ruta real. Usamos la tienda más cercana por distancia aproximada.',
    );
  }

  Future<RutaTiendaResultado> rutaParaTienda({
    required LatLng origen,
    required TiendaWisaData tienda,
    ModoTransporte modo = ModoTransporte.driving,
  }) async {
    final resultado = await _consultarRuta(
      origen: origen,
      tienda: tienda,
      modo: modo,
    );

    if (resultado != null) return resultado;

    return RutaTiendaResultado(
      tienda: tienda,
      origen: origen,
      distanciaLineaMetros: distanciaMetros(origen, tienda.ubicacion),
      tiendasDisponibles: [tienda],
      radioBusquedaMetros: tienda.radioBusquedaMetros ?? MapsConfig.radioCiudadMetros.round(),
      esFallback: true,
      aviso:
          'No se pudo calcular una ruta real hacia esta tienda. Mostramos una distancia aproximada.',
    );
  }

  Future<RutaTiendaResultado?> _consultarRuta({
    required LatLng origen,
    required TiendaWisaData tienda,
    required ModoTransporte modo,
  }) async {
    try {
      final ruta = await _directionsService.obtenerRuta(
        origen: origen,
        destino: tienda.ubicacion,
        modo: modo,
      );

      return RutaTiendaResultado(
        tienda: tienda,
        origen: origen,
        ruta: ruta,
        distanciaLineaMetros: distanciaMetros(origen, tienda.ubicacion),
        tiendasDisponibles: [tienda],
        radioBusquedaMetros:
            tienda.radioBusquedaMetros ?? MapsConfig.radioCiudadMetros.round(),
      );
    } catch (e) {
      debugPrint('No se pudo calcular ruta a ${tienda.id}: $e');
      return null;
    }
  }

  Future<ResultadoTiendasWisa> _obtenerTiendasDisponibles(LatLng origen) async {
    try {
      return await _placesService.buscarTiendasWisaCercanas(origen: origen);
    } catch (e) {
      debugPrint('No se pudo buscar tiendas Wisa en Places: $e');
      return ResultadoTiendasWisa(
        tiendas: MapsConfig.tiendasHuancayo,
        radioBusquedaMetros: MapsConfig.radioCiudadMetros.round(),
        esFallback: true,
        aviso:
            'No pudimos consultar Google Maps. Mostramos tiendas Wisa locales de respaldo.',
      );
    }
  }
}
