import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../config/maps_config.dart';
import '../utils/polyline_decoder.dart';

enum ModoTransporte { driving, walking }

/// Modos disponibles en la app (bici y transporte suelen dar ZERO_RESULTS en Huancayo).
const List<ModoTransporte> modosDisponibles = ModoTransporte.values;

extension ModoTransporteApi on ModoTransporte {
  String get apiValue {
    switch (this) {
      case ModoTransporte.driving:
        return 'driving';
      case ModoTransporte.walking:
        return 'walking';
    }
  }

  String get etiqueta {
    switch (this) {
      case ModoTransporte.driving:
        return 'En auto';
      case ModoTransporte.walking:
        return 'A pie';
    }
  }
}

class RutaDirections {
  const RutaDirections({
    required this.distanciaTexto,
    required this.duracionTexto,
    required this.distanciaMetros,
    required this.duracionSegundos,
    required this.puntos,
    this.direccionDestino,
  });

  final String distanciaTexto;
  final String duracionTexto;
  final int distanciaMetros;
  final int duracionSegundos;
  final List<LatLng> puntos;
  final String? direccionDestino;
}

class DirectionsService {
  Future<RutaDirections> obtenerRuta({
    required LatLng origen,
    required LatLng destino,
    required ModoTransporte modo,
  }) async {
    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/directions/json',
      {
        'origin': '${origen.latitude},${origen.longitude}',
        'destination': '${destino.latitude},${destino.longitude}',
        'key': MapsConfig.googleMapsApiKey,
        'mode': modo.apiValue,
        'language': 'es',
        'region': 'pe',
      },
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Error HTTP ${response.statusCode} al consultar la ruta.');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final status = data['status'] as String? ?? 'UNKNOWN';

    if (status != 'OK') {
      if (status == 'ZERO_RESULTS') {
        throw Exception(
          'No hay ruta en ${modo.etiqueta.toLowerCase()} para este trayecto. '
          'Prueba con otro modo.',
        );
      }
      final error = data['error_message'] as String?;
      throw Exception(
        error ?? 'La API de Directions respondió: $status',
      );
    }

    final routes = data['routes'] as List<dynamic>?;
    if (routes == null || routes.isEmpty) {
      throw Exception('No se encontró ninguna ruta.');
    }

    final route = routes.first as Map<String, dynamic>;
    final legs = route['legs'] as List<dynamic>?;
    if (legs == null || legs.isEmpty) {
      throw Exception('La ruta no tiene tramos (legs).');
    }

    final leg = legs.first as Map<String, dynamic>;
    final distance = leg['distance'] as Map<String, dynamic>;
    final duration = leg['duration'] as Map<String, dynamic>;
    final overview = route['overview_polyline'] as Map<String, dynamic>?;
    final encoded = overview?['points'] as String?;

    if (encoded == null || encoded.isEmpty) {
      throw Exception('No se recibió el polyline de la ruta.');
    }

    return RutaDirections(
      distanciaTexto: distance['text'] as String? ?? '',
      duracionTexto: duration['text'] as String? ?? '',
      distanciaMetros: (distance['value'] as num?)?.toInt() ?? 0,
      duracionSegundos: (duration['value'] as num?)?.toInt() ?? 0,
      puntos: decodePolyline(encoded),
      direccionDestino: leg['end_address'] as String?,
    );
  }

  ModoTransporte modoSugerido(double distanciaMetrosLinea) {
    if (distanciaMetrosLinea <= 2000) return ModoTransporte.walking;
    return ModoTransporte.driving;
  }
}
