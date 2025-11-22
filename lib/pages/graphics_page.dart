import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/database_service.dart';

class GraphicsPage extends StatefulWidget {
  final String doctorId;
  const GraphicsPage({super.key, required this.doctorId});

  @override
  State<GraphicsPage> createState() => _GraphicsPageState();
}

class _GraphicsPageState extends State<GraphicsPage> {
  final DatabaseService _db = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Métricas'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ListView(
          children: [
            // Pie chart: estados
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    const Text('Distribución de citas por estado', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 220,
                      child: StreamBuilder<Map<String,int>>(
                        stream: _db.streamAppointmentsCountByState(widget.doctorId),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          final data = snapshot.data!;
                          final total = data.values.fold<int>(0, (a,b) => a+b);
                          if (total == 0) {
                            return const Center(child: Text('No hay citas registradas'));
                          }
                          final sections = <PieChartSectionData>[];
                          final colors = {
                            'pendiente': Colors.orange,
                            'reagendada': Colors.purple,
                            'cancelada': Colors.red,
                            'atendida': Colors.green,
                          };
                          int idx = 0;
                          data.forEach((k,v) {
                            final value = v.toDouble();
                            sections.add(PieChartSectionData(
                              color: colors[k],
                              value: value,
                              title: '${((value/total)*100).toStringAsFixed(0)}%',
                              radius: 60,
                              titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                            ));
                            idx++;
                          });

                          return Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: PieChart(
                                  PieChartData(
                                    sections: sections,
                                    centerSpaceRadius: 28,
                                    sectionsSpace: 2,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 1,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: data.keys.map((k) {
                                    final color = colors[k];
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                                      child: Row(
                                        children: [
                                          Container(width: 14, height: 14, color: color),
                                          const SizedBox(width: 8),
                                          Expanded(child: Text('$k: ${data[k]}')),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Bar chart: citas por mes (últimos 6 meses)
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    const Text('Citas por mes (últimos 6 meses)', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 220,
                      child: StreamBuilder<Map<String,int>>(
                        stream: _db.streamAppointmentsPerMonth(widget.doctorId, monthsBack: 6),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                          final map = snapshot.data!;
                          final keys = map.keys.toList();
                          final values = map.values.toList();
                          if (values.every((v) => v == 0)) {
                            return const Center(child: Text('No hay citas en los últimos meses'));
                          }

                          // Crear barras
                          final bars = <BarChartGroupData>[];
                          for (int i = 0; i < keys.length; i++) {
                            bars.add(BarChartGroupData(x: i, barRods: [
                              BarChartRodData(toY: values[i].toDouble(), width: 18),
                            ]));
                          }

                          return BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: (values.reduce((a,b) => a>b?a:b)).toDouble() + 1,
                              barGroups: bars,
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      final idx = value.toInt();
                                      if (idx < 0 || idx >= keys.length) return const SizedBox.shrink();
                                      final label = keys[idx].split('-').last; 
                                      return SideTitleWidget(child: Text(label), axisSide: meta.axisSide);
                                    },
                                  ),
                                ),
                                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              gridData: FlGridData(show: true),
                              borderData: FlBorderData(show: false),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Pacientes únicos (Future)
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: FutureBuilder<int>(
                  future: _db.getUniquePatientsCountForDoctor(widget.doctorId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox(height: 60, child: Center(child: CircularProgressIndicator()));
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Pacientes únicos atendidos', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Text('${snapshot.data}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        const Text('Pacientes distintos registrados en tus citas'),
                      ],
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
