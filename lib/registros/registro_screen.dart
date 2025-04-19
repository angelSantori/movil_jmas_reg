import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:movil_jmas_reg/app_drawer.dart';
import 'package:movil_jmas_reg/controllers/lectenviar_controller.dart';
import 'package:movil_jmas_reg/controllers/problemas_controller.dart';
import 'package:movil_jmas_reg/widgets/device_utils.dart';
import 'package:movil_jmas_reg/widgets/mensajes.dart';
import 'package:path_provider/path_provider.dart';

class RegistroScreen extends StatefulWidget {
  final LectEnviar? lecturaSeleccionada;
  final List<LectEnviar>? lecturasList;
  const RegistroScreen({
    super.key,
    this.lecturaSeleccionada,
    this.lecturasList,
  });

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final TextEditingController _cuenta = TextEditingController();
  final TextEditingController _ruta = TextEditingController();
  final TextEditingController _nombre = TextEditingController();
  final TextEditingController _direccion = TextEditingController();
  final TextEditingController _medidor = TextEditingController();
  final TextEditingController _promedio = TextEditingController();
  final TextEditingController _lActual = TextEditingController();

  final LectenviarController _lectenviarController = LectenviarController();
  final ProblemasController _problemasController = ProblemasController();

  List<LectEnviar> _allLecturas = [];
  List<Problemas> _problemasList = [];
  Problemas? _selectedProblema;

  int _currentIndex = 0;
  bool _isLoading = true;

  File? _imageFile;
  bool _hasTakenPhoto = false;

  final String _fechaCaptura = DeviceUtils.getFecha();
  final Future<String> _ubicacionFuture = DeviceUtils.getCoordenadas();

  @override
  void initState() {
    super.initState();
    _loadProblemas();

    // Si viene con una lectura seleccionada, cargamos directamente
    if (widget.lecturaSeleccionada != null && widget.lecturasList != null) {
      _allLecturas = widget.lecturasList!;
      _currentIndex = _allLecturas.indexWhere(
        (l) => l.idLectEnviar == widget.lecturaSeleccionada!.idLectEnviar,
      );
      if (_currentIndex == -1) _currentIndex = 0;
      _loadCurrentLectura();
      _isLoading = false;
    } else {
      _loadData();
    }
  }

  Future<void> _takePhoto() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 85,
        maxWidth: 1024,
      );

      if (pickedFile != null) {
        // Verificar que el archivo sea una imagen válida
        final bytes = await pickedFile.readAsBytes();
        if (bytes.isEmpty) {
          throw Exception('La imagen está vacía');
        }

        // Intentar decodificar para verificar que es una imagen válida
        await decodeImageFromList(bytes);

        setState(() {
          _imageFile = File(pickedFile.path);
          _hasTakenPhoto = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al tomar foto: ${e.toString()}')),
      );
      print('Error en _takePhoto: $e');
    }
  }

  Future<void> _loadProblemas() async {
    try {
      final problemas = await _problemasController.listProblemas();
      setState(() {
        _problemasList = problemas;
        if (_problemasList.isNotEmpty) {
          _selectedProblema = _problemasList.first;
        }
      });
    } catch (e) {
      print('Error al cargar problemas | Registro Screen: $e');
    }
  }

  Future<void> _loadData() async {
    try {
      final lecturasList = await _lectenviarController.listLecturas();
      setState(() {
        _allLecturas = lecturasList;

        if (_allLecturas.isNotEmpty) {
          _loadCurrentLectura();
        }

        _isLoading = false;
      });
    } catch (e) {
      print('Error al cargar datos: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _savedLectura() async {
    if (!_hasTakenPhoto && _imageFile == null) {
      showAdvertence(context, 'Debes tomar una foto antes de guardar.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes tomar una foto antes de guardar')),
      );
      return;
    }

    try {
      final ubicacion = await _ubicacionFuture;

      final currentLecura = _allLecturas[_currentIndex].copyWith(
        lecact: int.tryParse(_lActual.text),
        idProblema: _selectedProblema?.idProblema,
        felean: _fechaCaptura,
        ubicacion: ubicacion, // Aquí usas la cadena obtenida
      );

      final success = await _lectenviarController.updateLectura(
        currentLecura,
        _imageFile,
      );

      if (success) {
        showOk(context, 'Registro guardado exitosamente.');
        setState(() {
          _allLecturas[_currentIndex] = currentLecura;
          _loadData();
        });
      } else {
        showError(context, 'Error al guardar el registro.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al obtener ubicación: ${e.toString()}')),
      );
    }
  }

  void _loadCurrentLectura() {
    if (_currentIndex >= 0 && _currentIndex < _allLecturas.length) {
      final current = _allLecturas[_currentIndex];
      _cuenta.text = current.cuenta?.toString() ?? '';
      _ruta.text = current.ruta?.toString() ?? '';
      _nombre.text = current.nombre ?? '';
      _direccion.text = current.direccion ?? '';
      _medidor.text = current.medidor ?? '';
      _promedio.text = current.promedio?.toString() ?? '';
      _lActual.text = current.lecact?.toString() ?? '';

      _hasTakenPhoto = false;
      _imageFile = null;

      if (current.img64 != null && current.img64!.isNotEmpty) {
        setState(() {
          _hasTakenPhoto = true;
        });
      } else {
        setState(() {
          _hasTakenPhoto = false;
          _imageFile = null;
        });
      }

      if (_problemasList.isNotEmpty) {
        if (current.idProblema != null && current.idProblema! > 0) {
          _selectedProblema = _problemasList.firstWhere(
            (p) => p.idProblema == current.idProblema,
            orElse: () => _problemasList.first,
          );
        } else {
          _selectedProblema = _problemasList.first;
        }
      }
    }
  }

  // ignore: unused_element
  Future<File?> _base64ToFile(String base64String) async {
    try {
      final bytes = base64.decode(base64String);
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/temp_image.jpg');
      await file.writeAsBytes(bytes);
      return file;
    } catch (e) {
      print('Error al convertir base64 a File: $e');
      return null;
    }
  }

  void _nextLectura() {
    if (_currentIndex < _allLecturas.length - 1) {
      setState(() {
        _currentIndex++;
        _loadCurrentLectura();
      });
    }
  }

  void _previusLectura() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _loadCurrentLectura();
      });
    }
  }

  bool get _isFirstRecord => _currentIndex == 0;
  bool get _isLastRecord => _currentIndex == _allLecturas.length - 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lecturas JMAS'),
        centerTitle: true,
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        ),
      ),
      drawer: const AppDrawer(),
      body: Container(
        decoration: BoxDecoration(gradient: _getBackGroundColor()),
        child:
            _isLoading
                ? Center(
                  child: CircularProgressIndicator(
                    color: Colors.green.shade900,
                  ),
                )
                : Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          'Registro ${_currentIndex + 1} de ${_allLecturas.length}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Container(
                          height: _hasTakenPhoto ? 400 : 50,
                          width: _hasTakenPhoto ? 200 : 50,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: _buildImageWidget(),
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: TextField(
                                controller: _cuenta,
                                decoration: const InputDecoration(
                                  labelText: 'Cuenta',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              flex: 1,
                              child: TextField(
                                controller: _ruta,
                                decoration: const InputDecoration(
                                  labelText: 'Ruta',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        //Nombre
                        TextField(
                          controller: _nombre,
                          decoration: const InputDecoration(
                            labelText: 'Nombre',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 15),
                        TextField(
                          controller: _direccion,
                          decoration: const InputDecoration(
                            labelText: 'Dirección',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 15),
                        TextField(
                          controller: _medidor,
                          decoration: const InputDecoration(
                            labelText: 'Medidor',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: Text(
                                'Promedio: ${_promedio.text}',
                                style: const TextStyle(fontSize: 17),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 1,
                              child: TextField(
                                controller: _lActual,
                                decoration: const InputDecoration(
                                  labelText: 'L. Actual',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        DropdownButtonFormField<Problemas>(
                          value: _selectedProblema,
                          decoration: const InputDecoration(
                            labelText: 'Problema',
                            border: OutlineInputBorder(),
                          ),
                          items:
                              _problemasList.map((Problemas problema) {
                                return DropdownMenuItem<Problemas>(
                                  value: problema,
                                  child: Text(problema.descripcionProb ?? ''),
                                );
                              }).toList(),
                          onChanged: (Problemas? newValue) {
                            setState(() {
                              _selectedProblema = newValue;
                            });
                          },
                        ),
                        const SizedBox(height: 20),
                        //Navegación
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_ios_rounded),
                              onPressed:
                                  _isFirstRecord ? null : _previusLectura,
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.all(16),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.save),
                              onPressed: _hasTakenPhoto ? _savedLectura : null,
                              style: IconButton.styleFrom(
                                backgroundColor:
                                    _hasTakenPhoto ? Colors.green : Colors.grey,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.all(16),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.arrow_forward),
                              onPressed: _isLastRecord ? null : _nextLectura,
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.all(16),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.camera_alt),
                              onPressed: _takePhoto,
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.all(16),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }

  @override
  void dispose() {
    _cuenta.dispose();
    _ruta.dispose();
    _nombre.dispose();
    _direccion.dispose();
    _medidor.dispose();
    _promedio.dispose();
    _lActual.dispose();
    super.dispose();
  }

  Widget _buildImageWidget() {
    try {
      if (_imageFile != null) {
        return Image.file(
          _imageFile!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildErrorWidget('Error al cargar imagen nueva');
          },
        );
      }

      final currentImg64 = _allLecturas[_currentIndex].img64;
      if (currentImg64 != null && currentImg64.isNotEmpty) {
        // Verificar si es una cadena base64 válida
        if (!RegExp(r'^[a-zA-Z0-9+/]+={0,2}$').hasMatch(currentImg64)) {
          return _buildErrorWidget('Formato base64 inválido');
        }

        try {
          final bytes = base64Decode(currentImg64);
          if (bytes.isEmpty) {
            return _buildErrorWidget('Imagen vacía');
          }

          return Image.memory(
            bytes,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildErrorWidget('Error al cargar imagen guardada');
            },
          );
        } catch (e) {
          return _buildErrorWidget('Error al decodificar imagen');
        }
      }

      return _buildPlaceholderWidget();
    } catch (e) {
      return _buildErrorWidget('Error inesperado: ${e.toString()}');
    }
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, color: Colors.red),
          Text(message, style: const TextStyle(color: Colors.red)),
        ],
      ),
    );
  }

  Widget _buildPlaceholderWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_camera, color: Colors.grey),
          Text('S/F', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  // Agrega estas variables en tu clase _RegistroScreenState
  final Gradient _gradienteVerde = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      const Color.fromARGB(255, 255, 255, 255).withOpacity(0.9),
      const Color.fromARGB(255, 179, 243, 105).withOpacity(0.6),
      const Color.fromARGB(255, 136, 255, 0).withOpacity(0.3),
    ],
  );

  final Gradient _gradienteNaranja = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      const Color.fromARGB(255, 255, 255, 255).withOpacity(0.9),
      const Color.fromARGB(255, 231, 205, 181).withOpacity(0.6),
      const Color(0xFFFF9800).withOpacity(0.3),
    ],
  );

  final Gradient _gradienteDefault = LinearGradient(
    colors: [Colors.white, Colors.white],
  );

  Gradient _getBackGroundColor() {
    if (_allLecturas.isNotEmpty && _currentIndex < _allLecturas.length) {
      final currentLectura = _allLecturas[_currentIndex];
      return currentLectura.estado == true
          ? _gradienteVerde
          : _gradienteNaranja;
    }
    return _gradienteDefault;
  }
}
