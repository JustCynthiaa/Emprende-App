import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../services/api_service.dart';
import '../services/session_service.dart';

class EditarEmprendimientoScreen extends StatefulWidget {
  const EditarEmprendimientoScreen({super.key});

  @override
  State<EditarEmprendimientoScreen> createState() =>
      _EditarEmprendimientoScreenState();
}

class _EditarEmprendimientoScreenState
    extends State<EditarEmprendimientoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _ubicacionController = TextEditingController();
  final List<Map<String, dynamic>> _productos = [];
  final List<int> _productosAEliminar = [];
  
  // Imagen del emprendimiento
  XFile? _imagenEmprendimientoNueva;
  String? _imagenEmprendimientoExistente;
  
  final Map<String, bool> _dias = {
    'Lunes': false,
    'Martes': false,
    'Miércoles': false,
    'Jueves': false,
    'Viernes': false,
  };
  final Map<String, bool> _diasOriginal = {};
  final Map<String, TextEditingController> _horaInicio = {};
  final Map<String, TextEditingController> _horaFin = {};
  final Map<String, TextEditingController> _ubicacionDia = {};
  int? _idEmprendimiento;
  bool _loading = false;
  bool _estadoActivo = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      _idEmprendimiento = args is int ? args : null;
      for (final d in _dias.keys) {
        _horaInicio[d] = TextEditingController(text: '09:00');
        _horaFin[d] = TextEditingController(text: '17:00');
        _ubicacionDia[d] = TextEditingController(text: '');
      }
      _cargarDatos();
    });
  }

  Future<void> _cargarDatos() async {
    if (_idEmprendimiento == null || _idEmprendimiento! <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Falta el ID del emprendimiento')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final resp = await ApiService.obtenerDetalleEmprendimiento(
        _idEmprendimiento!,
      );
      if (resp['success'] == true && resp['emprendimiento'] != null) {
        final emp = resp['emprendimiento'] as Map<String, dynamic>;
        _nombreController.text = emp['nombre_emprendimiento']?.toString() ?? '';
        _descripcionController.text = emp['descripcion_emp']?.toString() ?? '';
        _estadoActivo = (emp['estado'] ?? 1) == 1;
        
        // Cargar imagen del emprendimiento si existe
        _imagenEmprendimientoExistente = emp['imagen_emprendimiento_url'] as String?;
        
        // Productos existentes
        _productos.clear();
        _productosAEliminar.clear();
        final productos = emp['productos'] as List? ?? [];
        for (final p in productos) {
          _productos.add({
            'id_producto': p['id_producto'],
            'descripcion': TextEditingController(
              text: p['descripcion_producto']?.toString() ?? '',
            ),
            'precio': TextEditingController(
              text: p['precio']?.toString() ?? '',
            ),
            'imagen_existente':
                p['imagen_url'] as String?, // Imagen actual del producto
            'imagen_nueva': null as XFile?, // Nueva imagen seleccionada
          });
        }
        if (_productos.isEmpty) {
          _productos.add({
            'descripcion': TextEditingController(),
            'precio': TextEditingController(),
          });
        }

        // Horarios
        final horarios = emp['horarios'] as List? ?? [];
        _diasOriginal.clear();
        _diasOriginal.addAll(_dias.map((k, v) => MapEntry(k, false)));
        
        // Variable para guardar la ubicación general (tomar la primera ubicación única)
        String? ubicacionGeneral;
        
        for (final h in horarios) {
          final dia = h['dia_semana']?.toString();
          if (dia != null && _dias.containsKey(dia)) {
            _dias[dia] = true;
            _diasOriginal[dia] = true;
            _horaInicio[dia]?.text = h['hora_inicial']?.toString() ?? '09:00';
            _horaFin[dia]?.text = h['hora_final']?.toString() ?? '17:00';
            
            final ubicacionHorario = h['ubicacion']?.toString() ?? '';
            _ubicacionDia[dia]?.text = ubicacionHorario;
            
            // Guardar la primera ubicación no vacía como ubicación general
            if (ubicacionGeneral == null && ubicacionHorario.isNotEmpty) {
              ubicacionGeneral = ubicacionHorario;
            }
          }
        }
        
        // Establecer la ubicación general
        _ubicacionController.text = ubicacionGeneral ?? '';
      } else {
        final msg =
            resp['message']?.toString() ??
            'No se pudo cargar el emprendimiento';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar datos: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _seleccionarHora(
    BuildContext context,
    String dia,
    bool esInicio,
  ) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1A3B5D),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      // Convertir a formato 24 horas
      final hour = picked.hour.toString().padLeft(2, '0');
      final minute = picked.minute.toString().padLeft(2, '0');
      final hora = '$hour:$minute';

      setState(() {
        if (esInicio) {
          _horaInicio[dia]?.text = hora;
        } else {
          _horaFin[dia]?.text = hora;
        }
      });
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _ubicacionController.dispose();
    super.dispose();
  }

  Widget _buildImageMemory(String base64String) {
    try {
      final base64Str = base64String.split(',').last;
      
      // Validar que sea base64 válido
      if (base64Str.isEmpty) {
        return _buildImagePlaceholder();
      }
      
      final imageBytes = base64Decode(base64Str);
      
      // Validar que tenga datos
      if (imageBytes.isEmpty) {
        return _buildImagePlaceholder();
      }
      
      return Image.memory(
        imageBytes,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildImagePlaceholder();
        },
      );
    } catch (e) {
      // Log error pero no muestra a usuario
      // ignore: avoid_print
      print('Error decodificando imagen: $e');
      return _buildImagePlaceholder();
    }
  }

  Widget _buildImagePlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported,
            color: Colors.grey[400],
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'Imagen no disponible',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_idEmprendimiento == null || _idEmprendimiento! <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Falta el ID del emprendimiento')),
      );
      return;
    }

    final userId = await SessionService.getUserId();
    if (userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Debes iniciar sesión')));
      return;
    }

    setState(() => _loading = true);
    try {
      // Construir lista de productos válidos (nuevos y existentes)
      final productosPayload = <Map<String, dynamic>>[];

      for (final p in _productos) {
        final desc = p['descripcion']!.text.trim();
        final precioText = p['precio']!.text.trim();
        if (desc.isEmpty && precioText.isEmpty) continue;

        final payload = {
          'descripcion': desc,
          'precio': double.tryParse(precioText) ?? 0,
        };

        // Si tiene id_producto, incluirlo para que no intente insertar
        if (p['id_producto'] != null) {
          payload['id_producto'] = p['id_producto'];
        }

        // Agregar imagen si se seleccionó una nueva
        if (p['imagen_nueva'] != null) {
          final bytes = await p['imagen_nueva']!.readAsBytes();
          payload['imagen_url'] =
              'data:image/jpeg;base64,${base64Encode(bytes)}';
        }

        productosPayload.add(payload);
      }

      // Construir horarios: solo los días seleccionados
      final horariosPayload = _dias.entries.where((e) => e.value).map((e) {
        final dia = e.key;
        final horaIni = _horaInicio[dia]?.text.trim().isEmpty == true
            ? '09:00:00'
            : _horaInicio[dia]!.text.trim();
        final horaFin = _horaFin[dia]?.text.trim().isEmpty == true
            ? '17:00:00'
            : _horaFin[dia]!.text.trim();
        // Si tiene ubicación específica, usarla; si no, usar la ubicación general
        final ubicacion = (!_ubicacionDia[dia]!.text.trim().isEmpty
            ? _ubicacionDia[dia]!.text.trim()
            : _ubicacionController.text.trim());
        return {
          'dia_semana': dia,
          'hora_inicial': horaIni,
          'hora_final': horaFin,
          'ubicacion': ubicacion,
        };
      }).toList();

      final payload = {
        'id_emprendimiento': _idEmprendimiento,
        'id_usuario': userId,
        'nombre_emprendimiento': _nombreController.text.trim(),
        'descripcion_emp': _descripcionController.text.trim(),
        'contacto': null,
        'ubicacion': _ubicacionController.text.trim(),
        'estado': _estadoActivo ? 1 : 0,
        'productos': productosPayload,
        'productos_a_eliminar': _productosAEliminar,
        'horarios': horariosPayload,
      };

      // Procesar imagen del emprendimiento si se seleccionó una nueva
      if (_imagenEmprendimientoNueva != null) {
        final bytes = await _imagenEmprendimientoNueva!.readAsBytes();
        payload['imagen_emprendimiento'] = base64Encode(bytes);
      }

      final resp = await ApiService.editarEmprendimiento(
        _idEmprendimiento!,
        payload,
      );

      if (resp['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Emprendimiento actualizado exitosamente'),
            ),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        final msg = resp['message']?.toString() ?? 'No se pudo actualizar';
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al actualizar: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF1A3B5D); // Azul marino

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Editar Emprendimiento',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 20),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nombreController,
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  labelText: 'Nombre del emprendimiento',
                  prefixIcon: const Icon(Icons.business, color: primaryColor),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: primaryColor, width: 2),
                  ),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Ingrese el nombre' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descripcionController,
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  labelText: 'Descripción',
                  prefixIcon: const Icon(
                    Icons.description,
                    color: primaryColor,
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: primaryColor, width: 2),
                  ),
                ),
                maxLines: 4,
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Ingrese una descripción'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ubicacionController,
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  labelText: 'Ubicación',
                  prefixIcon: const Icon(
                    Icons.location_on,
                    color: primaryColor,
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: primaryColor, width: 2),
                  ),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Ingrese la ubicación'
                    : null,
              ),
              const SizedBox(height: 16),
              
              // Imagen del emprendimiento
              GestureDetector(
                onTap: () async {
                  final picker = ImagePicker();
                  final imagen = await picker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 1200,
                    maxHeight: 1200,
                    imageQuality: 85,
                  );
                  if (imagen != null) {
                    setState(() {
                      _imagenEmprendimientoNueva = imagen;
                    });
                  }
                },
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                  child: _imagenEmprendimientoNueva != null
                      ? Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(_imagenEmprendimientoNueva!.path),
                                width: double.infinity,
                                height: 180,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _imagenEmprendimientoNueva = null;
                                  });
                                },
                                icon: const Icon(Icons.delete),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        )
                      : _imagenEmprendimientoExistente != null
                          ? Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.memory(
                                    base64Decode(_imagenEmprendimientoExistente!
                                        .split(',')
                                        .last),
                                    width: double.infinity,
                                    height: 180,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _imagenEmprendimientoExistente = null;
                                      });
                                    },
                                    icon: const Icon(Icons.delete),
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate_outlined,
                                    size: 48,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Toca para agregar/cambiar imagen del emprendimiento',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                ),
              ),
              
              const SizedBox(height: 24),

              // Interruptor de estado (disponible/no disponible)
              Card(
                margin: const EdgeInsets.all(0),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Estado del emprendimiento',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _estadoActivo ? 'Disponible' : 'No disponible',
                            style: TextStyle(
                              fontSize: 14,
                              color: _estadoActivo
                                  ? Colors.green[700]
                                  : Colors.red[700],
                            ),
                          ),
                        ],
                      ),
                      Switch(
                        value: _estadoActivo,
                        activeColor: Colors.green,
                        inactiveThumbColor: Colors.red,
                        onChanged: (value) {
                          setState(() {
                            _estadoActivo = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Productos',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              ..._productos.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Fila de datos del producto
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: item['descripcion'],
                                decoration: const InputDecoration(
                                  labelText: 'Descripción',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 110,
                              child: TextFormField(
                                controller: item['precio'],
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Precio',
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: _productos.length > 1
                                  ? () {
                                      setState(() {
                                        if (item['id_producto'] != null) {
                                          _productosAEliminar.add(
                                            item['id_producto'] as int,
                                          );
                                        }
                                        _productos.removeAt(idx);
                                      });
                                    }
                                  : null,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Sección de imagen
                        const Text(
                          'Imagen del producto',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () async {
                            final picker = ImagePicker();
                            final pickedFile = await picker.pickImage(
                              source: ImageSource.gallery,
                            );
                            if (pickedFile != null) {
                              setState(() {
                                item['imagen_nueva'] = XFile(pickedFile.path);
                              });
                            }
                          },
                          child: Container(
                            height: 120,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.grey[300]!,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey[50],
                            ),
                            child: item['imagen_nueva'] != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(7),
                                    child: Image.file(
                                      File(item['imagen_nueva']!.path),
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : (item['imagen_existente'] != null &&
                                      item['imagen_existente']!.startsWith(
                                        'data:image',
                                      ))
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(7),
                                    child: item['imagen_existente'] != null
                                        ? _buildImageMemory(
                                            item['imagen_existente']!,
                                          )
                                        : const SizedBox.shrink(),
                                  )
                                : Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_photo_alternate,
                                          color: Colors.grey[400],
                                          size: 32,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Seleccionar imagen',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
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
                );
              }),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _productos.add({
                        'descripcion': TextEditingController(),
                        'precio': TextEditingController(),
                      });
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar producto'),
                ),
              ),

              const SizedBox(height: 16),
              const Text(
                'Horarios por día',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ..._dias.keys.map((dia) {
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: _dias[dia],
                              onChanged: (v) {
                                setState(() {
                                  _dias[dia] = v ?? false;
                                });
                              },
                            ),
                            Text(
                              dia,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        if (_dias[dia] == true) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () =>
                                      _seleccionarHora(context, dia, true),
                                  child: AbsorbPointer(
                                    child: TextFormField(
                                      controller: _horaInicio[dia],
                                      decoration: const InputDecoration(
                                        labelText: 'Hora inicio (HH:MM)',
                                        suffixIcon: Icon(Icons.access_time),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () =>
                                      _seleccionarHora(context, dia, false),
                                  child: AbsorbPointer(
                                    child: TextFormField(
                                      controller: _horaFin[dia],
                                      decoration: const InputDecoration(
                                        labelText: 'Hora fin (HH:MM)',
                                        suffixIcon: Icon(Icons.access_time),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _ubicacionDia[dia],
                            decoration: const InputDecoration(
                              labelText: 'Ubicación específica',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 24),
              SizedBox(
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  icon: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: const Text(
                    'Actualizar Emprendimiento',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
