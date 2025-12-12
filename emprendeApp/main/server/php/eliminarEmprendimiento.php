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

$id_emprendimiento = $input['id_emprendimiento'] ?? null;
$id_usuario = $input['id_usuario'] ?? null;

if (!$id_emprendimiento || !$id_usuario) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Datos requeridos incompletos']);
    exit;
}

try {
    // Verificar que el usuario sea el propietario del emprendimiento
    $stmt = $pdo->prepare("SELECT id_usuario FROM emprendimientos WHERE id_emprendimiento = ?");
    $stmt->execute([$id_emprendimiento]);
    $emp = $stmt->fetch();

    if (!$emp || $emp['id_usuario'] != $id_usuario) {
        http_response_code(403);
        echo json_encode(['success' => false, 'message' => 'No tienes permiso para eliminar este emprendimiento']);
        exit;
    }

    // Eliminar de forma ordenada para evitar conflictos de FK
    $pdo->beginTransaction();

    // Desactivar FKs temporalmente para asegurar borrado limpio
    $pdo->exec('SET FOREIGN_KEY_CHECKS=0');

    // 1) Desvincular productos de archivos (evita FK producto -> archivos)
    $stmtNullArch = $pdo->prepare("UPDATE producto SET id_archivo = NULL WHERE id_emprendimiento = ?");
    $stmtNullArch->execute([$id_emprendimiento]);

    // 2) Eliminar productos (esto además cascada eliminará archivos con id_producto si la FK está activa)
    $stmtProd = $pdo->prepare("DELETE FROM producto WHERE id_emprendimiento = ?");
    $stmtProd->execute([$id_emprendimiento]);

    // 3) Eliminar archivos que queden asociados al emprendimiento (ej. imagen del emprendimiento o archivos sin id_producto)
    $stmtArchivos = $pdo->prepare("DELETE FROM archivos WHERE id_emprendimiento = ?");
    $stmtArchivos->execute([$id_emprendimiento]);

    // 4) Horarios
    $stmtHor = $pdo->prepare("DELETE FROM horarios WHERE id_emprendimiento = ?");
    $stmtHor->execute([$id_emprendimiento]);

    // 5) Emprendimiento
    $stmtDelete = $pdo->prepare("DELETE FROM emprendimientos WHERE id_emprendimiento = ? AND id_usuario = ?");
    $stmtDelete->execute([$id_emprendimiento, $id_usuario]);

    // Reactivar FKs
    $pdo->exec('SET FOREIGN_KEY_CHECKS=1');

    $pdo->commit();

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Emprendimiento eliminado exitosamente'
    ]);

} catch (PDOException $e) {
    if ($pdo->inTransaction()) {
        $pdo->exec('SET FOREIGN_KEY_CHECKS=1');
        $pdo->rollBack();
    }
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error al eliminar emprendimiento',
        'detail' => $e->getMessage()
    ]);
} catch (Exception $e) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error interno',
        'detail' => $e->getMessage()
    ]);
}

?>
