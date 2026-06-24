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
  double _capitalInicial = 1000.0;
  String _mesGestion = "Mayo 2025";
  final double _porcentajeRiesgoDefault = 5.0;
  
  List<LogDia> _logs = [];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final prefs = await SharedPreferences.getInstance();
    final String? logsString = prefs.getString('logs_bankroll');
    
    setState(() {
      _capitalInicial = prefs.getDouble('capital_inicial') ?? 1000.0;
      _mesGestion = prefs.getString('mes_gestion') ?? "Mayo 2025";
    });

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
        ];
      });
      _guardarDatos();
    }
  }

  Future<void> _guardarDatos() async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = jsonEncode(_logs.map((item) => item.toJson()).toList());
    await prefs.setString('logs_bankroll', jsonString);
    await prefs.setDouble('capital_inicial', _capitalInicial);
    await prefs.setString('mes_gestion', _mesGestion);
  }

  double get _capitalActual => _logs.isEmpty ? _capitalInicial : _logs.last.bancaFinal;
  double get _gananciaPerdida => _capitalActual - _capitalInicial;
  double get _roi => _capitalInicial > 0 ? (_gananciaPerdida / _capitalInicial) * 100 : 0;
  double get _cuotaPromedio => 2.0;

  void _mostrarFormularioConfiguracion() {
    final TextEditingController capitalController = TextEditingController(text: _capitalInicial.toString());
    final TextEditingController mesController = TextEditingController(text: _mesGestion);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF141C26),
          title: const Text("Configurar Parámetros", style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: mesController,
                decoration: const InputDecoration(
                  labelText: "Mes de Gestión",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_month),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: capitalController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: "Capital Inicial (\$)",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
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
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
              onPressed: () {
                setState(() {
                  _mesGestion = mesController.text;
                  _capitalInicial = double.tryParse(capitalController.text) ?? _capitalInicial;
                });
                _guardarDatos();
                Navigator.pop(context);
              },
              child: const Text("Guardar", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _mostrarFormularioAgregar() {
    final TextEditingController cuotaController = TextEditingController(text: "2.0");
    double sugerenciaDinero = _capitalActual * (_porcentajeRiesgoDefault / 100);
    final TextEditingController apuestaController = TextEditingController(text: sugerenciaDinero.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            double dineroApuesta = double.tryParse(apuestaController.text) ?? 0.0;
            double porcentajeCalculado = _capitalActual > 0 ? (dineroApuesta / _capitalActual) * 100 : 0.0;

            return AlertDialog(
              backgroundColor: const Color(0xFF141C26),
              title: const Text("Registrar Operación", style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: cuotaController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: "Cuota de la apuesta",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.trending_up),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: apuestaController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (val) {
                      setDialogState(() {});
                    },
                    decoration: const InputDecoration(
                      labelText: "Cantidad a apostar (\$)",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.money),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Impacto en la Banca: ${porcentajeCalculado.toStringAsFixed(2)}% del Bank total",
                    style: TextStyle(
                      color: porcentajeCalculado > 10 ? Colors.redAccent : Colors.greenAccent, 
                      fontSize: 13, 
                      fontWeight: FontWeight.bold
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
                    double monto = double.tryParse(apuestaController.text) ?? sugerenciaDinero;
                    _guardarNuevaOperacion(cuota, monto, false);
                    Navigator.pop(context);
                  },
                  child: const Text("Perdida ❌", style: TextStyle(color: Colors.white)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: () {
                    double cuota = double.tryParse(cuotaController.text) ?? 2.0;
                    double monto = double.tryParse(apuestaController.text) ?? sugerenciaDinero;
                    _guardarNuevaOperacion(cuota, monto, true);
                    Navigator.pop(context);
                  },
                  child: const Text("Ganada  ", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _guardarNuevaOperacion(double cuota, double montoApuesta, bool gano) {
    setState(() {
      int proximoDia = _logs.isEmpty ? 1 : _logs.last.dia + 1;
      double bancaIn = _capitalActual;
      
      double gananciaPerdida = gano ? (montoApuesta * (cuota - 1)) : -montoApuesta;
      double bancaFin = bancaIn + gananciaPerdida;

      _logs.add(LogDia(
        dia: proximoDia,
        bancaInicial: bancaIn,
        apuesta: montoApuesta,
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
        border: Border.all(color: color.withAlpha((0.3 * 255).round())),
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
              GestureDetector(
                onTap: _mostrarFormularioConfiguracion,
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text("Configuración del Mes (Toca para editar)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                            Icon(Icons.edit, color: Colors.blueAccent, size: 16),
                          ],
                        ),
                        const Divider(height: 20),
                        _buildConfigRow("Mes de Gestión", _mesGestion, Colors.blue),
                        _buildConfigRow("Capital Inicial", "\$${_capitalInicial.toStringAsFixed(2)}", Colors.green),
                        _buildConfigRow("Cuota Promedio", _cuotaPromedio.toStringAsFixed(2), Colors.purple),
                        _buildConfigRow("Riesgo Base Sugerido", "${_porcentajeRiesgoDefault.toStringAsFixed(0)}%", Colors.orange),
                      ],
                    ),
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