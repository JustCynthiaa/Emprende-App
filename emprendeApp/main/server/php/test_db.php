<?php
header('Content-Type: application/json');

try {
    require_once 'config.php';
    
    // Test simple insert
    $stmt = $pdo->prepare("SELECT DATABASE() as db_name");
    $stmt->execute();
    $result = $stmt->fetch();
    
    echo json_encode([
        'success' => true,
        'database' => $result['db_name'],
        'message' => 'Conexión exitosa'
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error: ' . $e->getMessage()
    ]);
}
?>
