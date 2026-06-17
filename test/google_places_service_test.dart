import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:minimarket/services/google_places_service.dart';

void main() {
  test('buscarTiendasWisaCercanas filters only Wisa places', () async {
    final client = _FakePlacesClient([
      http.Response(
        '''
        {
          "status": "OK",
          "results": [
            {
              "name": "Wisa Real y Tello",
              "place_id": "place-wisa-1",
              "formatted_address": "Calle Real 701",
              "rating": 4.5,
              "geometry": { "location": { "lat": -12.059707, "lng": -75.2159385 } }
            },
            {
              "name": "Otra tienda",
              "place_id": "place-other",
              "formatted_address": "Otra direccion",
              "geometry": { "location": { "lat": -12.0, "lng": -75.0 } }
            }
          ]
        }
        ''',
        200,
      ),
    ]);
    final service = GooglePlacesService(client: client);

    final resultado = await service.buscarTiendasWisaCercanas(
      origen: const LatLng(-12.0597, -75.2159),
    );

    expect(resultado.tiendas, hasLength(1));
    expect(resultado.tiendas.first.nombre, 'Wisa Real y Tello');
    expect(resultado.tiendas.first.placeId, 'place-wisa-1');
    expect(resultado.tiendas.first.fuente, 'google_places');
    expect(resultado.tiendas.first.radioBusquedaMetros, 5000);
  });

  test('buscarTiendasWisaCercanas expands radius when first search is empty', () async {
    final client = _FakePlacesClient([
      http.Response('{"status":"ZERO_RESULTS","results":[]}', 200),
      http.Response(
        '''
        {
          "status": "OK",
          "results": [
            {
              "name": "Wisa Chilca",
              "place_id": "place-wisa-2",
              "formatted_address": "Av. Huancavelica 723",
              "geometry": { "location": { "lat": -12.086691, "lng": -75.208143 } }
            }
          ]
        }
        ''',
        200,
      ),
    ]);
    final service = GooglePlacesService(client: client);

    final resultado = await service.buscarTiendasWisaCercanas(
      origen: const LatLng(-12.0597, -75.2159),
    );

    expect(resultado.tiendas.single.nombre, 'Wisa Chilca');
    expect(resultado.radioBusquedaMetros, 10000);
    expect(resultado.aviso, contains('ampliamos'));
    expect(client.requestedRadii, [5000, 10000]);
  });
}

class _FakePlacesClient extends http.BaseClient {
  _FakePlacesClient(this._responses);

  final List<http.Response> _responses;
  final List<int> requestedRadii = [];
  int _index = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requestedRadii.add(int.parse(request.url.queryParameters['radius']!));
    final response = _responses[_index++];
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
      request: request,
    );
  }
}
