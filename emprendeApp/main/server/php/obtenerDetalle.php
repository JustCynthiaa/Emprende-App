<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once __DIR__ . '/config.php';

$id_emprendimiento = $_GET['id'] ?? null;

if (!$id_emprendimiento) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'ID de emprendimiento requerido']);
    exit;
}

try {
    // Obtener datos del emprendimiento con su imagen
    $stmt = $pdo->prepare("
        SELECT 
            e.id_emprendimiento,
            e.id_usuario,
            e.nombre_emprendimiento,
            e.descripcion_emp,
            e.contacto,
            e.estado,
            e.imagen_emprendimiento,
            u.nombre_usuario,
            u.email
        FROM emprendimientos e
        INNER JOIN usuarios u ON e.id_usuario = u.id_usuario
        WHERE e.id_emprendimiento = ?
        LIMIT 1
    ");
    
    $stmt->execute([$id_emprendimiento]);
    $emprendimiento = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$emprendimiento) {
        http_response_code(404);
        echo json_encode(['success' => false, 'message' => 'Emprendimiento no encontrado']);
        exit;
    }

    // Obtener productos del emprendimiento con sus imágenes
    $stmtProductos = $pdo->prepare("
        SELECT p.id_producto, p.descripcion_producto, p.precio, p.id_archivo, a.imagen
        FROM producto p
        LEFT JOIN archivos a ON p.id_archivo = a.id_archivo
        WHERE p.id_emprendimiento = ?
    ");
    
    $stmtProductos->execute([$id_emprendimiento]);
    $productos = $stmtProductos->fetchAll(PDO::FETCH_ASSOC);

    // Obtener horarios del emprendimiento
    $stmtHorarios = $pdo->prepare("
        SELECT id_horario, dia_semana, hora_inicial, hora_final, ubicacion
        FROM horarios
        WHERE id_emprendimiento = ?
    ");
    
    $stmtHorarios->execute([$id_emprendimiento]);
    $horarios = $stmtHorarios->fetchAll(PDO::FETCH_ASSOC);

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'emprendimiento' => [
            'id_emprendimiento' => (int)$emprendimiento['id_emprendimiento'],
            'nombre_emprendimiento' => $emprendimiento['nombre_emprendimiento'],
            'descripcion_emp' => $emprendimiento['descripcion_emp'],
            'contacto' => $emprendimiento['contacto'],
            'estado' => (int)$emprendimiento['estado'],
            'nombre_usuario' => $emprendimiento['nombre_usuario'],
            'email' => $emprendimiento['email'],
            'id_usuario' => (int)$emprendimiento['id_usuario'],
            'imagen_emprendimiento_url' => $emprendimiento['imagen_emprendimiento'] ? 'data:image/jpeg;base64,' . base64_encode($emprendimiento['imagen_emprendimiento']) : null,
            'productos' => array_map(function($p) {
                return [
                    'id_producto' => (int)$p['id_producto'],
                    'descripcion_producto' => $p['descripcion_producto'],
                    'precio' => (float)$p['precio'],
                    'id_archivo' => $p['id_archivo'] ? (int)$p['id_archivo'] : null,
                    'imagen_url' => $p['imagen'] ? 'data:image/jpeg;base64,' . base64_encode($p['imagen']) : null
                ];
            }, $productos),
            'horarios' => array_map(function($h) {
                return [
                    'id_horario' => (int)$h['id_horario'],
                    'dia_semana' => $h['dia_semana'],
                    'hora_inicial' => $h['hora_inicial'],
                    'hora_final' => $h['hora_final'],
                    'ubicacion' => $h['ubicacion']
                ];
            }, $horarios)
        ]
    ]);

} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al obtener detalles',
        'detail' => $e->getMessage()
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error interno',
        'detail' => $e->getMessage()
    ]);
}

?>
