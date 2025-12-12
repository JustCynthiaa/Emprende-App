<?php
header('Content-Type: application/json; charset=utf-8');

try {
    $pdo = new PDO('mysql:host=localhost;dbname=emprendeapp;charset=utf8', 'root', '');
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Obtener emprendimientos con productos y archivos
    $stmt = $pdo->query("
        SELECT 
            e.id_emprendimiento, 
            e.nombre_emprendimiento,
            p.id_producto,
            p.descripcion_producto,
            p.id_archivo,
            CASE WHEN a.imagen IS NOT NULL THEN 'SI' ELSE 'NO' END as tiene_imagen,
            LENGTH(a.imagen) as tamano_imagen
        FROM emprendimientos e
        LEFT JOIN producto p ON e.id_emprendimiento = p.id_emprendimiento
        LEFT JOIN archivos a ON p.id_archivo = a.id_archivo
        WHERE e.estado = 1
        ORDER BY e.id_emprendimiento DESC
        LIMIT 10
    ");
    
    $results = $stmt->fetchAll(PDO::FETCH_ASSOC);
    echo json_encode($results, JSON_PRETTY_PRINT);
    
} catch(Exception $e) {
    echo json_encode(['error' => $e->getMessage()]);
}
