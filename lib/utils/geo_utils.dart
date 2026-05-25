import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../config/maps_config.dart';

/// Distancia en metros entre dos coordenadas (fórmula haversine).
double distanciaMetros(LatLng a, LatLng b) {
  const radioTierra = 6371000.0;
  final dLat = _gradosARadianes(b.latitude - a.latitude);
  final dLng = _gradosARadianes(b.longitude - a.longitude);
  final lat1 = _gradosARadianes(a.latitude);
  final lat2 = _gradosARadianes(b.latitude);

  final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1) * math.cos(lat2) * math.sin(dLng / 2) * math.sin(dLng / 2);
  final c = 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
  return radioTierra * c;
}

double _gradosARadianes(double grados) => grados * math.pi / 180;

/// True si el GPS está dentro del área metropolitana de Huancayo.
bool estaEnHuancayo(LatLng ubicacion) {
  return distanciaMetros(ubicacion, MapsConfig.centroHuancayo) <=
      MapsConfig.radioCiudadMetros;
}

/// Elige la tienda Wisa de Huancayo más cercana al usuario.
TiendaWisaData tiendaMasCercanaHuancayo(LatLng origen) {
  final tiendas = MapsConfig.tiendasHuancayo;
  if (tiendas.isEmpty) {
    throw Exception('No hay tiendas Wisa configuradas en Huancayo.');
  }

  TiendaWisaData masCercana = tiendas.first;
  double menorDistancia = double.infinity;

  for (final tienda in tiendas) {
    final dist = distanciaMetros(origen, tienda.ubicacion);
    if (dist < menorDistancia) {
      menorDistancia = dist;
      masCercana = tienda;
    }
  }

  return masCercana;
}

String formatearDistanciaLinea(double metros) {
  if (metros < 1000) {
    return '${metros.round()} m en línea recta';
  }
  return '${(metros / 1000).toStringAsFixed(1)} km en línea recta';
}

String formatearDistanciaCorta(double metros) {
  if (metros < 1000) {
    return '${metros.round()} m';
  }
  return '${(metros / 1000).toStringAsFixed(1)} km';
}

/// Tiendas Wisa en Huancayo ordenadas de la más cercana a la más lejana.
List<TiendaConDistancia> tiendasOrdenadasPorDistancia(LatLng origen) {
  return MapsConfig.tiendasHuancayo
      .map(
        (t) => TiendaConDistancia(
          tienda: t,
          distanciaMetros: distanciaMetros(origen, t.ubicacion),
        ),
      )
      .toList()
    ..sort((a, b) => a.distanciaMetros.compareTo(b.distanciaMetros));
}

class TiendaConDistancia {
  const TiendaConDistancia({
    required this.tienda,
    required this.distanciaMetros,
  });

  final TiendaWisaData tienda;
  final double distanciaMetros;
}
