import 'package:flutter_test/flutter_test.dart';
import 'package:minimarket/services/delivery_service.dart';

void main() {
  group('DeliveryService.calcularCostoDelivery', () {
    test('uses distance tiers for Vecino users', () {
      expect(
        DeliveryService.calcularCostoDelivery(
          distanciaKm: 1.5,
          puntosUsuario: 0,
          totalProductos: 20,
        ),
        3.0,
      );
      expect(
        DeliveryService.calcularCostoDelivery(
          distanciaKm: 7,
          puntosUsuario: 0,
          totalProductos: 20,
        ),
        8.0,
      );
    });

    test('applies free delivery by purchase amount', () {
      expect(
        DeliveryService.calcularCostoDelivery(
          distanciaKm: 12,
          puntosUsuario: 0,
          totalProductos: 50,
        ),
        0.0,
      );
    });

    test('applies loyalty delivery benefits', () {
      expect(
        DeliveryService.calcularCostoDelivery(
          distanciaKm: 7,
          puntosUsuario: 50,
          totalProductos: 20,
        ),
        4.0,
      );
      expect(
        DeliveryService.calcularCostoDelivery(
          distanciaKm: 12,
          puntosUsuario: 150,
          totalProductos: 20,
        ),
        0.0,
      );
    });
  });
}
