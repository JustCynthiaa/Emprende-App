<?php
require_once __DIR__ . '/config.php';

try {
    // Eliminar la columna id_archivo si existe
    $stmt = $pdo->query("SHOW COLUMNS FROM emprendimientos LIKE 'id_archivo'");
    if ($stmt->rowCount() > 0) {
        echo "Eliminando columna id_archivo...\n";
        
        // Primero obtener el nombre real de la FK
        $stmtFK = $pdo->query("
            SELECT CONSTRAINT_NAME 
            FROM information_schema.KEY_COLUMN_USAGE 
            WHERE TABLE_SCHEMA = 'emprendeapp' 
            AND TABLE_NAME = 'emprendimientos' 
            AND COLUMN_NAME = 'id_archivo'
            AND CONSTRAINT_NAME != 'PRIMARY'
        ");
        
        $fks = $stmtFK->fetchAll(PDO::FETCH_COLUMN);
        foreach ($fks as $fkName) {
            try {
                $pdo->exec("ALTER TABLE emprendimientos DROP FOREIGN KEY `$fkName`");
                echo "✓ Foreign key '$fkName' eliminada\n";
            } catch (PDOException $e) {
                echo "Info: Error al eliminar FK '$fkName': " . $e->getMessage() . "\n";
            }
        }
        
        // Eliminar índices relacionados
        try {
            $pdo->exec("ALTER TABLE emprendimientos DROP INDEX fk_emprendimiento_archivo");
            echo "✓ Índice eliminado\n";
        } catch (PDOException $e) {
            echo "Info: No se pudo eliminar índice: " . $e->getMessage() . "\n";
        }
        
        // Ahora eliminar la columna
        $pdo->exec("ALTER TABLE emprendimientos DROP COLUMN id_archivo");
        echo "✓ Columna id_archivo eliminada\n";
    }
    
    // Agregar columna imagen_emprendimiento directamente en emprendimientos
    $stmt = $pdo->query("SHOW COLUMNS FROM emprendimientos LIKE 'imagen_emprendimiento'");
    if ($stmt->rowCount() == 0) {
        echo "Agregando columna imagen_emprendimiento...\n";
        $pdo->exec("ALTER TABLE emprendimientos ADD COLUMN imagen_emprendimiento LONGBLOB NULL AFTER descripcion_emp");
        echo "✓ Columna imagen_emprendimiento agregada como LONGBLOB\n";
    } else {
        echo "✓ La columna imagen_emprendimiento ya existe\n";
    }
    
    echo "\n✓ Proceso completado exitosamente\n";
    
} catch (PDOException $e) {
    echo "Error: " . $e->getMessage() . "\n";
    exit(1);
}
?>
