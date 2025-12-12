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

$id_usuario = $_GET['id_usuario'] ?? null;

if (!$id_usuario) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'ID de usuario requerido']);
    exit;
}

try {
    // Obtener emprendimientos del usuario
    $stmt = $pdo->prepare("
        SELECT 
            e.id_emprendimiento,
            e.nombre_emprendimiento,
            e.descripcion_emp,
            e.contacto,
            e.estado,
            a.imagen,
            COUNT(p.id_producto) as total_productos
        FROM emprendimientos e
        LEFT JOIN archivos a ON e.id_emprendimiento = a.id_emprendimiento
        LEFT JOIN producto p ON e.id_emprendimiento = p.id_emprendimiento
        WHERE e.id_usuario = ?
        GROUP BY e.id_emprendimiento
        ORDER BY e.id_emprendimiento DESC
    ");
    
    $stmt->execute([$id_usuario]);
    $emprendimientos = $stmt->fetchAll(PDO::FETCH_ASSOC);

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'emprendimientos' => array_map(function($e) {
            // Convertir imagen BLOB a base64
            $imagenUrl = null;
            if (!empty($e['imagen'])) {
                $imagenUrl = 'data:image/jpeg;base64,' . base64_encode($e['imagen']);
            }
            
            return [
                'id_emprendimiento' => (int)$e['id_emprendimiento'],
                'nombre_emprendimiento' => $e['nombre_emprendimiento'],
                'descripcion_emp' => $e['descripcion_emp'],
                'contacto' => $e['contacto'],
                'estado' => (int)$e['estado'],
                'imagen_url' => $imagenUrl,
                'total_productos' => (int)$e['total_productos'],
            ];
        }, $emprendimientos)
    ]);

} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al obtener emprendimientos',
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
