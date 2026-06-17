import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../config/maps_config.dart';

class ResultadoTiendasWisa {
  const ResultadoTiendasWisa({
    required this.tiendas,
    required this.radioBusquedaMetros,
    required this.esFallback,
    this.aviso,
  });

  final List<TiendaWisaData> tiendas;
  final int radioBusquedaMetros;
  final bool esFallback;
  final String? aviso;
}

class GooglePlacesService {
  GooglePlacesService({
    http.Client? client,
    List<int> radiosBusquedaMetros = const [5000, 10000, 25000],
  })  : _client = client ?? http.Client(),
        _radiosBusquedaMetros = radiosBusquedaMetros;

  final http.Client _client;
  final List<int> _radiosBusquedaMetros;

  Future<ResultadoTiendasWisa> buscarTiendasWisaCercanas({
    required LatLng origen,
  }) async {
    Exception? ultimoError;

    for (final radio in _radiosBusquedaMetros) {
      try {
        final tiendas = await _buscarEnRadio(origen: origen, radio: radio);
        if (tiendas.isNotEmpty) {
          return ResultadoTiendasWisa(
            tiendas: tiendas,
            radioBusquedaMetros: radio,
            esFallback: false,
            aviso: radio > _radiosBusquedaMetros.first
                ? 'No encontramos Wisa en 5 km; ampliamos la búsqueda a ${(radio / 1000).round()} km.'
                : null,
          );
        }
      } catch (e) {
        ultimoError = e is Exception ? e : Exception(e.toString());
      }
    }

    throw ultimoError ??
        Exception('No encontramos tiendas Wisa cercanas en Google Maps.');
  }

  Future<List<TiendaWisaData>> _buscarEnRadio({
    required LatLng origen,
    required int radio,
  }) async {
    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/textsearch/json',
      {
        'query': 'Wisa',
        'location': '${origen.latitude},${origen.longitude}',
        'radius': '$radio',
        'key': MapsConfig.googleMapsApiKey,
        'language': 'es',
        'region': 'pe',
      },
    );

    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Error HTTP ${response.statusCode} al buscar tiendas.');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final status = data['status'] as String? ?? 'UNKNOWN';

    if (status == 'ZERO_RESULTS') return [];
    if (status != 'OK') {
      final error = data['error_message'] as String?;
      throw Exception(error ?? 'Places respondió: $status');
    }

    final results = data['results'] as List<dynamic>? ?? [];
    final tiendas = results
        .whereType<Map<String, dynamic>>()
        .map((item) => _tiendaDesdePlace(item, radio))
        .whereType<TiendaWisaData>()
        .toList();

    final porId = <String, TiendaWisaData>{};
    for (final tienda in tiendas) {
      porId[tienda.placeId ?? tienda.id] = tienda;
    }
    return porId.values.toList();
  }

  TiendaWisaData? _tiendaDesdePlace(
    Map<String, dynamic> place,
    int radioBusquedaMetros,
  ) {
    final nombre = place['name'] as String? ?? '';
    if (!nombre.toLowerCase().contains('wisa')) return null;

    final geometry = place['geometry'] as Map<String, dynamic>?;
    final location = geometry?['location'] as Map<String, dynamic>?;
    final lat = (location?['lat'] as num?)?.toDouble();
    final lng = (location?['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) return null;

    final placeId = place['place_id'] as String?;
    final direccion = place['formatted_address'] as String? ??
        place['vicinity'] as String? ??
        'Dirección no disponible';

    return TiendaWisaData(
      id: placeId ?? _normalizarId(nombre),
      placeId: placeId,
      nombre: nombre,
      direccion: direccion,
      ciudad: MapsConfig.ciudad,
      ubicacion: LatLng(lat, lng),
      fuente: 'google_places',
      radioBusquedaMetros: radioBusquedaMetros,
      rating: (place['rating'] as num?)?.toDouble(),
    );
  }

  String _normalizarId(String value) {
    final cleaned = value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return cleaned.isEmpty ? 'wisa-place' : cleaned;
  }
}
