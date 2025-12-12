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

try {
    // Obtener todos los emprendimientos activos con sus datos relacionados
    // Optimizado: sin cargar imágenes completas en el listado
    $stmt = $pdo->prepare("
        SELECT 
            e.id_emprendimiento,
            e.nombre_emprendimiento,
            e.descripcion_emp,
            e.contacto,
            e.estado,
            u.nombre_usuario,
            u.email,
            CASE WHEN a.imagen IS NOT NULL THEN 1 ELSE 0 END as tiene_imagen
        FROM emprendimientos e
        INNER JOIN usuarios u ON e.id_usuario = u.id_usuario
        LEFT JOIN archivos a ON e.id_emprendimiento = a.id_emprendimiento
        WHERE e.estado = 1
        GROUP BY e.id_emprendimiento
        ORDER BY e.id_emprendimiento DESC
    ");
    
    $stmt->execute();
    $emprendimientos = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Procesar datos para retornar en formato más útil
    $resultado = [];
    foreach ($emprendimientos as $emp) {
        // Obtener productos de este emprendimiento
        $stmtProd = $pdo->prepare("
            SELECT id_producto, descripcion_producto, precio 
            FROM producto 
            WHERE id_emprendimiento = ?
        ");
        $stmtProd->execute([$emp['id_emprendimiento']]);
        $productos = [];
        while ($prod = $stmtProd->fetch(PDO::FETCH_ASSOC)) {
            $productos[] = [
                'id_producto' => (int)$prod['id_producto'],
                'descripcion' => $prod['descripcion_producto'],
                'precio' => (float)$prod['precio']
            ];
        }
        
        // NO enviar imagen en el listado para mejor performance
        // Solo indicar si tiene imagen
        $tieneImagen = 0;
        $stmtImagen = $pdo->prepare("
            SELECT COUNT(*) as tiene
            FROM producto p
            INNER JOIN archivos a ON p.id_archivo = a.id_archivo
            WHERE p.id_emprendimiento = ?
            LIMIT 1
        ");
        $stmtImagen->execute([$emp['id_emprendimiento']]);
        $archivoRow = $stmtImagen->fetch(PDO::FETCH_ASSOC);
        
        if ($archivoRow) {
            $tieneImagen = (int)$archivoRow['tiene'];
        }

        $resultado[] = [
            'id_emprendimiento' => (int)$emp['id_emprendimiento'],
            'nombre_emprendimiento' => $emp['nombre_emprendimiento'],
            'descripcion_emp' => $emp['descripcion_emp'],
            'contacto' => $emp['contacto'],
            'nombre_usuario' => $emp['nombre_usuario'],
            'email' => $emp['email'],
            'imagen_url' => null, // No enviar imagen en listado
            'tiene_imagen' => $tieneImagen,
            'productos' => $productos,
            'estado' => (int)$emp['estado']
        ];
    }

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'emprendimientos' => $resultado
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
