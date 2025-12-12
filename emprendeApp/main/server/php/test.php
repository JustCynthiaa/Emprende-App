<?php
header('Content-Type: application/json; charset=utf-8');

try {
    require_once __DIR__ . '/config.php';
    echo json_encode(['success' => true, 'message' => 'Conexión exitosa a la base de datos']);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Error de conexión', 'detail' => $e->getMessage()]);
}
?>
