import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const BankrollBetProApp());
}

class BankrollBetProApp extends StatelessWidget {
  const BankrollBetProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0F1A),
        cardColor: const Color(0xFF141C26),
      ),
      home: const HomeScreen(),
    );
  }
}

class LogDia {
  final int dia;
  final double bancaInicial;
  final double apuesta;
  final bool gano;
  final double bancaFinal;

  LogDia({
    required this.dia,
    required this.bancaInicial,
    required this.apuesta,
    required this.gano,
    required this.bancaFinal,
  });

  Map<String, dynamic> toJson() => {
        'dia': dia,
        'bancaInicial': bancaInicial,
        'apuesta': apuesta,
        'gano': gano,
        'bancaFinal': bancaFinal,
      };

  factory LogDia.fromJson(Map<String, dynamic> json) => LogDia(
        dia: json['dia'],
        bancaInicial: json['bancaInicial'].toDouble(),
        apuesta: json['apuesta'].toDouble(),
        gano: json['gano'],
        bancaFinal: json['bancaFinal'].toDouble(),
      );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final double _capitalInicial = 1000.0;
  final double _porcentajeRiesgo = 5.0;
  
  List<LogDia> _logs = [];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final prefs = await SharedPreferences.getInstance();
    final String? logsString = prefs.getString('logs_bankroll');
    if (logsString != null) {
      final List<dynamic> jsonList = jsonDecode(logsString);
      setState(() {
        _logs = jsonList.map((item) => LogDia.fromJson(item)).toList();
      });
    } else {
      setState(() {
        _logs = [
          LogDia(dia: 1, bancaInicial: 1000.0, apuesta: 50.0, gano: true, bancaFinal: 1100.0),
          LogDia(dia: 2, bancaInicial: 1100.0, apuesta: 55.0, gano: false, bancaFinal: 1045.0),
          LogDia(dia: 3, bancaInicial: 1045.0, apuesta: 52.25, gano: true, bancaFinal: 1149.50),
          LogDia(dia: 4, bancaInicial: 1149.50, apuesta: 57.48, gano: true, bancaFinal: 1264.45),
          LogDia(dia: 5, bancaInicial: 1264.45, apuesta: 63.22, gano: false, bancaFinal: 1201.23),
          LogDia(dia: 6, bancaInicial: 1201.23, apuesta: 60.06, gano: true, bancaFinal: 1261.29),
        ];
      });
      _guardarDatos();
    }
  }

  Future<void> _guardarDatos() async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = jsonEncode(_logs.map((item) => item.toJson()).toList());
    await prefs.setString('logs_bankroll', jsonString);
  }

  double get _capitalActual => _logs.isEmpty ? _capitalInicial : _logs.last.bancaFinal;
  double get _gananciaPerdida => _capitalActual - _capitalInicial;
  double get _roi => _capitalInicial > 0 ? (_gananciaPerdida / _capitalInicial) * 100 : 0;
  
  double get _cuotaPromedio => 2.0;

  void _mostrarFormularioAgregar() {
    final TextEditingController cuotaController = TextEditingController(text: "2.0");

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF141C26),
          title: const Text("Registrar Operación Real", style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Banca sugerida para apostar: \$${(_capitalActual * (_porcentajeRiesgo / 100)).toStringAsFixed(2)} (Riesgo $_porcentajeRiesgo%)",
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: cuotaController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: "Cuota de la apuesta",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.trending_up),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () {
                double cuota = double.tryParse(cuotaController.text) ?? 2.0;
                _guardarNuevaOperacion(cuota, false);
                Navigator.pop(context);
              },
              child: const Text("Perdida ❌", style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () {
                double cuota = double.tryParse(cuotaController.text) ?? 2.0;
                _guardarNuevaOperacion(cuota, true);
                Navigator.pop(context);
              },
              child: const Text("Ganada  ", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _guardarNuevaOperacion(double cuota, bool gano) {
    setState(() {
      int proximoDia = _logs.isEmpty ? 1 : _logs.last.dia + 1;
      double bancaIn = _capitalActual;
      double apuesta = bancaIn * (_porcentajeRiesgo / 100);
      
      double gananciaPerdida = gano ? (apuesta * (cuota - 1)) : -apuesta;
      double bancaFin = bancaIn + gananciaPerdida;

      _logs.add(LogDia(
        dia: proximoDia,
        bancaInicial: bancaIn,
        apuesta: apuesta,
        gano: gano,
        bancaFinal: bancaFin,
      ));
    });
    _guardarDatos();
  }

  void _reiniciarMes() {
    setState(() {
      _logs.clear();
    });
    _guardarDatos();
  }

  Widget _buildConfigRow(String title, String value, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.circle, size: 8, color: iconColor),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(color: Colors.white70)),
            ],
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF141C26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Text("Bankroll ", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                          Text("Bet Pro", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                        ],
                      ),
                      const Text("Gestiona tu banca como un profesional", style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.bar_chart, color: Colors.grey), 
                    onPressed: () {},
                  )
                ],
              ),
              const SizedBox(height: 20),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text("Configuración del Mes", style: TextStyle(fontWeight: FontWeight.bold)),
                          Icon(Icons.chevron_right, color: Colors.grey, size: 16),
                        ],
                      ),
                      const Divider(height: 20),
                      _buildConfigRow("Mes de Gestión", "Mayo 2025", Colors.blue),
                      _buildConfigRow("Capital Inicial", "\$${_capitalInicial.toStringAsFixed(2)}", Colors.green),
                      _buildConfigRow("Cuota Promedio", _cuotaPromedio.toStringAsFixed(2), Colors.purple),
                      _buildConfigRow("% Riesgo por Paso", "${_porcentajeRiesgo.toStringAsFixed(0)}%", Colors.orange),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildSummaryCard("Capital Actual", "\$${_capitalActual.toStringAsFixed(2)}", Colors.green)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildSummaryCard("Ganancia / Pérdida", "\$${_gananciaPerdida.toStringAsFixed(2)}", Colors.blueAccent)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildSummaryCard("ROI %", "${_roi.toStringAsFixed(2)}%", Colors.purple)),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Registro de Operaciones", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Expanded(child: Text("Día", style: TextStyle(color: Colors.grey, fontSize: 12))),
                          Expanded(child: Text("Banca Inicial", style: TextStyle(color: Colors.grey, fontSize: 12), textAlign: TextAlign.right)),
                          Expanded(child: Text("Apuesta", style: TextStyle(color: Colors.grey, fontSize: 12), textAlign: TextAlign.right)),
                          Expanded(child: Text("Result.", style: TextStyle(color: Colors.grey, fontSize: 12), textAlign: TextAlign.center)),
                          Expanded(child: Text("Banca Final", style: TextStyle(color: Colors.grey, fontSize: 12), textAlign: TextAlign.right)),
                        ],
                      ),
                      const Divider(),
                      _logs.isEmpty 
                        ? const Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Center(child: Text("No hay operaciones este mes", style: TextStyle(color: Colors.grey))),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _logs.length,
                            itemBuilder: (context, index) {
                              final log = _logs[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(child: Text("${log.dia}")),
                                    Expanded(child: Text("\$${log.bancaInicial.toStringAsFixed(0)}", textAlign: TextAlign.right)),
                                    Expanded(child: Text("\$${log.apuesta.toStringAsFixed(0)}", textAlign: TextAlign.right)),
                                    Expanded(
                                      child: Icon(
                                        log.gano ? Icons.check_circle_outline : Icons.cancel_outlined,
                                        color: log.gano ? Colors.green : Colors.red,
                                        size: 16,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        "\$${log.bancaFinal.toStringAsFixed(0)}",
                                        style: TextStyle(color: log.gano ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _mostrarFormularioAgregar,
                child: const Text("Agregar Día", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: const BorderSide(color: Colors.grey),
                ),
                onPressed: _reiniciarMes,
                child: const Text("Reiniciar Mes", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}