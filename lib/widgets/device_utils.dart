import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';

class DeviceUtils {
  // Obtiene la fecha en formato "dd/MM/yyyy HH:mm"
  static String getFecha() {
    final now = DateTime.now();
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    return formatter.format(now);
  }

  // Obtiene SOLO las coordenadas (latitud y longitud)
  static Future<String> getCoordenadas() async {
    try {
      // Verificar y solicitar permisos
      await _verificarPermisosUbicacion();

      // Obtener posición
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Retornar como cadena concatenada "latitud,longitud"
      return '${position.latitude},${position.longitude}';
    } catch (e) {
      throw Exception('Error al obtener coordenadas: ${e.toString()}');
    }
  }

  // Método privado para manejo de permisos
  static Future<void> _verificarPermisosUbicacion() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('El servicio de ubicación está desactivado');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Permisos de ubicación denegados');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Permisos de ubicación permanentemente denegados. Active los permisos en configuración.',
      );
    }
  }
}
