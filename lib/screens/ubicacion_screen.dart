import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/maps_config.dart';
import '../config/theme.dart';
import '../services/directions_service.dart';
import '../utils/geo_utils.dart';

class UbicacionScreen extends StatefulWidget {
  const UbicacionScreen({super.key, required this.activa});

  /// Solo true cuando el usuario está en la pestaña Ubicación.
  final bool activa;

  @override
  State<UbicacionScreen> createState() => _UbicacionScreenState();
}

class _UbicacionScreenState extends State<UbicacionScreen> {
  final DirectionsService _directionsService = DirectionsService();

  GoogleMapController? _mapController;
  LatLng? _ubicacionUsuario;
  TiendaWisaData? _tiendaDestino;
  RutaDirections? _ruta;
  ModoTransporte _modo = ModoTransporte.walking;

  bool _cargando = false;
  bool _inicializado = false;
  String? _error;
  String? _aviso;
  double? _distanciaLineaMetros;

  @override
  void initState() {
    super.initState();
    if (widget.activa) _inicializar();
  }

  @override
  void didUpdateWidget(UbicacionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activa && !oldWidget.activa && !_inicializado) {
      _inicializar();
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _inicializar() async {
    if (!widget.activa) return;

    setState(() {
      _cargando = true;
      _error = null;
      _aviso = null;
      _ruta = null;
      _inicializado = true;
    });

    try {
      final usuario = await _obtenerUbicacionUsuario();
      final tienda = tiendaMasCercanaHuancayo(usuario);
      final distLinea = distanciaMetros(usuario, tienda.ubicacion);
      final modoSugerido = _directionsService.modoSugerido(distLinea);

      String? aviso;
      if (!estaEnHuancayo(usuario)) {
        aviso =
            'Tu GPS no parece estar en Huancayo. Igual te mostramos la tienda '
            'Wisa más cercana en ${MapsConfig.ciudad}.';
      }

      if (!mounted) return;
      setState(() {
        _ubicacionUsuario = usuario;
        _tiendaDestino = tienda;
        _distanciaLineaMetros = distLinea;
        _modo = modoSugerido;
        _aviso = aviso;
      });

      await _calcularRuta();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _cargando = false;
      });
    }
  }

  Future<LatLng> _obtenerUbicacionUsuario() async {
    final servicioHabilitado = await Geolocator.isLocationServiceEnabled();
    if (!servicioHabilitado) {
      throw Exception('Activa el GPS o la ubicación en tu dispositivo.');
    }

    var permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }
    if (permiso == LocationPermission.denied) {
      throw Exception('Se necesita permiso de ubicación para mostrar la ruta.');
    }
    if (permiso == LocationPermission.deniedForever) {
      throw Exception(
        'El permiso de ubicación está bloqueado. Habilítalo en Ajustes del teléfono.',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );

    return LatLng(position.latitude, position.longitude);
  }

  Future<void> _calcularRuta() async {
    if (!widget.activa) return;

    final origen = _ubicacionUsuario;
    final destino = _tiendaDestino?.ubicacion;
    if (origen == null || destino == null) return;

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final ruta = await _directionsService.obtenerRuta(
        origen: origen,
        destino: destino,
        modo: _modo,
      );

      if (!mounted) return;
      setState(() {
        _ruta = ruta;
        _error = null;
        _cargando = false;
      });

      await _ajustarCamara();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _cargando = false;
      });
    }
  }

  Future<void> _ajustarCamara() async {
    final controller = _mapController;
    final usuario = _ubicacionUsuario;
    final tienda = _tiendaDestino?.ubicacion;
    if (controller == null || usuario == null || tienda == null) return;

    final puntos = <LatLng>[usuario, tienda];
    if (_ruta != null && _ruta!.puntos.isNotEmpty) {
      puntos.addAll(_ruta!.puntos);
    }

    double minLat = puntos.first.latitude;
    double maxLat = puntos.first.latitude;
    double minLng = puntos.first.longitude;
    double maxLng = puntos.first.longitude;

    for (final p in puntos) {
      minLat = minLat < p.latitude ? minLat : p.latitude;
      maxLat = maxLat > p.latitude ? maxLat : p.latitude;
      minLng = minLng < p.longitude ? minLng : p.longitude;
      maxLng = maxLng > p.longitude ? maxLng : p.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 56));
  }

  /// Abre navegación GPS hacia la tienda elegida en la app (Google Maps instalado).
  Future<void> _comenzarViaje() async {
    final tienda = _tiendaDestino;
    final destino = tienda?.ubicacion;
    if (destino == null) return;

    final params = <String, String>{
      'api': '1',
      'destination': '${destino.latitude},${destino.longitude}',
      'travelmode': _modo.apiValue,
    };

    final origen = _ubicacionUsuario;
    if (origen != null) {
      params['origin'] = '${origen.latitude},${origen.longitude}';
    }

    final uri = Uri.https('www.google.com', '/maps/dir/', params);

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo iniciar el viaje. Verifica que tengas Google Maps instalado.',
          ),
        ),
      );
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navegando hacia ${tienda!.nombre}…'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Set<Marker> get _markers {
    final markers = <Marker>{};
    final usuario = _ubicacionUsuario;
    final tienda = _tiendaDestino;

    if (usuario != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('usuario'),
          position: usuario,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'Tu ubicación'),
        ),
      );
    }

    final destinoId = tienda?.id;
    for (final t in MapsConfig.tiendasHuancayo) {
      final esDestino = t.id == destinoId;
      markers.add(
        Marker(
          markerId: MarkerId(t.id),
          position: t.ubicacion,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            esDestino ? BitmapDescriptor.hueYellow : BitmapDescriptor.hueOrange,
          ),
          infoWindow: InfoWindow(
            title: esDestino ? '${t.nombre} (más cercana)' : t.nombre,
            snippet: t.direccion,
          ),
        ),
      );
    }

    markers.add(
      Marker(
        markerId: const MarkerId('continental-ref'),
        position: MapsConfig.universidadContinental,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(
          title: 'Universidad Continental',
          snippet: 'Campus Huancayo (referencia)',
        ),
      ),
    );

    return markers;
  }

  Set<Polyline> get _polylines {
    final puntos = _ruta?.puntos;
    if (puntos == null || puntos.isEmpty) return {};
    return {
      Polyline(
        polylineId: const PolylineId('ruta'),
        points: puntos,
        color: MinimarketTheme.secondaryNavy,
        width: 5,
      ),
    };
  }

  CameraPosition get _posicionInicial {
    if (_ubicacionUsuario != null && _tiendaDestino != null) {
      return CameraPosition(
        target: LatLng(
          (_ubicacionUsuario!.latitude + _tiendaDestino!.ubicacion.latitude) / 2,
          (_ubicacionUsuario!.longitude + _tiendaDestino!.ubicacion.longitude) / 2,
        ),
        zoom: 15,
      );
    }
    return MapsConfig.camaraInicialHuancayo;
  }

  @override
  Widget build(BuildContext context) {
    if (!_inicializado) {
      return _buildInvitacionActivar();
    }

    if (_error != null && _ubicacionUsuario == null) {
      return _buildEstadoError();
    }

    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: _posicionInicial,
                myLocationEnabled: widget.activa && _ubicacionUsuario != null,
                myLocationButtonEnabled: widget.activa,
                markers: _markers,
                polylines: _polylines,
                onMapCreated: (controller) {
                  _mapController = controller;
                  if (!_cargando) _ajustarCamara();
                },
              ),
              if (_cargando)
                const ColoredBox(
                  color: Color(0x88FFFFFF),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
        _buildPanelInfo(),
      ],
    );
  }

  Widget _buildInvitacionActivar() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.map_outlined,
                size: 56, color: MinimarketTheme.secondaryNavy),
            const SizedBox(height: 16),
            const Text(
              'Mapa y rutas a tiendas Wisa en Huancayo',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: MinimarketTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Al entrar aquí usamos tu GPS para mostrar la tienda más cercana.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: MinimarketTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadoError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off, size: 48, color: MinimarketTheme.error),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Error desconocido',
              textAlign: TextAlign.center,
              style: const TextStyle(color: MinimarketTheme.textPrimary),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _inicializar,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPanelInfo() {
    final tienda = _tiendaDestino;
    final ruta = _ruta;

    return Material(
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_city,
                      size: 18, color: MinimarketTheme.secondaryNavy),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${MapsConfig.tiendasHuancayo.length} tiendas Wisa en '
                      '${MapsConfig.ciudad}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: MinimarketTheme.secondaryNavy,
                      ),
                    ),
                  ),
                ],
              ),
              if (_ubicacionUsuario != null) ...[
                const SizedBox(height: 8),
                ...tiendasOrdenadasPorDistancia(_ubicacionUsuario!)
                    .take(3)
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(
                              item.tienda.id == tienda?.id
                                  ? Icons.star
                                  : Icons.store_outlined,
                              size: 14,
                              color: item.tienda.id == tienda?.id
                                  ? MinimarketTheme.primaryYellowDark
                                  : MinimarketTheme.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${item.tienda.nombre} · '
                                '${formatearDistanciaCorta(item.distanciaMetros)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: item.tienda.id == tienda?.id
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: MinimarketTheme.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
              if (_aviso != null) ...[
                const SizedBox(height: 8),
                Text(
                  _aviso!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: MinimarketTheme.warning,
                  ),
                ),
              ],
              if (tienda != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.store, color: MinimarketTheme.secondaryNavy),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            MapsConfig.tiendasHuancayo.length > 1
                                ? 'Tienda más cercana a ti'
                                : 'Tu tienda Wisa en Huancayo',
                            style: TextStyle(
                              fontSize: 11,
                              color: MinimarketTheme.textSecondary.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            tienda.nombre,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: MinimarketTheme.textPrimary,
                            ),
                          ),
                          Text(
                            tienda.direccion,
                            style: const TextStyle(
                              fontSize: 11,
                              color: MinimarketTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_distanciaLineaMetros != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    formatearDistanciaLinea(_distanciaLineaMetros!),
                    style: const TextStyle(
                      fontSize: 12,
                      color: MinimarketTheme.textSecondary,
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 12),
              const Text(
                'Modo de viaje',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: MinimarketTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: modosDisponibles.map((modo) {
                  final seleccionado = _modo == modo;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: modo == modosDisponibles.last ? 0 : 8,
                      ),
                      child: Material(
                        color: seleccionado
                            ? MinimarketTheme.secondaryNavy
                            : MinimarketTheme.primaryYellowSurface,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          onTap: _cargando
                              ? null
                              : () {
                                  setState(() => _modo = modo);
                                  _calcularRuta();
                                },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: seleccionado
                                    ? MinimarketTheme.secondaryNavy
                                    : MinimarketTheme.secondaryNavy
                                        .withValues(alpha: 0.35),
                              ),
                            ),
                            child: Text(
                              modo.etiqueta,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: seleccionado
                                    ? Colors.white
                                    : MinimarketTheme.secondaryNavy,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (_error != null && _ubicacionUsuario != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: const TextStyle(color: MinimarketTheme.error, fontSize: 12),
                ),
              ],
              if (ruta != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    _InfoRuta(
                      icono: Icons.straighten,
                      valor: ruta.distanciaTexto,
                      etiqueta: 'Distancia',
                    ),
                    const SizedBox(width: 16),
                    _InfoRuta(
                      icono: Icons.schedule,
                      valor: ruta.duracionTexto,
                      etiqueta: 'Tiempo estimado',
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed:
                      _tiendaDestino == null || _cargando ? null : _comenzarViaje,
                  icon: const Icon(Icons.directions_rounded, size: 22),
                  label: const Text('Comenzar viaje'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _cargando ? null : _inicializar,
                  icon: const Icon(Icons.my_location, size: 18),
                  label: const Text('Actualizar ubicación'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRuta extends StatelessWidget {
  const _InfoRuta({
    required this.icono,
    required this.valor,
    required this.etiqueta,
  });

  final IconData icono;
  final String valor;
  final String etiqueta;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: MinimarketTheme.primaryYellowSurface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icono, color: MinimarketTheme.secondaryNavy, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    etiqueta,
                    style: const TextStyle(
                      fontSize: 11,
                      color: MinimarketTheme.textSecondary,
                    ),
                  ),
                  Text(
                    valor,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: MinimarketTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
