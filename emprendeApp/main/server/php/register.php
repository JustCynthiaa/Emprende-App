<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once __DIR__ . '/config.php';

$input = json_decode(file_get_contents('php://input'), true);
$nombre_usuario = $input['nombre_usuario'] ?? null;
$email = $input['email'] ?? null;
$password = $input['contraseña'] ?? null;

if (!$nombre_usuario || !$email || !$password) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Todos los campos son requeridos']);
    exit;
}

// Validar formato de email
if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Email inválido']);
    exit;
}

try {
    // Verificar si el email ya existe
    $stmt = $pdo->prepare('SELECT id_usuario FROM usuarios WHERE email = ? LIMIT 1');
    $stmt->execute([$email]);
    $existingUser = $stmt->fetch();

    if ($existingUser) {
        http_response_code(409);
        echo json_encode(['success' => false, 'message' => 'El email ya está registrado']);
        exit;
    }

    // Insertar nuevo usuario con contraseña hasheada
    $hashedPassword = password_hash($password, PASSWORD_DEFAULT);
    $stmt = $pdo->prepare('INSERT INTO usuarios (nombre_usuario, email, contraseña) VALUES (?, ?, ?)');
    $stmt->execute([$nombre_usuario, $email, $hashedPassword]);

    $userId = $pdo->lastInsertId();

    // Registro exitoso
    echo json_encode([
        'success' => true,
        'message' => 'Usuario registrado exitosamente',
        'user' => [
            'id' => (int)$userId,
            'nombre_usuario' => $nombre_usuario,
            'email' => $email,
        ]
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Error al registrar usuario', 'detail' => $e->getMessage()]);
}

?>
