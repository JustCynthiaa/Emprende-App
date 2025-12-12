<?php
header('Content-Type: application/json; charset=utf-8');

require_once 'config.php';

try {
    // Listar todos los usuarios
    $stmt = $pdo->query('SELECT id_usuario, email, contraseña, nombre_usuario FROM usuarios');
    $users = $stmt->fetchAll();
    
    echo json_encode([
        'success' => true,
        'usuarios' => $users
    ], JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    
} catch (PDOException $e) {
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
}
?>
