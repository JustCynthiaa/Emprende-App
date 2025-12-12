import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';

class AgregarEmprendimientoPage extends StatefulWidget {
  const AgregarEmprendimientoPage({super.key});

  @override
  State<AgregarEmprendimientoPage> createState() =>
      _AgregarEmprendimientoPageState();
}

class _AgregarEmprendimientoPageState extends State<AgregarEmprendimientoPage> {
  // Controladores del emprendimiento
  final tituloController = TextEditingController();
  final descripcionEmpController = TextEditingController();
  final ubicacionGeneralController = TextEditingController();

  final telefonoController = TextEditingController();
  final instagramController = TextEditingController();

  // Controladores para horarios
  final Map<String, TextEditingController> ubicacionPorDiaController = {};

  // Lista de productos
  final List<Map<String, dynamic>> productos = [];
  final ImagePicker _picker = ImagePicker();

  // Producto actual en edición
  TextEditingController descripcionActual = TextEditingController();
  TextEditingController precioActual = TextEditingController();
  XFile? imagenActual;

  // Imagen del emprendimiento
  XFile? imagenEmprendimiento;

  // Días con horarios
  final Map<String, bool> dias = {
    "Lunes": false,
    "Martes": false,
    "Miércoles": false,
    "Jueves": false,
    "Viernes": false,
  };

  final Map<String, TextEditingController> horaInicio = {};
  final Map<String, TextEditingController> horaFin = {};

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    for (var dia in dias.keys) {
      horaInicio[dia] = TextEditingController(text: "9:00");
      horaFin[dia] = TextEditingController(text: "9:00");
      ubicacionPorDiaController[dia] = TextEditingController();
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
          horaInicio[dia]?.text = hora;
        } else {
          horaFin[dia]?.text = hora;
        }
      });
    }
  }

  Future<void> _seleccionarImagen() async {
    final XFile? imagen = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (imagen != null) {
      setState(() {
        imagenActual = imagen;
      });
    }
  }

  void _agregarProducto() {
    // Validar que los campos del producto actual estén llenos
    if (descripcionActual.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa la descripción del producto')),
      );
      return;
    }

    if (precioActual.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa el precio del producto')),
      );
      return;
    }

    // Agregar producto a la lista con sus propios controladores
    setState(() {
      productos.add({
        'descripcion': descripcionActual.text.trim(),
        'precio': precioActual.text.trim(),
        'imagen': imagenActual,
        'descripcionController': TextEditingController(
          text: descripcionActual.text.trim(),
        ),
        'precioController': TextEditingController(
          text: precioActual.text.trim(),
        ),
      });

      // Limpiar SOLO los campos actuales para el nuevo producto
      descripcionActual.clear();
      precioActual.clear();
      imagenActual = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Producto ${productos.length} agregado. Puedes agregar otro.',
        ),
        duration: const Duration(seconds: 2),
      ),
    );

    print('Total productos agregados: ${productos.length}'); // Debug
  }

  Future<void> _guardarEmprendimiento() async {
    print('=== INICIANDO VALIDACIÓN ===');
    print('Total productos: ${productos.length}');

    // Si hay un producto en edición con datos válidos, agregarlo automáticamente
    if (descripcionActual.text.trim().isNotEmpty &&
        precioActual.text.trim().isNotEmpty) {
      final precioNum = double.tryParse(precioActual.text.trim());
      if (precioNum != null && precioNum > 0) {
        setState(() {
          productos.add({
            'descripcion': descripcionActual.text.trim(),
            'precio': precioActual.text.trim(),
            'imagen': imagenActual,
            'descripcionController': TextEditingController(
              text: descripcionActual.text.trim(),
            ),
            'precioController': TextEditingController(
              text: precioActual.text.trim(),
            ),
          });
          // Limpiar campos
          descripcionActual.clear();
          precioActual.clear();
          imagenActual = null;
        });
        print('Producto en edición agregado automáticamente');
      }
    }

    print('Total productos después de validar: ${productos.length}');

    // Validaciones
    if (tituloController.text.trim().isEmpty) {
      _mostrarError('Ingresa el título del emprendimiento');
      return;
    }

    if (descripcionEmpController.text.trim().isEmpty) {
      _mostrarError('Ingresa la descripción del emprendimiento');
      return;
    }

    if (ubicacionGeneralController.text.trim().isEmpty) {
      _mostrarError('Ingresa la ubicación general');
      return;
    }

    if (telefonoController.text.trim().isEmpty &&
        instagramController.text.trim().isEmpty) {
      _mostrarError('Ingresa al menos un medio de contacto');
      return;
    }

    print('Productos en lista: ${productos.length}');
    if (productos.isEmpty) {
      _mostrarError(
        'Agrega al menos un producto. Productos actuales: ${productos.length}',
      );
      return;
    }

    // Validar que todos los productos agregados tengan descripción y precio válidos
    for (int i = 0; i < productos.length; i++) {
      final producto = productos[i];
      final desc = producto['descripcionController']?.text.trim() ?? '';
      final precio = producto['precioController']?.text.trim() ?? '';

      if (desc.isEmpty) {
        _mostrarError('El Producto ${i + 1} no tiene descripción');
        return;
      }

      if (precio.isEmpty) {
        _mostrarError('El Producto ${i + 1} no tiene precio');
        return;
      }

      // Validar que el precio sea un número válido
      if (double.tryParse(precio) == null) {
        _mostrarError('El precio del Producto ${i + 1} no es válido');
        return;
      }
    }

    // Validar que hay al menos un día seleccionado
    bool hayDiaSeleccionado = dias.values.any((dia) => dia);
    if (!hayDiaSeleccionado) {
      _mostrarError('Selecciona al menos un día disponible');
      return;
    }

    print('=== TODAS LAS VALIDACIONES PASARON ===');
    setState(() => _isLoading = true);

    try {
      // Obtener ID del usuario de la sesión
      final userId = await SessionService.getUserId();
      if (userId == null) {
        _mostrarError('Sesión expirada. Por favor, inicia sesión nuevamente');
        setState(() => _isLoading = false);
        Navigator.of(context).pushReplacementNamed('/login');
        return;
      }

      // Preparar datos de horarios
      List<Map<String, dynamic>> horarios = [];
      dias.forEach((dia, seleccionado) {
        if (seleccionado) {
          horarios.add({
            'dia_semana': dia,
            'hora_inicial': horaInicio[dia]?.text ?? '9:00',
            'hora_final': horaFin[dia]?.text ?? '9:00',
            'ubicacion':
                ubicacionPorDiaController[dia]?.text.trim() ??
                ubicacionGeneralController.text,
          });
        }
      });

      // Preparar datos completos
      Map<String, dynamic> datos = {
        'nombre_emprendimiento': tituloController.text.trim(),
        'descripcion_emp': descripcionEmpController.text.trim(),
        'ubicacion_general': ubicacionGeneralController.text.trim(),
        'contacto': telefonoController.text.trim(),
        'instagram': instagramController.text.trim(),
        'productos': await Future.wait(
          productos.map((p) async {
            final imagenUrl = p['imagen'] as XFile?;
            String? imagenBase64;

            if (imagenUrl != null) {
              try {
                final bytes = await imagenUrl.readAsBytes();
                imagenBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
              } catch (e) {
                print('Error al codificar imagen: $e');
              }
            }

            // Usar los valores de los controladores que son los más actualizados
            final descripcion =
                p['descripcionController']?.text.trim() ??
                p['descripcion'] ??
                '';
            final precio =
                p['precioController']?.text.trim() ?? p['precio'] ?? '';

            print(
              'Producto a enviar: descripcion="$descripcion", precio="$precio"',
            );

            return {
              'descripcion': descripcion,
              'precio': double.tryParse(precio) ?? 0,
              'imagen_url': imagenBase64,
            };
          }),
        ),
        'horarios': horarios,
        'id_usuario': userId,
      };

      // Procesar imagen del emprendimiento si existe
      if (imagenEmprendimiento != null) {
        try {
          final bytes = await imagenEmprendimiento!.readAsBytes();
          datos['imagen_emprendimiento'] = base64Encode(bytes);
          print('Imagen del emprendimiento codificada');
        } catch (e) {
          print('Error al codificar imagen del emprendimiento: $e');
        }
      }

      print('Datos a enviar: ${datos.keys}');
      print('Total productos a enviar: ${(datos['productos'] as List).length}');

      // Enviar al servidor
      final response = await ApiService.agregarEmprendimiento(datos);

      print('Respuesta del servidor: $response');

      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Emprendimiento creado exitosamente!'),
            ),
          );
          // Limpiar campos y volver
          _limpiarFormulario();
          Navigator.pop(context, true);
        }
      } else {
        _mostrarError(
          response['message'] ?? 'Error al guardar el emprendimiento',
        );
      }
    } catch (e) {
      _mostrarError('Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _limpiarFormulario() {
    tituloController.clear();
    descripcionEmpController.clear();
    ubicacionGeneralController.clear();
    telefonoController.clear();
    instagramController.clear();
    productos.clear();
    descripcionActual.clear();
    precioActual.clear();
    imagenActual = null;
    for (var dia in dias.keys) {
      dias[dia] = false;
      ubicacionPorDiaController[dia]?.clear();
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: const Color.fromARGB(255, 54, 98, 244),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF1A3B5D);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Agregar Emprendimiento',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header decorativo
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
              child: Column(
                children: [
                  Icon(
                    Icons.store_rounded,
                    size: 50,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Completa la información",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Información General Card
                  _buildSectionCard(
                    title: "Información General",
                    icon: Icons.info_outline_rounded,
                    children: [
                      _buildModernTextField(
                        controller: tituloController,
                        label: "Nombre del emprendimiento",
                        icon: Icons.business_rounded,
                      ),
                      const SizedBox(height: 16),
                      _buildModernTextField(
                        controller: descripcionEmpController,
                        label: "Descripción",
                        icon: Icons.description_outlined,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      _buildModernTextField(
                        controller: ubicacionGeneralController,
                        label: "Ubicación general",
                        icon: Icons.location_on_outlined,
                      ),
                      const SizedBox(height: 16),
                      // Imagen del emprendimiento
                      GestureDetector(
                        onTap: () async {
                          final imagen = await _picker.pickImage(
                            source: ImageSource.gallery,
                            maxWidth: 1200,
                            maxHeight: 1200,
                            imageQuality: 85,
                          );
                          if (imagen != null) {
                            setState(() {
                              imagenEmprendimiento = imagen;
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
                          child: imagenEmprendimiento != null
                              ? Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        File(imagenEmprendimiento!.path),
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
                                            imagenEmprendimiento = null;
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
                                        'Toca para agregar imagen del emprendimiento',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Contacto Card
                  _buildSectionCard(
                    title: "Información de Contacto",
                    icon: Icons.contact_phone_rounded,
                    children: [
                      _buildModernTextField(
                        controller: telefonoController,
                        label: "Número de WhatsApp",
                        icon: Icons.phone_rounded,
                        keyboardType: TextInputType.phone,
                        iconColor: const Color(0xFF25D366),
                      ),
                      const SizedBox(height: 16),
                      _buildModernTextField(
                        controller: instagramController,
                        label: "Link de Instagram",
                        icon: Icons.camera_alt_rounded,
                        iconColor: const Color(0xFFE1306C),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Productos Card
                  _buildSectionCard(
                    title: "Productos",
                    icon: Icons.shopping_bag_rounded,
                    children: [
                      if (productos.isNotEmpty) ...[
                        ...productos.asMap().entries.map((entry) {
                          final index = entry.key;
                          final prod = entry.value;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.blue.shade200,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                if (prod['imagen'] != null)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      File(prod['imagen'].path),
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                else
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.image_outlined,
                                      color: Colors.grey,
                                    ),
                                  ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        prod['descripcion'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        'S/ ${prod['precio']}',
                                        style: const TextStyle(
                                          color: primaryColor,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      productos.removeAt(index);
                                    });
                                  },
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 16),
                      ],

                      // Agregar nuevo producto
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Nuevo Producto",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Botón de imagen
                            GestureDetector(
                              onTap: _seleccionarImagen,
                              child: Container(
                                height: 120,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey[300]!,
                                    width: 2,
                                    style: BorderStyle.solid,
                                  ),
                                ),
                                child: imagenActual != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.file(
                                          File(imagenActual!.path),
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                        ),
                                      )
                                    : Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.add_photo_alternate_rounded,
                                            size: 40,
                                            color: Colors.grey[400],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            "Toca para agregar imagen",
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            _buildModernTextField(
                              controller: descripcionActual,
                              label: "Descripción del producto",
                              icon: Icons.label_outline,
                            ),

                            const SizedBox(height: 12),

                            _buildModernTextField(
                              controller: precioActual,
                              label: "Precio (S/)",
                              icon: Icons.attach_money_rounded,
                              keyboardType: TextInputType.number,
                            ),

                            const SizedBox(height: 16),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _agregarProducto,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.add_circle_outline_rounded,
                                ),
                                label: const Text(
                                  "Agregar Producto",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Horarios Card
                  _buildSectionCard(
                    title: "Horarios de Atención",
                    icon: Icons.schedule_rounded,
                    children: [
                      Text(
                        "Selecciona los días que atiendes:",
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 12),

                      ...dias.keys.map((dia) {
                        return Column(
                          children: [
                            Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: dias[dia]!
                                    ? primaryColor.withOpacity(0.05)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: dias[dia]!
                                      ? primaryColor.withOpacity(0.3)
                                      : Colors.grey[300]!,
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Checkbox(
                                        value: dias[dia],
                                        onChanged: (value) {
                                          setState(() {
                                            dias[dia] = value!;
                                          });
                                        },
                                        activeColor: primaryColor,
                                      ),
                                      Text(
                                        dia,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: dias[dia]!
                                              ? primaryColor
                                              : Colors.black87,
                                        ),
                                      ),
                                      const Spacer(),

                                      // Hora inicio
                                      GestureDetector(
                                        onTap: () => _seleccionarHora(
                                          context,
                                          dia,
                                          true,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: Colors.grey[300]!,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.access_time,
                                                size: 16,
                                                color: primaryColor,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                horaInicio[dia]?.text ?? "9:00",
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        child: Text(
                                          "a",
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),

                                      // Hora fin
                                      GestureDetector(
                                        onTap: () => _seleccionarHora(
                                          context,
                                          dia,
                                          false,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: Colors.grey[300]!,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.access_time,
                                                size: 16,
                                                color: primaryColor,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                horaFin[dia]?.text ?? "9:00",
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  if (dias[dia]!) ...[
                                    const SizedBox(height: 8),
                                    _buildModernTextField(
                                      controller:
                                          ubicacionPorDiaController[dia]!,
                                      label: "Ubicación específica (opcional)",
                                      icon: Icons.place_outlined,
                                      compact: true,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Botón Guardar
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _guardarEmprendimiento,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              "Guardar Emprendimiento",
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    const primaryColor = Color(0xFF1A3B5D);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: primaryColor, size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    Color? iconColor,
    bool compact = false,
  }) {
    const primaryColor = Color(0xFF1A3B5D);

    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontSize: compact ? 13 : 14,
          color: Colors.grey[600],
        ),
        prefixIcon: Icon(
          icon,
          color: iconColor ?? primaryColor,
          size: compact ? 20 : 22,
        ),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: compact ? 12 : 16,
        ),
      ),
    );
  }
}
