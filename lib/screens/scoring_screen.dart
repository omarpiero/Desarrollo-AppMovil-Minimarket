import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/theme.dart';
import '../models/usuario.dart';

class ScoringScreen extends StatefulWidget {
  final int puntosUsuario;
  const ScoringScreen({super.key, required this.puntosUsuario});

  @override
  State<ScoringScreen> createState() => _ScoringScreenState();
}

class _ScoringScreenState extends State<ScoringScreen> {
  StreamSubscription? _usuarioSub;
  Usuario? _usuarioLogueado;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _iniciarEscuchaUsuario();
  }

  @override
  void dispose() {
    _usuarioSub?.cancel();
    super.dispose();
  }

  void _iniciarEscuchaUsuario() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _usuarioSub = FirebaseFirestore.instance
          .collection('usuarios')
          .where('uid', isEqualTo: user.uid)
          .limit(1)
          .snapshots()
          .listen((snap) {
        if (snap.docs.isNotEmpty) {
          if (mounted) {
            setState(() {
              _usuarioLogueado = Usuario.fromFirestore(snap.docs.first);
              _cargando = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _cargando = false;
            });
          }
        }
      }, onError: (e) {
        if (mounted) {
          setState(() {
            _cargando = false;
          });
        }
      });
    } else {
      setState(() => _cargando = false);
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

  Color _obtenerColorRango(String rango) {
    if (rango == 'El Caserito') return MinimarketTheme.primaryYellow;
    if (rango == 'Amigo de la casa') return const Color(0xFFE0E0E0); // Plata
    return const Color(0xFFCD7F32); // Bronce
  }

  @override
  Widget build(BuildContext context) {
    final puntos = _usuarioLogueado?.puntosAcumulados ?? widget.puntosUsuario;
    final rango = _obtenerRango(puntos);
    final progreso = _obtenerProgreso(puntos);
    final dni = _usuarioLogueado?.dni;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Club Caserito Wisa'),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: MinimarketTheme.primaryRed))
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Tarjeta Header Premium con gradiente
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [MinimarketTheme.primaryRed, MinimarketTheme.primaryRedDark],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(32),
                        bottomRight: Radius.circular(32),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.stars_rounded,
                          color: MinimarketTheme.primaryYellow,
                          size: 72,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          rango.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$puntos Puntos Acumulados',
                            style: const TextStyle(
                              color: MinimarketTheme.primaryYellow,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Barra de progreso a nivel
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              puntos < 50 ? 'Vecino' : (puntos < 150 ? 'Amigo' : 'Caserito'),
                              style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              puntos < 50 ? '50 pts para Amigo' : (puntos < 150 ? '150 pts para Caserito' : 'Nivel Máximo'),
                              style: const TextStyle(color: MinimarketTheme.primaryYellow, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: progreso,
                            backgroundColor: Colors.white10,
                            valueColor: const AlwaysStoppedAnimation<Color>(MinimarketTheme.primaryYellow),
                            minHeight: 10,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Cada 1 punto acumulado equivale a S/ 0.01 de descuento adicional en tus compras o delivery.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Sección de Beneficios
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'BENEFICIOS POR NIVEL',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: MinimarketTheme.textSecondary,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildCardBeneficio(
                          nivel: 'Vecino (0-49 pts)',
                          color: _obtenerColorRango('Vecino'),
                          activo: rango == 'Vecino',
                          beneficios: [
                            'Acumula 1 punto por cada sol comprado.',
                            'Canjea tus puntos por descuentos directos (1 pto = S/ 0.01).',
                            'Costo de delivery regular según distancia (gratis > S/ 50).'
                          ],
                        ),
                        _buildCardBeneficio(
                          nivel: 'Amigo de la casa (50-149 pts)',
                          color: _obtenerColorRango('Amigo de la casa'),
                          activo: rango == 'Amigo de la casa',
                          beneficios: [
                            'Descuento del 5% automático en todos los productos del carrito.',
                            '50% de descuento automático en la tarifa de delivery.',
                            'Delivery gratis en compras mayores a S/ 40.',
                            'Todos los beneficios del nivel Vecino.'
                          ],
                        ),
                        _buildCardBeneficio(
                          nivel: 'El Caserito (150+ pts)',
                          color: _obtenerColorRango('El Caserito'),
                          activo: rango == 'El Caserito',
                          beneficios: [
                            'Descuento del 10% automático en todos los productos del carrito.',
                            'DELIVERY TOTALMENTE GRATIS en todas tus compras sin monto mínimo!',
                            'Delivery gratis en general en compras mayores a S/ 30.',
                            'Acceso a ofertas exclusivas del Club Caserito.',
                            'Todos los beneficios de niveles anteriores.'
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Historial de Transacciones de Puntos
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'HISTORIAL DE PUNTOS',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: MinimarketTheme.textSecondary,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (dni == null)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('Inicia sesión para ver tu historial.'),
                            ),
                          )
                        else
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('usuarios')
                                .doc(dni)
                                .collection('historialPuntos')
                                .orderBy('fecha', descending: true)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }

                              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                return Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Center(
                                      child: Column(
                                        children: [
                                          Icon(Icons.history_rounded, size: 40, color: Colors.grey.shade400),
                                          const SizedBox(height: 8),
                                          const Text(
                                            'Aún no registras transacciones de puntos.',
                                            style: TextStyle(color: MinimarketTheme.textSecondary, fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }

                              final docs = snapshot.data!.docs;

                              return ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: docs.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final data = docs[index].data() as Map<String, dynamic>;
                                  final cantidad = data['puntos'] ?? 0;
                                  final esGanancia = (data['tipo'] ?? 'ganado') == 'ganado';
                                  final motivo = data['motivo'] ?? 'Compra realizada';
                                  final Timestamp? fechaTs = data['fecha'] as Timestamp?;
                                  final fechaStr = fechaTs != null
                                      ? '${fechaTs.toDate().day}/${fechaTs.toDate().month}/${fechaTs.toDate().year}'
                                      : '';

                                  return Card(
                                    margin: EdgeInsets.zero,
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: esGanancia
                                            ? Colors.green.shade50
                                            : Colors.red.shade50,
                                        child: Icon(
                                          esGanancia ? Icons.add_rounded : Icons.remove_rounded,
                                          color: esGanancia ? Colors.green : Colors.red,
                                        ),
                                      ),
                                      title: Text(
                                        motivo,
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Text(
                                        fechaStr,
                                        style: const TextStyle(fontSize: 11, color: MinimarketTheme.textSecondary),
                                      ),
                                      trailing: Text(
                                        '${esGanancia ? "+" : "-"}$cantidad pts',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: esGanancia ? Colors.green : Colors.red,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildCardBeneficio({
    required String nivel,
    required Color color,
    required bool activo,
    required List<String> beneficios,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: MinimarketTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: activo ? MinimarketTheme.primaryRed : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: activo
                  ? MinimarketTheme.primaryRed.withValues(alpha: 0.08)
                  : Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.stars_rounded, color: color, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    nivel,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: activo ? MinimarketTheme.primaryRedDark : MinimarketTheme.textPrimary,
                    ),
                  ),
                ),
                if (activo)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: MinimarketTheme.primaryRed,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'ACTIVO',
                      style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: beneficios
                  .map(
                    (b) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              b,
                              style: const TextStyle(fontSize: 12, color: MinimarketTheme.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
