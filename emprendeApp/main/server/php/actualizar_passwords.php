<?php
/**
 * Script para actualizar contraseñas existentes a formato hash
 * EJECUTAR SOLO UNA VEZ
 * 
 * Este script toma todas las contraseñas en texto plano de la BD
 * y las actualiza a formato hash usando password_hash()
 */

require_once __DIR__ . '/config.php';

echo "=== ACTUALIZANDO CONTRASEÑAS A FORMATO HASH ===\n\n";

try {
    // Obtener todos los usuarios
    $stmt = $pdo->query('SELECT id_usuario, email, contraseña FROM usuarios');
    $usuarios = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    $total = count($usuarios);
    $actualizados = 0;
    $yaHasheados = 0;
    
    echo "Total de usuarios encontrados: $total\n\n";
    
    foreach ($usuarios as $usuario) {
        $id = $usuario['id_usuario'];
        $email = $usuario['email'];
        $passwordActual = $usuario['contraseña'];
        
        // Verificar si ya está hasheada (las contraseñas hasheadas comienzan con $2y$)
        if (strpos($passwordActual, '$2y$') === 0) {
            echo "✓ Usuario $email - Ya tiene contraseña hasheada\n";
            $yaHasheados++;
            continue;
        }
        
        // Hashear la contraseña
        $hashedPassword = password_hash($passwordActual, PASSWORD_DEFAULT);
        
        // Actualizar en la base de datos
        $updateStmt = $pdo->prepare('UPDATE usuarios SET contraseña = ? WHERE id_usuario = ?');
        $updateStmt->execute([$hashedPassword, $id]);
        
        echo "✓ Usuario $email - Contraseña actualizada\n";
        echo "  Texto plano: '$passwordActual' -> Hash: " . substr($hashedPassword, 0, 20) . "...\n\n";
        $actualizados++;
    }
    
    echo "\n=== RESUMEN ===\n";
    echo "Total de usuarios: $total\n";
    echo "Actualizados: $actualizados\n";
    echo "Ya hasheados: $yaHasheados\n";
    echo "\n✓ Proceso completado exitosamente\n";
    
} catch (Exception $e) {
    echo "✗ ERROR: " . $e->getMessage() . "\n";
    exit(1);
}
?>
