import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/product.dart';
import '../widgets/promoted_product_card.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Product> _emprendimientos = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  Future<void> _cargarProductos() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    
    try {
      print('Iniciando carga de productos...');
      final data = await ApiService.listarProductos();
      print('Respuesta recibida: ${data.length} productos');
      
      final productos = <Product>[];

      for (final prod in data) {
        try {
          final prodMap = prod as Map<String, dynamic>;
          final idEmprendimiento = prodMap['id_emprendimiento'] as int?;
          final descripcion = prodMap['descripcion_producto'] as String? ?? 'Sin descripción';
          final precio = (prodMap['precio'] as num?)?.toDouble() ?? 0.0;
          final nombreUsuario = prodMap['nombre_usuario'] as String? ?? 'Emprendedor';
          final nombreEmprendimiento = prodMap['nombre_emprendimiento'] as String?;
          final imagenUrl = prodMap['imagen_url'] as String?;
          final imagenEmprendimientoUrl = prodMap['imagen_emprendimiento_url'] as String?;

          // Decodificar imagen del producto si existe
          Uint8List? imageBytes;
          if (imagenUrl != null && imagenUrl.startsWith('data:image')) {
            try {
              final base64Str = imagenUrl.split(',').last;
              imageBytes = base64Decode(base64Str);
            } catch (e) {
              print('Error decodificando imagen: $e');
              imageBytes = null;
            }
          }

          // Decodificar imagen del emprendimiento si existe
          Uint8List? imagenEmprendimientoBytes;
          if (imagenEmprendimientoUrl != null && imagenEmprendimientoUrl.startsWith('data:image')) {
            try {
              final base64Str = imagenEmprendimientoUrl.split(',').last;
              imagenEmprendimientoBytes = base64Decode(base64Str);
            } catch (e) {
              print('Error decodificando imagen emprendimiento: $e');
              imagenEmprendimientoBytes = null;
            }
          }

          if (idEmprendimiento != null) {
            productos.add(
              Product(
                id: idEmprendimiento,
                title: descripcion,
                price: precio,
                uploaderName: nombreUsuario,
                imageBytes: imageBytes,
                nombreEmprendimiento: nombreEmprendimiento,
                imagenEmprendimiento: imagenEmprendimientoBytes,
              ),
            );
          }
        } catch (e) {
          print('Error procesando producto: $e');
        }
      }

      setState(() {
        _emprendimientos = productos;
        _loading = false;
        _error = null;
      });
      
      print('Carga completada: ${productos.length} productos');
    } catch (e) {
      print('Error en _cargarProductos: $e');
      setState(() {
        _loading = false;
        _error = 'Error al cargar productos: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF1A3B5D);
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'EmprendeApp',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 8,
            offset: const Offset(0, 50),
            color: Colors.white,
            onSelected: (value) async {
              if (value == 'productos') {
                final result = await Navigator.of(context).pushNamed('/mis_emprendimientos');
                if (mounted && result == true) {
                  _cargarProductos();
                }
              } else if (value == 'agregar') {
                final result = await Navigator.of(context).pushNamed('/agregar_emprendimiento');
                if (mounted && result == true) {
                  _cargarProductos();
                }
              } else if (value == 'cerrar_sesion') {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'productos',
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.storefront_rounded,
                        color: primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Mis emprendimientos',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'agregar',
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.add_business_rounded,
                        color: primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Agregar emprendimiento',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(height: 16),
              PopupMenuItem(
                value: 'cerrar_sesion',
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.logout_rounded,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Cerrar sesión',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _cargarProductos,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _emprendimientos.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.store_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay emprendimientos disponibles',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _cargarProductos,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        itemCount: _emprendimientos.length,
                        itemBuilder: (context, index) {
                          return PromotedProductCard(
                            product: _emprendimientos[index],
                            onTap: () async {
                              await Navigator.of(context).pushNamed(
                                '/detalle_emprendimiento',
                                arguments: _emprendimientos[index].id,
                              );
                              // Recargar productos al regresar
                              if (mounted) {
                                _cargarProductos();
                              }
                            },
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.pushNamed(context, '/agregar_emprendimiento');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
