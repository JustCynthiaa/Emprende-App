<?php
require_once __DIR__ . '/config.php';

echo "=== AMPLIANDO CAMPO DE CONTRASEÑA ===\n\n";

try {
    // Modificar el campo contraseña para que soporte 255 caracteres
    $pdo->exec('ALTER TABLE usuarios MODIFY COLUMN contraseña VARCHAR(255) NOT NULL');
    echo "✓ Campo 'contraseña' ampliado a VARCHAR(255)\n\n";
    
    // Volver a ejecutar el proceso de hasheo
    echo "=== REHASH DE CONTRASEÑAS ===\n";
    echo "IMPORTANTE: Necesitas saber las contraseñas originales.\n\n";
    
    // Resetear las contraseñas a texto plano para volver a hashearlas
    echo "Ingresa las contraseñas originales:\n";
    $usuarios = [
        ['email' => 'cynthiamt1304', 'password' => 'coco'],
        ['email' => 'earv@gmail.com', 'password' => '123456'],
        ['email' => 'coco@gmail.com', 'password' => 'coco']
    ];
    
    foreach ($usuarios as $user) {
        $hashedPassword = password_hash($user['password'], PASSWORD_DEFAULT);
        $stmt = $pdo->prepare('UPDATE usuarios SET contraseña = ? WHERE email = ?');
        $stmt->execute([$hashedPassword, $user['email']]);
        echo "✓ Usuario {$user['email']} - Contraseña actualizada (longitud: " . strlen($hashedPassword) . ")\n";
    }
    
    echo "\n✓ Proceso completado\n";
    
} catch (Exception $e) {
    echo "✗ ERROR: " . $e->getMessage() . "\n";
}
?>
