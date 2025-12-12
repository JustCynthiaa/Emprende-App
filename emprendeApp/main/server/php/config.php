<?php
// Configuración de conexión a la base de datos MySQL
$host = 'localhost';
$dbname = 'emprendeapp';
$username = 'root';
$password = ''; // Por defecto XAMPP no tiene contraseña para root

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Error de conexión a la base de datos', 'detail' => $e->getMessage()]);
    exit;
}
?>
