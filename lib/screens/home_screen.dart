import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/theme.dart';
import '../models/producto.dart';
import '../widgets/carrito_badge.dart';
import 'productos_screen.dart';
import 'carrito_screen.dart';
import 'perfil_screen.dart';
import 'ubicacion_screen.dart';

class HomeScreen extends StatefulWidget {
  static final GlobalKey<HomeScreenState> homeKey = GlobalKey<HomeScreenState>();
  HomeScreen() : super(key: homeKey);

  static void selectTab(int index) {
    homeKey.currentState?.setSelectedTab(index);
  }

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  void setSelectedTab(int index) {
    if (mounted) {
      setState(() {
        if (index == 2) _ubicacionMontada = true;
        _currentIndex = index;
      });
    }
  }
  bool _ubicacionMontada = false;

  // Carrito compartido entre pantallas
  final List<Map<String, dynamic>> _carrito = [];

  StreamSubscription? _authSubscription;
  StreamSubscription? _usuarioSub;

  @override
  void initState() {
    super.initState();
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      _usuarioSub?.cancel();
      _iniciarEscuchaUsuario();
      if (mounted) {
        setState(() {
          _currentIndex = 0;
        });
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
      _usuarioSub = FirebaseFirestore.instance
          .collection('usuarios')
          .where('uid', isEqualTo: user.uid)
          .snapshots()
          .listen((querySnapshot) {
        if (mounted) {
          setState(() {});
        }
      }, onError: (e) {
        debugPrint('Error al escuchar datos de usuario en HomeScreen: $e');
      });
    } else {
      if (mounted) {
        setState(() {});
      }
    }
  }

  int get _carritoItemCount {
    int total = 0;
    for (final item in _carrito) {
      total += item['cantidad'] as int;
    }
    return total;
  }

  void _agregarAlCarrito(Producto producto, int cantidad) {
    setState(() {
      // Buscar si ya existe en el carrito
      final existeIndex =
          _carrito.indexWhere((item) => (item['producto'] as Producto).id == producto.id);

      if (existeIndex != -1) {
        _carrito[existeIndex]['cantidad'] =
            (_carrito[existeIndex]['cantidad'] as int) + cantidad;
      } else {
        _carrito.add({
          'producto': producto,
          'cantidad': cantidad,
        });
      }
    });
  }

  void _eliminarDelCarrito(int index) {
    setState(() {
      _carrito.removeAt(index);
    });
  }

  void _cambiarCantidad(int index, int nuevaCantidad) {
    setState(() {
      if (nuevaCantidad <= 0) {
        _carrito.removeAt(index);
      } else {
        _carrito[index]['cantidad'] = nuevaCantidad;
      }
    });
  }

  void _limpiarCarrito() {
    setState(() {
      _carrito.clear();
    });
  }

  String get _tituloActual {
    switch (_currentIndex) {
      case 0:
        return 'Minimarket';
      case 1:
        return 'Mi Carrito';
      case 2:
        return 'Cómo llegar';
      case 3:
        return 'Mi Perfil';
      default:
        return 'Minimarket';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_tituloActual),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: CarritoBadge(
              count: _carritoItemCount,
              onTap: () {
                setState(() => _currentIndex = 1);
              },
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          ProductosScreen(
            onAgregarAlCarrito: _agregarAlCarrito,
            carritoCount: _carritoItemCount,
          ),
          CarritoScreen(
            carrito: _carrito,
            onEliminar: _eliminarDelCarrito,
            onCambiarCantidad: _cambiarCantidad,
            onPedidoConfirmado: _limpiarCarrito,
          ),
          if (_ubicacionMontada)
            UbicacionScreen(activa: _currentIndex == 2)
          else
            const SizedBox.shrink(),
          const PerfilScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() {
          if (index == 2) _ubicacionMontada = true;
          _currentIndex = index;
        }),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.store_rounded),
            activeIcon: Icon(Icons.store_rounded),
            label: 'Productos',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.shopping_cart_rounded),
                if (_carritoItemCount > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: MinimarketTheme.error,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$_carritoItemCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Carrito',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.map_rounded),
            activeIcon: Icon(Icons.map_rounded),
            label: 'Ubicación',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
