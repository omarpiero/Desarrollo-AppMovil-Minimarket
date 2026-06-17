import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:minimarket/config/maps_config.dart';
import 'package:minimarket/utils/geo_utils.dart';

void main() {
  test('distanciaMetros returns zero for the same point', () {
    final distancia = distanciaMetros(
      MapsConfig.centroHuancayo,
      MapsConfig.centroHuancayo,
    );

    expect(distancia, closeTo(0, 0.01));
  });

  test('tiendaMasCercanaHuancayo returns the closest configured store', () {
    const origen = LatLng(-12.05970, -75.21594);

    final tienda = tiendaMasCercanaHuancayo(origen);

    expect(tienda.id, 'wisa-real-tello');
  });

  test('tiendasOrdenadasPorDistancia sorts stores by distance', () {
    const origen = LatLng(-12.05970, -75.21594);

    final tiendas = tiendasOrdenadasPorDistancia(origen);

    expect(tiendas, isNotEmpty);
    expect(tiendas.first.tienda.id, 'wisa-real-tello');
    expect(tiendas.first.distanciaMetros <= tiendas.last.distanciaMetros, isTrue);
  });
}
