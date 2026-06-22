import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:file_saver/file_saver.dart';
import 'package:intl/intl.dart';

import '../../models/pedido.dart';
import '../../services/delivery_service.dart';
import '../../services/firestore_service.dart';
import '../../config/theme.dart';

class AdminEstadisticasScreen extends StatefulWidget {
  const AdminEstadisticasScreen({super.key});

  @override
  State<AdminEstadisticasScreen> createState() => _AdminEstadisticasScreenState();
}

class _AdminEstadisticasScreenState extends State<AdminEstadisticasScreen> {
  final DeliveryService _deliveryService = DeliveryService();
  final FirestoreService _firestoreService = FirestoreService();

  DateTimeRange _rangoFechas = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  void _seleccionarRangoFechas() async {
    final DateTimeRange? nuevoRango = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      initialDateRange: _rangoFechas,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: MinimarketTheme.primaryRed,
            colorScheme: const ColorScheme.light(primary: MinimarketTheme.primaryRed),
            buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );
    if (nuevoRango != null) {
      setState(() {
        _rangoFechas = DateTimeRange(
          start: nuevoRango.start,
          end: DateTime(nuevoRango.end.year, nuevoRango.end.month, nuevoRango.end.day, 23, 59, 59),
        );
      });
    }
  }

  Future<void> _exportarVentasCSV(List<Pedido> pedidosFiltrados) async {
    try {
      List<List<dynamic>> filas = [];
      filas.add(['ID Pedido', 'Fecha', 'Cliente DNI', 'Estado', 'Subtotal Productos (S/)', 'Costo Delivery (S/)', 'Descuentos (S/)', 'Ingreso Final (S/)']);

      for (var p in pedidosFiltrados) {
        filas.add([
          p.id,
          DateFormat('yyyy-MM-dd HH:mm').format(p.creadoEn),
          p.userId,
          p.estado.name,
          p.total.toStringAsFixed(2),
          p.costoDelivery.toStringAsFixed(2),
          p.descuentoAplicado.toStringAsFixed(2),
          p.totalConDelivery.toStringAsFixed(2)
        ]);
      }

      String csvData = const ListToCsvConverter().convert(filas);
      Uint8List bytes = Uint8List.fromList(csvData.codeUnits);
      
      await FileSaver.instance.saveFile(
        name: 'Reporte_Ventas_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv',
        bytes: bytes,
        mimeType: MimeType.csv,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reporte de Ventas descargado con éxito.'), backgroundColor: MinimarketTheme.disponible),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al exportar: $e'), backgroundColor: MinimarketTheme.error));
      }
    }
  }

  Future<void> _exportarProductosCSV() async {
    try {
      final productos = await _firestoreService.obtenerProductos();
      List<List<dynamic>> filas = [];
      filas.add(['ID', 'Nombre', 'Categoria', 'Precio Unitario (S/)', 'Stock Actual', 'Disponible']);

      for (var prod in productos) {
        filas.add([
          prod.id,
          prod.nombre,
          prod.categoria,
          prod.precio.toStringAsFixed(2),
          prod.stock,
          prod.disponible ? 'Si' : 'No'
        ]);
      }

      String csvData = const ListToCsvConverter().convert(filas);
      Uint8List bytes = Uint8List.fromList(csvData.codeUnits);
      
      await FileSaver.instance.saveFile(
        name: 'Reporte_Inventario_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv',
        bytes: bytes,
        mimeType: MimeType.csv,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reporte de Inventario descargado con éxito.'), backgroundColor: MinimarketTheme.disponible),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al exportar: $e'), backgroundColor: MinimarketTheme.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Dashboard y Analíticas',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: MinimarketTheme.textPrimary,
                ),
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _seleccionarRangoFechas,
                    icon: const Icon(Icons.date_range),
                    label: Text('${DateFormat('dd/MM/yy').format(_rangoFechas.start)} - ${DateFormat('dd/MM/yy').format(_rangoFechas.end)}'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () => _exportarProductosCSV(),
                    icon: const Icon(Icons.inventory_2_outlined),
                    label: const Text('Exportar Inventario CSV'),
                    style: ElevatedButton.styleFrom(backgroundColor: MinimarketTheme.textPrimary, foregroundColor: Colors.white),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: StreamBuilder<List<Pedido>>(
              stream: _deliveryService.streamPedidos(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: MinimarketTheme.primaryRed));
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error al cargar datos: ${snapshot.error}', style: const TextStyle(color: MinimarketTheme.error)));
                }

                // Filtrar pedidos por fecha y estado (ignorar cancelados para ingresos)
                final todosLosPedidos = snapshot.data ?? [];
                final pedidosFiltrados = todosLosPedidos.where((p) {
                  return p.creadoEn.isAfter(_rangoFechas.start) && 
                         p.creadoEn.isBefore(_rangoFechas.end) &&
                         p.estado != EstadoPedido.cancelado;
                }).toList();

                // Calcular KPIs
                double ingresosTotales = 0;
                int totalVentas = pedidosFiltrados.length;
                Map<String, Map<String, dynamic>> metricasPorProducto = {};
                Map<String, double> ingresosPorDia = {};

                for (var p in pedidosFiltrados) {
                  ingresosTotales += p.totalConDelivery;

                  // Agrupar por día para el gráfico
                  String diaStr = DateFormat('dd/MM').format(p.creadoEn);
                  ingresosPorDia[diaStr] = (ingresosPorDia[diaStr] ?? 0) + p.totalConDelivery;

                  // Agrupar por producto
                  for (var item in p.items) {
                    if (!metricasPorProducto.containsKey(item.productoId)) {
                      metricasPorProducto[item.productoId] = {
                        'nombre': item.nombre,
                        'cantidad': 0,
                        'ingreso': 0.0,
                      };
                    }
                    metricasPorProducto[item.productoId]!['cantidad'] += item.cantidad;
                    metricasPorProducto[item.productoId]!['ingreso'] += item.subtotal;
                  }
                }

                double ticketPromedio = totalVentas > 0 ? ingresosTotales / totalVentas : 0;

                // Ordenar productos por ingreso
                var rankingProductos = metricasPorProducto.values.toList();
                rankingProductos.sort((a, b) => (b['ingreso'] as double).compareTo(a['ingreso'] as double));

                // Preparar datos para el gráfico
                List<String> diasOrdenados = ingresosPorDia.keys.toList().reversed.toList(); // Fechas cronológicas
                if (diasOrdenados.isEmpty) diasOrdenados.add(DateFormat('dd/MM').format(DateTime.now()));

                return CustomScrollView(
                  slivers: [
                    // Fila de KPIs
                    SliverToBoxAdapter(
                      child: Row(
                        children: [
                          Expanded(child: _construirKPICard('Ingresos Totales', 'S/ ${ingresosTotales.toStringAsFixed(2)}', Icons.monetization_on, MinimarketTheme.disponible)),
                          const SizedBox(width: 16),
                          Expanded(child: _construirKPICard('Pedidos Exitosos', '$totalVentas', Icons.shopping_bag, Colors.blue)),
                          const SizedBox(width: 16),
                          Expanded(child: _construirKPICard('Ticket Promedio', 'S/ ${ticketPromedio.toStringAsFixed(2)}', Icons.receipt, Colors.purple)),
                        ],
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    // Gráfico y Exportación
                    SliverToBoxAdapter(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Evolución de Ingresos por Día', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 20),
                                    SizedBox(
                                      height: 250,
                                      child: _construirGraficoBarras(ingresosPorDia, diasOrdenados),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 1,
                            child: Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    const Text('Exportación de Reportes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 16),
                                    const Text('Descarga el histórico de ventas según el rango de fechas seleccionado para analizar en Excel o PowerBI.', style: TextStyle(color: MinimarketTheme.textSecondary, fontSize: 13)),
                                    const SizedBox(height: 24),
                                    ElevatedButton.icon(
                                      onPressed: () => _exportarVentasCSV(pedidosFiltrados),
                                      icon: const Icon(Icons.download),
                                      label: const Text('Exportar Ventas CSV'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: MinimarketTheme.primaryRed,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    // Ranking de Productos
                    SliverToBoxAdapter(
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Ingresos por Producto (Ranking)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 16),
                              if (rankingProductos.isEmpty)
                                const Center(child: Padding(padding: EdgeInsets.all(20.0), child: Text('No hay ventas en este rango.'))),
                              if (rankingProductos.isNotEmpty)
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: rankingProductos.length,
                                  separatorBuilder: (c, i) => const Divider(),
                                  itemBuilder: (context, index) {
                                    final item = rankingProductos[index];
                                    return ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: MinimarketTheme.primaryRed.withValues(alpha: 0.1),
                                        child: Text('${index + 1}', style: const TextStyle(color: MinimarketTheme.primaryRed, fontWeight: FontWeight.bold)),
                                      ),
                                      title: Text(item['nombre'], style: const TextStyle(fontWeight: FontWeight.w600)),
                                      subtitle: Text('Unidades vendidas: ${item['cantidad']}'),
                                      trailing: Text('S/ ${item['ingreso'].toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: MinimarketTheme.disponible)),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 40)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirKPICard(String titulo, String valor, IconData icono, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icono, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: const TextStyle(color: MinimarketTheme.textSecondary, fontSize: 14)),
                const SizedBox(height: 4),
                Text(valor, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: MinimarketTheme.textPrimary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirGraficoBarras(Map<String, double> ingresosPorDia, List<String> diasOrdenados) {
    if (ingresosPorDia.isEmpty) return const Center(child: Text('Datos insuficientes'));

    double maxIngreso = 0;
    for (var dia in diasOrdenados) {
      if ((ingresosPorDia[dia] ?? 0) > maxIngreso) {
        maxIngreso = ingresosPorDia[dia]!;
      }
    }
    if (maxIngreso == 0) maxIngreso = 1;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: diasOrdenados.map((dia) {
            double ingreso = ingresosPorDia[dia] ?? 0;
            double porcentaje = ingreso / (maxIngreso * 1.1); // 10% margen superior
            double barHeight = constraints.maxHeight * 0.8 * porcentaje;

            return Tooltip(
              message: '$dia\nS/ ${ingreso.toStringAsFixed(2)}',
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('S/ ${ingreso > 0 ? ingreso.toStringAsFixed(0) : ''}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOut,
                    width: 24,
                    height: barHeight,
                    decoration: BoxDecoration(
                      color: MinimarketTheme.primaryRed,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: MinimarketTheme.primaryRed.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(dia, style: const TextStyle(fontSize: 11, color: MinimarketTheme.textSecondary, fontWeight: FontWeight.w500)),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
