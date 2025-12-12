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
$email = $input['email'] ?? null;
$password = $input['password'] ?? null;

// Log para debug
error_log("Login attempt - Email: " . ($email ?? 'null') . ", Password length: " . strlen($password ?? ''));

if (!$email || !$password) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Email y password requeridos']);
    exit;
}

try {
    $stmt = $pdo->prepare('SELECT id_usuario, email, contraseña, nombre_usuario FROM usuarios WHERE email = ? LIMIT 1');
    $stmt->execute([$email]);
    $user = $stmt->fetch();

    if (!$user) {
        error_log("User not found: " . $email);
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Usuario no encontrado', 'debug_email' => $email]);
        exit;
    }

    $stored = $user['contraseña'];
    error_log("Password comparison - Stored hash length: " . strlen($stored) . ", Received: '" . $password . "'");

    // Verificar si la contraseña está hasheada o es texto plano
    $isHashed = (strpos($stored, '$2y$') === 0);
    
    if ($isHashed) {
        // Contraseña hasheada - usar password_verify
        if (!password_verify($password, $stored)) {
            error_log("Password verification failed for user: " . $email);
            http_response_code(401);
            echo json_encode([
                'success' => false, 
                'message' => 'Contraseña incorrecta'
            ]);
            exit;
        }
    } else {
        // Contraseña en texto plano - comparación directa (legacy)
        if ($stored !== $password) {
            error_log("Plain password comparison failed for user: " . $email);
            http_response_code(401);
            echo json_encode([
                'success' => false, 
                'message' => 'Contraseña incorrecta'
            ]);
            exit;
        }
        // Actualizar a hash automáticamente
        error_log("Upgrading plain text password to hash for user: " . $email);
        $hashedPassword = password_hash($password, PASSWORD_DEFAULT);
        $updateStmt = $pdo->prepare('UPDATE usuarios SET contraseña = ? WHERE id_usuario = ?');
        $updateStmt->execute([$hashedPassword, $user['id_usuario']]);
    }

    // Login exitoso
    echo json_encode([
        'success' => true,
        'user' => [
            'id' => (int)$user['id_usuario'],
            'email' => $user['email'],
            'name' => $user['nombre_usuario'] ?? null,
        ]
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Error interno', 'detail' => $e->getMessage()]);
}

?>
