import 'package:flutter/material.dart';
import 'package:movil_jmas_reg/app_drawer.dart';
import 'package:movil_jmas_reg/controllers/lectenviar_controller.dart';
import 'package:movil_jmas_reg/registros/registro_screen.dart';

class ListLecturasScreen extends StatefulWidget {
  const ListLecturasScreen({super.key});

  @override
  State<ListLecturasScreen> createState() => _ListLecturasScreenState();
}

class _ListLecturasScreenState extends State<ListLecturasScreen> {
  final LectenviarController _lectenviarController = LectenviarController();
  List<LectEnviar> _lecturas = [];
  List<LectEnviar> _filteredLecturas = [];
  bool _isLoading = true;
  // ignore: unused_field
  bool? _filterEstado;

  @override
  void initState() {
    super.initState();
    _loadLecturas();
  }

  Future<void> _loadLecturas() async {
    try {
      final lecturas = await _lectenviarController.listLecturas();
      setState(() {
        _lecturas = lecturas;
        _filteredLecturas = lecturas;
        _isLoading = false;
      });
    } catch (e) {
      // ignore: avoid_print
      print('Error cargar lectura | list screen | try: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyFilter(bool? estado) {
    setState(() {
      _filterEstado = estado;
      if (estado == null) {
        _filteredLecturas = _lecturas;
      } else {
        _filteredLecturas =
            _lecturas.where((lectura) => lectura.estado == estado).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listado de Lecturas'),
        actions: [
          PopupMenuButton<bool?>(
            onSelected: _applyFilter,
            itemBuilder: (context) => [
              const PopupMenuItem<bool?>(
                value: null,
                child: Text('Todos'),
              ),
              const PopupMenuItem<bool?>(
                value: true,
                child: Text('Hecho'),
              ),
              const PopupMenuItem<bool?>(
                value: false,
                child: Text('Pendiente'),
              ),
            ],
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadLecturas,
              child: ListView.builder(
                itemCount: _filteredLecturas.length,
                itemBuilder: (context, index) {
                  final lectura = _filteredLecturas[index];
                  return _buildLecturaCard(lectura);
                },
              ),
            ),
    );
  }

  Widget _buildLecturaCard(LectEnviar lectura) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        title: Text(lectura.nombre ?? 'Sin nombre'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cuenta: ${lectura.cuenta ?? 'N/A'}'),
            Text('Dirección: ${lectura.direccion ?? 'N/A'}'),
            Text('Medidor: ${lectura.medidor ?? 'N/A'}'),
            Text('Estado: ${lectura.estado == true ? 'Hecho' : 'Pendiente'}'),
          ],
        ),
        trailing: Icon(
          lectura.estado == true ? Icons.check_circle : Icons.pending,
          color: lectura.estado == true ? Colors.green : Colors.orange,
        ),
        onTap: () {
          _navigateToRegistroScreen(context, lectura);
        },
      ),
    );
  }

  void _navigateToRegistroScreen(BuildContext context, LectEnviar lectura) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegistroScreen(
          lecturaSeleccionada: lectura,
          lecturasList: _lecturas,
        ),
      ),
    );
  }
}
