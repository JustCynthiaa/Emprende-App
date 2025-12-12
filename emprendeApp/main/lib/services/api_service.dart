import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiService {
  // URL para acceder al backend PHP en XAMPP
  // Para dispositivo físico conectado por USB: usa la IP de Ethernet (10.142.254.91)
  // Para emulador Android: usa 10.0.2.2
  static const String baseUrl = 'http://10.0.2.2/emprendeApp/main/server/php';

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final uri = Uri.parse('$baseUrl/login.php');
    final resp = await http.post(uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}));

    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }

    // Passthrough error
    return {'success': false, 'message': 'HTTP ${resp.statusCode}', 'detail': resp.body};
  }

  static Future<Map<String, dynamic>> register(String nombreUsuario, String email, String password) async {
    final uri = Uri.parse('$baseUrl/register.php');
    final resp = await http.post(uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombre_usuario': nombreUsuario,
          'email': email,
          'contraseña': password
        }));

    if (resp.statusCode == 200 || resp.statusCode == 201) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }

    // Si hay un error, intentar decodificar el mensaje
    try {
      final errorData = jsonDecode(resp.body) as Map<String, dynamic>;
      return errorData;
    } catch (e) {
      return {'success': false, 'message': 'HTTP ${resp.statusCode}', 'detail': resp.body};
    }
  }

  static Future<Map<String, dynamic>> agregarEmprendimiento(Map<String, dynamic> datos) async {
    final uri = Uri.parse('$baseUrl/agregarEmprendimiento.php');
    final resp = await http.post(uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(datos));

    if (resp.statusCode == 200 || resp.statusCode == 201) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }

    try {
      final errorData = jsonDecode(resp.body) as Map<String, dynamic>;
      return errorData;
    } catch (e) {
      return {'success': false, 'message': 'HTTP ${resp.statusCode}', 'detail': resp.body};
    }
  }

  static Future<List<dynamic>> listarEmprendimientos() async {
    try {
      final uri = Uri.parse('$baseUrl/listarEmprendimientos.php');
      final resp = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        return data['emprendimientos'] ?? [];
      }

      return [];
    } catch (e) {
      print('Error en listarEmprendimientos: $e');
      return [];
    }
  }

  static Future<List<dynamic>> listarProductos() async {
    try {
      final uri = Uri.parse('$baseUrl/listarProductos.php');
      final resp = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        return data['productos'] ?? [];
      }

      return [];
    } catch (e) {
      print('Error en listarEmprendimientos: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> obtenerDetalleEmprendimiento(int id) async {
    final uri = Uri.parse('$baseUrl/obtenerDetalle.php?id=$id');
    final resp = await http.get(uri, headers: {'Content-Type': 'application/json'});

    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }

    return {'success': false, 'message': 'Emprendimiento no encontrado'};
  }

  static Future<Map<String, dynamic>> editarEmprendimiento(int id, Map<String, dynamic> datos) async {
    final uri = Uri.parse('$baseUrl/editarEmprendimiento.php');
    final requestData = {...datos, 'id_emprendimiento': id};
    final resp = await http.post(uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestData));

    // Loguear respuesta para debugging
    // ignore: avoid_print
    print('editarEmprendimiento status: ${resp.statusCode}');
    // ignore: avoid_print
    print('editarEmprendimiento body: ${resp.body}');

    if (resp.statusCode == 200) {
      try {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      } catch (e) {
        // Si el JSON es inválido a pesar de status 200, devolver error con detalles
        return {
          'success': false,
          'message': 'Error al procesar respuesta del servidor',
          'detail': 'Invalid JSON: ${resp.body}',
        };
      }
    }

    try {
      final errorData = jsonDecode(resp.body) as Map<String, dynamic>;
      return errorData;
    } catch (e) {
      return {
        'success': false,
        'message': 'HTTP ${resp.statusCode}',
        'detail': resp.body,
      };
    }
  }

  static Future<Map<String, dynamic>> eliminarEmprendimiento(
      int id, int userId) async {
    final uri = Uri.parse('$baseUrl/eliminarEmprendimiento.php');
    final resp = await http.post(uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id_emprendimiento': id,
          'id_usuario': userId,
        }));

    // Siempre intentamos decodificar para extraer mensaje del backend
    try {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      // Normalizamos para asegurarnos de tener success y status
      if (!data.containsKey('success')) {
        data['success'] = resp.statusCode == 200;
      }
      data['statusCode'] = resp.statusCode;
      return data;
    } catch (_) {
      // Si no es JSON, devolvemos una estructura con el status y el cuerpo bruto
      return {
        'success': resp.statusCode == 200,
        'statusCode': resp.statusCode,
        'message': 'HTTP ${resp.statusCode}',
        'raw': resp.body,
      };
    }
  }

  static Future<List<dynamic>> obtenerEmprendimientosDelUsuario(int userId) async {
    final uri = Uri.parse('$baseUrl/obtenerEmprendimientosUsuario.php?id_usuario=$userId');
    final resp = await http.get(uri, headers: {'Content-Type': 'application/json'});

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      return data['emprendimientos'] ?? [];
    }

    return [];
  }
}
