import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../config/theme.dart';
import '../models/usuario.dart';
import '../services/google_places_service.dart';
import 'home_screen.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _nombreController = TextEditingController();
  final _dniController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();
  final _referenciaController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  double? _latitud;
  double? _longitud;
  bool _obteniendoGps = false;

  Future<void> _obtenerUbicacionActual() async {
    setState(() => _obteniendoGps = true);
    try {
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

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      setState(() {
        _latitud = position.latitude;
        _longitud = position.longitude;
      });

      // Reverse geocoding: autocompletar dirección desde coordenadas
      final placesService = GooglePlacesService();
      final direccion = await placesService.reverseGeocode(
        LatLng(position.latitude, position.longitude),
      );
      if (direccion != null && mounted) {
        setState(() {
          _direccionController.text = direccion;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    direccion != null
                        ? 'Ubicación obtenida y dirección autocompletada'
                        : 'Ubicación GPS obtenida correctamente',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text('Error al obtener ubicación: $e')),
              ],
            ),
            backgroundColor: MinimarketTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _obteniendoGps = false);
      }
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _dniController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    _referenciaController.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text.trim() != _confirmPasswordController.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Las contraseñas no coinciden'),
          backgroundColor: MinimarketTheme.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Registrar en Firebase Auth
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final String uid = credential.user!.uid;
      final String dni = _dniController.text.trim();

      // 2. Crear modelo Usuario
      final usuario = Usuario(
        uid: uid,
        dni: dni,
        email: _emailController.text.trim(),
        nombreCompleto: _nombreController.text.trim(),
        telefono: _telefonoController.text.trim(),
        direccion: _direccionController.text.trim(),
        referencia: _referenciaController.text.trim(),
        puntosAcumulados: 0,
        latitud: _latitud,
        longitud: _longitud,
      );

      // 3. Guardar en Firestore colección 'usuarios' usando DNI como ID de documento
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(dni)
          .set(usuario.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Registro exitoso'),
            backgroundColor: MinimarketTheme.disponible,
          ),
        );
        // Regresar directo al HomeScreen (la primera ruta del stack).
        // El StreamBuilder de main.dart detectará el cambio de sesión e iniciará la sesión del usuario.
        HomeScreen.selectTab(0);
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } on FirebaseAuthException catch (e) {
      String mensaje = 'Error al registrar: ${e.message ?? e.code}';
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(mensaje)),
              ],
            ),
            backgroundColor: MinimarketTheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: MinimarketTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Cuenta'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Únete a Minimarket',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: MinimarketTheme.primaryRedDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Completa tus datos para realizar tus compras de manera rápida y acumular puntos.',
                  style: TextStyle(
                    fontSize: 14,
                    color: MinimarketTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                // Form Fields Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Datos Personales',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: MinimarketTheme.primaryRedDark,
                          ),
                        ),
                        const Divider(height: 20),
                        
                        // Nombre Completo
                        TextFormField(
                          controller: _nombreController,
                          keyboardType: TextInputType.name,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Nombre Completo',
                            prefixIcon: Icon(Icons.person_outline_rounded),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Por favor ingresa tu nombre completo';
                            }
                            if (value.trim().length < 3) {
                              return 'El nombre debe tener al menos 3 caracteres';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // DNI
                        TextFormField(
                          controller: _dniController,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'DNI',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Por favor ingresa tu DNI';
                            }
                            final cleanVal = value.trim();
                            if (!RegExp(r'^\d{8}$').hasMatch(cleanVal)) {
                              return 'El DNI debe tener exactamente 8 dígitos';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Teléfono
                        TextFormField(
                          controller: _telefonoController,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Teléfono / Celular',
                            prefixIcon: Icon(Icons.phone_android_rounded),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Por favor ingresa tu teléfono';
                            }
                            final cleanVal = value.trim();
                            if (!RegExp(r'^\d{9}$').hasMatch(cleanVal)) {
                              return 'El teléfono debe tener exactamente 9 dígitos';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        
                        const Text(
                          'Datos de Entrega',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: MinimarketTheme.primaryRedDark,
                          ),
                        ),
                        const Divider(height: 20),

                        // Dirección
                        TextFormField(
                          controller: _direccionController,
                          keyboardType: TextInputType.streetAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Dirección de Entrega',
                            prefixIcon: Icon(Icons.home_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Por favor ingresa tu dirección';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _latitud != null && _longitud != null
                                    ? 'Ubicación GPS: ${_latitud!.toStringAsFixed(4)}, ${_longitud!.toStringAsFixed(4)}'
                                    : 'GPS no registrado (opcional para cálculo exacto)',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _latitud != null && _longitud != null ? Colors.green : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: _obteniendoGps ? null : _obtenerUbicacionActual,
                              icon: _obteniendoGps
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
                        const SizedBox(height: 16),
                        
                        // Referencia
                        TextFormField(
                          controller: _referenciaController,
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Referencia (ej: Portón negro, frente al parque)',
                            prefixIcon: Icon(Icons.info_outline_rounded),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Por favor ingresa una referencia';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        const Text(
                          'Credenciales de Acceso',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: MinimarketTheme.primaryRedDark,
                          ),
                        ),
                        const Divider(height: 20),
                        
                        // Email
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Correo Electrónico',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Por favor ingresa tu correo';
                            }
                            final emailRegex = RegExp(
                                r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+');
                            if (!emailRegex.hasMatch(value.trim())) {
                              return 'Ingresa un correo electrónico válido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Password
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Por favor ingresa tu contraseña';
                            }
                            if (value.trim().length < 6) {
                              return 'La contraseña debe tener al menos 6 caracteres';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Confirm Password
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _registrar(),
                          decoration: InputDecoration(
                            labelText: 'Confirmar Contraseña',
                            prefixIcon: const Icon(Icons.lock_clock_outlined),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword = !_obscureConfirmPassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Por favor confirma tu contraseña';
                            }
                            if (value.trim() != _passwordController.text.trim()) {
                              return 'Las contraseñas no coinciden';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Register Button
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _registrar,
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: MinimarketTheme.primaryRed,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text('REGISTRARME'),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
