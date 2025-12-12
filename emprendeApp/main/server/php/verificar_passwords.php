<?php
require_once __DIR__ . '/config.php';

echo "=== VERIFICANDO CONTRASEÑAS EN LA BD ===\n\n";

$stmt = $pdo->query('SELECT id_usuario, email, contraseña, LENGTH(contraseña) as pwd_length FROM usuarios');
while($row = $stmt->fetch()) {
    echo "Usuario: " . $row['email'] . "\n";
    echo "Longitud: " . $row['pwd_length'] . "\n";
    echo "Preview: " . substr($row['contraseña'], 0, 30) . "...\n";
    echo "Es hash: " . (strpos($row['contraseña'], '$2y$') === 0 ? 'SÍ' : 'NO') . "\n\n";
}
?>
