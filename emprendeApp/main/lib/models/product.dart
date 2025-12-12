import 'dart:typed_data';

class Product {
  final int id;
  final String title;
  final double price;
  final String uploaderName;
  final Uint8List? imageBytes; // Imagen almacenada como BLOB
  final String? nombreEmprendimiento; // Nombre del emprendimiento
  final Uint8List? imagenEmprendimiento; // Imagen del emprendimiento

  const Product({
    required this.id,
    required this.title,
    required this.price,
    required this.uploaderName,
    this.imageBytes,
    this.nombreEmprendimiento,
    this.imagenEmprendimiento,
  });

  // Ejemplo de factory para cargar desde una fila de SQLite (BLOB -> Uint8List)
  factory Product.fromMap(Map<String, dynamic> m) {
    return Product(
      id: m['id'] as int,
      title: m['title'] as String? ?? '',
      price: (m['price'] as num?)?.toDouble() ?? 0.0,
      uploaderName: m['uploader_name'] as String? ?? 'Desconocido',
      imageBytes: m['image'] as Uint8List?,
      nombreEmprendimiento: m['nombre_emprendimiento'] as String?,
      imagenEmprendimiento: m['imagen_emprendimiento'] as Uint8List?,
    );
  }
}
