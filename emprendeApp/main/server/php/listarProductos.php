<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once 'config.php';

try {
    // Consulta para obtener todos los productos con su información relacionada
    $sql = "
        SELECT 
            p.id_producto,
            p.descripcion_producto,
            p.precio,
            p.id_emprendimiento,
            e.nombre_emprendimiento,
            e.imagen_emprendimiento,
            u.nombre_usuario,
            u.id_usuario,
            a.imagen
        FROM producto p
        INNER JOIN emprendimientos e ON p.id_emprendimiento = e.id_emprendimiento
        INNER JOIN usuarios u ON e.id_usuario = u.id_usuario
        LEFT JOIN archivos a ON p.id_archivo = a.id_archivo
        ORDER BY p.id_producto DESC
    ";
    
    $stmt = $pdo->query($sql);
    $productos = [];
    
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        $producto = [
            'id_producto' => (int)$row['id_producto'],
            'descripcion_producto' => $row['descripcion_producto'],
            'precio' => (float)$row['precio'],
            'id_emprendimiento' => (int)$row['id_emprendimiento'],
            'nombre_emprendimiento' => $row['nombre_emprendimiento'],
            'nombre_usuario' => $row['nombre_usuario'],
            'id_usuario' => (int)$row['id_usuario'],
        ];
        
        // Convertir imagen BLOB a base64 si existe
        if ($row['imagen'] !== null) {
            $imageBase64 = base64_encode($row['imagen']);
            $producto['imagen_url'] = 'data:image/jpeg;base64,' . $imageBase64;
        } else {
            $producto['imagen_url'] = null;
        }
        
        // Convertir imagen del emprendimiento a base64 si existe
        if ($row['imagen_emprendimiento'] !== null) {
            $imagenEmpBase64 = base64_encode($row['imagen_emprendimiento']);
            $producto['imagen_emprendimiento_url'] = 'data:image/jpeg;base64,' . $imagenEmpBase64;
        } else {
            $producto['imagen_emprendimiento_url'] = null;
        }
        
        $productos[] = $producto;
    }
    
    echo json_encode([
        'success' => true,
        'productos' => $productos
    ], JSON_UNESCAPED_UNICODE);
    
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al listar productos: ' . $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}
?>
