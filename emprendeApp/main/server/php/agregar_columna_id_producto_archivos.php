<?php
require_once __DIR__ . '/config.php';

try {
    // Verificar si la columna id_producto existe en archivos
    $stmt = $pdo->query("SHOW COLUMNS FROM archivos LIKE 'id_producto'");
    if ($stmt->rowCount() == 0) {
        echo "Agregando columna id_producto a tabla archivos...\n";
        $pdo->exec("ALTER TABLE archivos ADD COLUMN id_producto INT NULL AFTER id_emprendimiento");
        echo "✓ Columna id_producto agregada\n";
        
        // Agregar índice para mejorar performance
        echo "Agregando índice...\n";
        $pdo->exec("ALTER TABLE archivos ADD INDEX idx_producto (id_producto)");
        echo "✓ Índice agregado\n";
        
        // Agregar foreign key
        echo "Agregando foreign key...\n";
        $pdo->exec("ALTER TABLE archivos ADD CONSTRAINT fk_archivo_producto FOREIGN KEY (id_producto) REFERENCES producto(id_producto) ON DELETE CASCADE");
        echo "✓ Foreign key agregada\n";
    } else {
        echo "✓ La columna id_producto ya existe en archivos\n";
    }
    
    echo "\n✓ Proceso completado exitosamente\n";
    
} catch (PDOException $e) {
    echo "Error: " . $e->getMessage() . "\n";
    exit(1);
}
?>
