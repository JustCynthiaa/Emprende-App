<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once 'config.php';

// Logging para debug
error_log('=== AGREGAR EMPRENDIMIENTO ===');

// Obtener datos JSON del request
$input = json_decode(file_get_contents('php://input'), true);

error_log('Input recibido: ' . print_r($input, true));

if (!$input) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Datos inválidos']);
    exit;
}

try {
    // Validaciones básicas
    $nombre = $input['nombre_emprendimiento'] ?? null;
    $descripcion = $input['descripcion_emp'] ?? null;
    $ubicacion = $input['ubicacion_general'] ?? null;
    $contacto = $input['contacto'] ?? null;
    $instagram = $input['instagram'] ?? null;
    $id_usuario = $input['id_usuario'] ?? null;
    $productos = $input['productos'] ?? [];
    $horarios = $input['horarios'] ?? [];

    if (!$nombre || !$descripcion || !$ubicacion || !$id_usuario) {
        http_response_code(400);
        $error_msg = "Faltan datos: nombre=$nombre, desc=$descripcion, ubic=$ubicacion, user=$id_usuario";
        error_log($error_msg);
        echo json_encode(['success' => false, 'message' => 'Faltan datos requeridos', 'detail' => $error_msg]);
        exit;
    }

    error_log("Productos recibidos: " . count($productos));
    error_log("Horarios recibidos: " . count($horarios));

    // Iniciar transacción
    $pdo->beginTransaction();
    
    error_log('Iniciando transacción...');

    // Procesar imagen del emprendimiento si viene
    $imagenEmprendimientoBinary = null;
    $imagenEmprendimiento = $input['imagen_emprendimiento'] ?? null;
    if ($imagenEmprendimiento && !empty($imagenEmprendimiento)) {
        try {
            $imagenEmprendimientoBinary = base64_decode($imagenEmprendimiento, true);
            if ($imagenEmprendimientoBinary === false) {
                $imagenEmprendimientoBinary = null;
            }
            error_log("Imagen del emprendimiento procesada");
        } catch (Exception $e) {
            error_log("Error al procesar imagen del emprendimiento: " . $e->getMessage());
        }
    }

    // Insertar emprendimiento con imagen
    $stmt = $pdo->prepare("
        INSERT INTO emprendimientos (id_usuario, nombre_emprendimiento, descripcion_emp, contacto, estado, imagen_emprendimiento)
        VALUES (:id_usuario, :nombre, :descripcion, :contacto, 1, :imagen)
    ");
    
    $stmt->execute([
        ':id_usuario' => $id_usuario,
        ':nombre' => $nombre,
        ':descripcion' => $descripcion,
        ':contacto' => $contacto ?: null,
        ':imagen' => $imagenEmprendimientoBinary,
    ]);

    $id_emprendimiento = $pdo->lastInsertId();
    error_log("Emprendimiento insertado con ID: $id_emprendimiento");

    // Insertar productos con imágenes
    foreach ($productos as $producto) {
        $idArchivo = null;
        
        // Procesar imagen PRIMERO si viene
        $imagenUrl = $producto['imagen_url'] ?? null;
        if ($imagenUrl && strpos($imagenUrl, 'data:image') === 0) {
            try {
                $imagenData = substr($imagenUrl, strpos($imagenUrl, ',') + 1);
                $imagenBinary = base64_decode($imagenData, true);
                
                if ($imagenBinary !== false && !empty($imagenBinary)) {
                    // Insertar archivo PRIMERO
                    $stmtArchivo = $pdo->prepare("
                        INSERT INTO archivos (id_emprendimiento, imagen)
                        VALUES (?, ?)
                    ");
                    $stmtArchivo->execute([$id_emprendimiento, $imagenBinary]);
                    
                    // Obtener ID del archivo
                    $idArchivo = $pdo->lastInsertId();
                    error_log("Archivo insertado con ID: $idArchivo");
                }
            } catch (Exception $e) {
                error_log('Error al procesar imagen de producto: ' . $e->getMessage());
            }
        }
        
        // Ahora insertar producto con id_archivo
        $stmtProducto = $pdo->prepare("
            INSERT INTO producto (id_emprendimiento, descripcion_producto, precio, id_archivo)
            VALUES (:id_emp, :descripcion, :precio, :id_archivo)
        ");
        
        $stmtProducto->execute([
            ':id_emp' => $id_emprendimiento,
            ':descripcion' => $producto['descripcion'] ?? '',
            ':precio' => (float)($producto['precio'] ?? 0),
            ':id_archivo' => $idArchivo, // Puede ser NULL si no hay imagen
        ]);
        
        $idProducto = $pdo->lastInsertId();
        error_log("Producto insertado con ID: $idProducto, id_archivo: " . ($idArchivo ?? 'NULL'));
    }

    // Insertar horarios
    $stmtHorario = $pdo->prepare("
        INSERT INTO horarios (id_emprendimiento, dia_semana, hora_inicial, hora_final, ubicacion)
        VALUES (:id_emp, :dia, :hora_inicial, :hora_final, :ubicacion)
    ");

    foreach ($horarios as $horario) {
        $stmtHorario->execute([
            ':id_emp' => $id_emprendimiento,
            ':dia' => $horario['dia_semana'] ?? '',
            ':hora_inicial' => $horario['hora_inicial'] ?? '09:00:00',
            ':hora_final' => $horario['hora_final'] ?? '17:00:00',
            ':ubicacion' => $horario['ubicacion'] ?? $ubicacion,
        ]);
    }

    // Confirmar transacción
    $pdo->commit();

    http_response_code(201);
    echo json_encode([
        'success' => true,
        'message' => 'Emprendimiento creado exitosamente',
        'id_emprendimiento' => $id_emprendimiento
    ]);

} catch (PDOException $e) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }
    error_log('Error PDO: ' . $e->getMessage());
    error_log('Stack trace: ' . $e->getTraceAsString());
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al guardar los datos',
        'detail' => $e->getMessage(),
        'trace' => $e->getTraceAsString()
    ]);
} catch (Exception $e) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }
    error_log('Error general: ' . $e->getMessage());
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error inesperado',
        'detail' => $e->getMessage()
    ]);
}
?>
