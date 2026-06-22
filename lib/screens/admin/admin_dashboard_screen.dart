import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../config/theme.dart';
import 'admin_login_screen.dart';
import 'admin_estadisticas_screen.dart';
import 'admin_productos_screen.dart';
import 'admin_pedidos_screen.dart';
import '../configuracion_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  void _cerrarSesion() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
      );
    }
  }

  Widget _buildScreen() {
    switch (_selectedIndex) {
      case 0:
        return const AdminEstadisticasScreen();
      case 1:
        return const AdminProductosScreen();
      case 2:
        return const AdminPedidosScreen();
      case 3:
        return const ConfiguracionScreen();
      default:
        return const AdminEstadisticasScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MinimarketTheme.background,
      body: Row(
        children: [
          NavigationRail(
            backgroundColor: Colors.white,
            extended: true,
            selectedIndex: _selectedIndex,
            labelType: NavigationRailLabelType.none,
            selectedIconTheme: const IconThemeData(color: MinimarketTheme.primaryRed),
            selectedLabelTextStyle: const TextStyle(color: MinimarketTheme.primaryRed, fontWeight: FontWeight.bold),
            unselectedIconTheme: const IconThemeData(color: Colors.grey),
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            leading: Column(
              children: [
                const SizedBox(height: 20),
                const Icon(Icons.admin_panel_settings_rounded, size: 48, color: MinimarketTheme.primaryRed),
                const SizedBox(height: 8),
                const Text('Wisa Admin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: MinimarketTheme.primaryRedDark)),
                const SizedBox(height: 20),
                Divider(color: Colors.grey.withValues(alpha: 0.3)),
              ],
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: IconButton(
                    icon: const Icon(Icons.logout_rounded, color: MinimarketTheme.error),
                    tooltip: 'Cerrar Sesión',
                    onPressed: _cerrarSesion,
                  ),
                ),
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.bar_chart_outlined),
                selectedIcon: Icon(Icons.bar_chart_rounded, color: MinimarketTheme.primaryRed),
                label: Text('Estadísticas'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.inventory_2_outlined),
                selectedIcon: Icon(Icons.inventory_2_rounded, color: MinimarketTheme.primaryRed),
                label: Text('Productos'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.shopping_bag_outlined),
                selectedIcon: Icon(Icons.shopping_bag_rounded, color: MinimarketTheme.primaryRed),
                label: Text('Pedidos'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.build_circle_outlined),
                selectedIcon: Icon(Icons.build_circle_rounded, color: MinimarketTheme.primaryRed),
                label: Text('Herramientas Dev'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: Container(
              color: MinimarketTheme.background,
              child: _buildScreen(),
            ),
          ),
        ],
      ),
    );
  }
}
