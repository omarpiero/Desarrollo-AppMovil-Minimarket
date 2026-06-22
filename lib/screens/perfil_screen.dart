import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../config/theme.dart';
import '../models/usuario.dart';
import 'login_screen.dart';
import 'historial_pedidos_screen.dart';
import 'scoring_screen.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  StreamSubscription? _authSubscription;
  StreamSubscription? _usuarioSub;
  Usuario? _usuarioLogueado;
  bool _cargandoUsuario = true;

  @override
  void initState() {
    super.initState();
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      _usuarioSub?.cancel();
      _iniciarEscuchaUsuario();
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _usuarioSub?.cancel();
    super.dispose();
  }

  void _iniciarEscuchaUsuario() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() => _cargandoUsuario = true);
      _usuarioSub = FirebaseFirestore.instance
          .collection('usuarios')
          .where('uid', isEqualTo: user.uid)
          .snapshots()
          .listen((querySnapshot) {
        if (querySnapshot.docs.isNotEmpty) {
          final doc = querySnapshot.docs.first;
          if (mounted) {
            setState(() {
              _usuarioLogueado = Usuario.fromFirestore(doc);
              _cargandoUsuario = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _usuarioLogueado = null;
              _cargandoUsuario = false;
            });
          }
        }
      }, onError: (e) {
        debugPrint('Error al escuchar datos de usuario en PerfilScreen: $e');
        if (mounted) {
          setState(() {
            _cargandoUsuario = false;
          });
        }
      });
    } else {
      if (mounted) {
        setState(() {
          _usuarioLogueado = null;
          _cargandoUsuario = false;
        });
      }
    }
  }

  String _obtenerRango(int puntos) {
    if (puntos < 50) return 'Vecino';
    if (puntos < 150) return 'Amigo de la casa';
    return 'El Caserito';
  }

  double _obtenerProgreso(int puntos) {
    if (puntos < 50) return puntos / 50;
    if (puntos < 150) return (puntos - 50) / 100;
    return 1.0;
  }

  Future<void> _cerrarSesion() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas salir de tu cuenta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Salir', style: TextStyle(color: MinimarketTheme.error)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
    }
  }

  Future<Position> _obtenerCoordenadasActuales() async {
    final servicioHabilitado = await Geolocator.isLocationServiceEnabled();
    if (!servicioHabilitado) {
      throw Exception('Activa el GPS en tu dispositivo.');
    }

    var permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }
    if (permiso == LocationPermission.denied) {
      throw Exception('Permiso de ubicación denegado.');
    }
    if (permiso == LocationPermission.deniedForever) {
      throw Exception('El permiso de ubicación está bloqueado permanentemente.');
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
  }

  void _mostrarDialogEditar() {
    if (_usuarioLogueado == null) return;
    
    final user = _usuarioLogueado!;
    final formKey = GlobalKey<FormState>();
    final nombreController = TextEditingController(text: user.nombreCompleto);
    final telefonoController = TextEditingController(text: user.telefono);
    final direccionController = TextEditingController(text: user.direccion);
    final referenciaController = TextEditingController(text: user.referencia);
    double? lat = user.latitud;
    double? lng = user.longitud;
    bool obteniendoGps = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool guardando = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Editar Perfil', style: TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nombreController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre Completo',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Ingresa tu nombre' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: telefonoController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Teléfono',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Ingresa tu teléfono';
                          if (!RegExp(r'^\d{9}$').hasMatch(v.trim())) return 'Debe tener 9 dígitos';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: direccionController,
                        decoration: const InputDecoration(
                          labelText: 'Dirección de Entrega',
                          prefixIcon: Icon(Icons.home_outlined),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Ingresa tu dirección' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: referenciaController,
                        decoration: const InputDecoration(
                          labelText: 'Referencia',
                          prefixIcon: Icon(Icons.info_outline),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Ingresa una referencia' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              lat != null && lng != null
                                  ? 'GPS: ${lat!.toStringAsFixed(4)}, ${lng!.toStringAsFixed(4)}'
                                  : 'GPS no registrado',
                              style: TextStyle(
                                fontSize: 11,
                                color: lat != null && lng != null ? Colors.green : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: obteniendoGps
                                ? null
                                : () async {
                                    setDialogState(() => obteniendoGps = true);
                                    try {
                                      final pos = await _obtenerCoordenadasActuales();
                                      setDialogState(() {
                                        lat = pos.latitude;
                                        lng = pos.longitude;
                                      });
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Error GPS: $e'),
                                            backgroundColor: MinimarketTheme.error,
                                          ),
                                        );
                                      }
                                    } finally {
                                      setDialogState(() => obteniendoGps = false);
                                    }
                                  },
                            icon: obteniendoGps
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 1.5, color: MinimarketTheme.primaryRed),
                                  )
                                : const Icon(Icons.my_location_rounded, size: 16),
                            label: const Text('GPS', style: TextStyle(fontSize: 12)),
                            style: TextButton.styleFrom(
                              foregroundColor: MinimarketTheme.primaryRed,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: guardando ? null : () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: guardando
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          
                          setDialogState(() => guardando = true);
                          try {
                            await FirebaseFirestore.instance
                                .collection('usuarios')
                                .doc(user.dni)
                                .update({
                              'nombreCompleto': nombreController.text.trim(),
                              'telefono': telefonoController.text.trim(),
                              'direccion': direccionController.text.trim(),
                              'referencia': referenciaController.text.trim(),
                              'latitud': lat,
                              'longitud': lng,
                            });
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('✅ Perfil actualizado correctamente'),
                                  backgroundColor: MinimarketTheme.disponible,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('❌ Error al actualizar: $e'),
                                  backgroundColor: MinimarketTheme.error,
                                ),
                              );
                            }
                          } finally {
                            setDialogState(() => guardando = false);
                          }
                        },
                  child: guardando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }



  Widget _buildBadgeRango(String rango) {
    IconData icon;
    Color color;
    if (rango == 'El Caserito') {
      icon = Icons.stars_rounded;
      color = MinimarketTheme.primaryYellow;
    } else if (rango == 'Amigo de la casa') {
      icon = Icons.stars_rounded;
      color = const Color(0xFFC0C0C0);
    } else {
      icon = Icons.star_half_rounded;
      color = const Color(0xFFCD7F32);
    }
    return Icon(icon, color: color, size: 20);
  }

  Widget _buildProgresoPuntos(Usuario dataUser) {
    final rango = _obtenerRango(dataUser.puntosAcumulados);
    final progreso = _obtenerProgreso(dataUser.puntosAcumulados);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ScoringScreen(puntosUsuario: dataUser.puntosAcumulados),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [MinimarketTheme.primaryRed, MinimarketTheme.primaryRedDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: MinimarketTheme.primaryRed.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '¡Hola, Casero! Tu nivel es:',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildBadgeRango(rango),
                        const SizedBox(width: 4),
                        Text(
                          rango,
                          style: const TextStyle(
                            color: MinimarketTheme.primaryYellow,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.stars_rounded, color: MinimarketTheme.primaryYellow, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        '${dataUser.puntosAcumulados} pts',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progreso,
                backgroundColor: Colors.white10,
                valueColor: const AlwaysStoppedAnimation<Color>(MinimarketTheme.primaryYellow),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              dataUser.puntosAcumulados < 150
                  ? 'Estás a ${dataUser.puntosAcumulados < 50 ? 50 - dataUser.puntosAcumulados : 150 - dataUser.puntosAcumulados} puntos del siguiente rango'
                  : '¡Felicidades! Estás en el nivel máximo del club.',
              style: const TextStyle(color: Colors.white60, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.account_circle_outlined,
                size: 90,
                color: MinimarketTheme.divider,
              ),
              const SizedBox(height: 16),
              const Text(
                'Inicia sesión para ver tu perfil',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: MinimarketTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Accede a tu historial de pedidos, acumula puntos Club Caserito y gestiona tus direcciones.',
                style: TextStyle(
                  fontSize: 14,
                  color: MinimarketTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LoginScreen(),
                      ),
                    );
                  },
                  child: const Text('INICIAR SESIÓN'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_cargandoUsuario) {
      return const Center(
        child: CircularProgressIndicator(color: MinimarketTheme.primaryRed),
      );
    }

    if (_usuarioLogueado == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 70, color: MinimarketTheme.error),
              const SizedBox(height: 16),
              const Text(
                'Error al cargar el perfil',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'No se encontró el documento de usuario en la base de datos.',
                textAlign: TextAlign.center,
                style: TextStyle(color: MinimarketTheme.textSecondary),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => FirebaseAuth.instance.signOut(),
                child: const Text('CERRAR SESIÓN'),
              ),
            ],
          ),
        ),
      );
    }

    final dataUser = _usuarioLogueado!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── TARJETA DE PERFIL PREMIUM ───
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  colors: [MinimarketTheme.primaryRedDark, MinimarketTheme.primaryRed],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          child: const Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dataUser.nombreCompleto,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                dataUser.email,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white24, height: 24),
                    _buildRowInfo(Icons.badge_outlined, 'DNI', dataUser.dni),
                    const SizedBox(height: 8),
                    _buildRowInfo(Icons.phone, 'Teléfono', dataUser.telefono),
                    const SizedBox(height: 8),
                    _buildRowInfo(Icons.home, 'Dirección', dataUser.direccion),
                    const SizedBox(height: 4),
                    _buildRowInfo(Icons.info_outline, 'Referencia', dataUser.referencia, isSmall: true),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildProgresoPuntos(dataUser),
          const SizedBox(height: 20),

          // ─── ACCIONES DEL USUARIO ───
          const Text(
            'OPCIONES',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: MinimarketTheme.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.moped_rounded, color: MinimarketTheme.primaryRed),
                  title: const Text('Mis Pedidos', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HistorialPedidosScreen(showAppBar: true),
                      ),
                    );
                  },
                ),
                const Divider(height: 1, indent: 50),
                ListTile(
                  leading: const Icon(Icons.stars_rounded, color: MinimarketTheme.primaryRed),
                  title: const Text('Club Caserito (Scoring)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ScoringScreen(puntosUsuario: dataUser.puntosAcumulados),
                      ),
                    );
                  },
                ),
                const Divider(height: 1, indent: 50),
                ListTile(
                  leading: const Icon(Icons.edit_rounded, color: MinimarketTheme.primaryRed),
                  title: const Text('Editar Datos', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: _mostrarDialogEditar,
                ),
                const Divider(height: 1, indent: 50),
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: MinimarketTheme.error),
                  title: const Text('Cerrar Sesión', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: MinimarketTheme.error)),
                  onTap: _cerrarSesion,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildRowInfo(IconData icon, String label, String val, {bool isSmall = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: MinimarketTheme.primaryYellow, size: isSmall ? 16 : 18),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.95),
                fontSize: isSmall ? 12 : 13,
              ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: val),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
