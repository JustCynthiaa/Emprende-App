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
$nombre = $input['nombre_emprendimiento'] ?? null;
$descripcion = $input['descripcion_emp'] ?? null;
$contacto = $input['contacto'] ?? null;
$id_usuario = $input['id_usuario'] ?? null;
$estado = $input['estado'] ?? 1;

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
        echo json_encode(['success' => false, 'message' => 'No tienes permiso para editar este emprendimiento']);
        exit;
    }

    // Iniciar transacción
    $pdo->beginTransaction();

    // Procesar imagen del emprendimiento si se envió una nueva
    $imagenEmprendimientoBinary = null;
    $actualizarImagen = false;
    $imagenEmprendimiento = $input['imagen_emprendimiento'] ?? null;
    
    if ($imagenEmprendimiento && !empty($imagenEmprendimiento)) {
        try {
            $imagenEmprendimientoBinary = base64_decode($imagenEmprendimiento, true);
            if ($imagenEmprendimientoBinary !== false) {
                $actualizarImagen = true;
                error_log("Imagen del emprendimiento procesada para actualizar");
            }
        } catch (Exception $e) {
            error_log("Error al procesar imagen del emprendimiento: " . $e->getMessage());
        }
    }

    // Actualizar emprendimiento con o sin imagen
    if ($actualizarImagen) {
        $stmtUpdate = $pdo->prepare("
            UPDATE emprendimientos 
            SET nombre_emprendimiento = ?, descripcion_emp = ?, contacto = ?, estado = ?, imagen_emprendimiento = ?
            WHERE id_emprendimiento = ?
        ");
        
        $stmtUpdate->execute([
            $nombre,
            $descripcion,
            $contacto,
            $estado,
            $imagenEmprendimientoBinary,
            $id_emprendimiento
        ]);
    } else {
        $stmtUpdate = $pdo->prepare("
            UPDATE emprendimientos 
            SET nombre_emprendimiento = ?, descripcion_emp = ?, contacto = ?, estado = ?
            WHERE id_emprendimiento = ?
        ");
        
        $stmtUpdate->execute([
            $nombre,
            $descripcion,
            $contacto,
            $estado,
            $id_emprendimiento
        ]);
    }

    // Gestionar productos (insertar nuevos, actualizar existentes, eliminar)
    $productos = $input['productos'] ?? [];
    $productosParaEliminar = $input['productos_a_eliminar'] ?? [];
    
    // Eliminar productos si se pasan sus IDs
    if (!empty($productosParaEliminar)) {
        $stmtDelete = $pdo->prepare("DELETE FROM producto WHERE id_producto = ? AND id_emprendimiento = ?");
        foreach ($productosParaEliminar as $idProd) {
            $stmtDelete->execute([(int)$idProd, $id_emprendimiento]);
        }
    }
    
    // Insertar o actualizar productos
    if (!empty($productos)) {
        $stmtInsertProducto = $pdo->prepare("
            INSERT INTO producto (id_emprendimiento, descripcion_producto, precio)
            VALUES (:id_emp, :descripcion, :precio)
        ");
        
        $stmtUpdateProducto = $pdo->prepare("
            UPDATE producto 
            SET descripcion_producto = ?, precio = ?
            WHERE id_producto = ? AND id_emprendimiento = ?
        ");

        foreach ($productos as $producto) {
            $desc = $producto['descripcion'] ?? '';
            $precio = (float)($producto['precio'] ?? 0);
            $idProd = $producto['id_producto'] ?? null;
            $imagenUrl = $producto['imagen_url'] ?? null;
            
            if ($idProd) {
                // Actualizar producto existente
                $stmtUpdateProducto->execute([$desc, $precio, $idProd, $id_emprendimiento]);
                error_log("Producto actualizado: ID=$idProd, desc=$desc, precio=$precio");
                
                // Procesar imagen si viene
                if ($imagenUrl && strpos($imagenUrl, 'data:image') === 0) {
                    try {
                        error_log("Procesando imagen para producto ID=$idProd");
                        $imagenData = substr($imagenUrl, strpos($imagenUrl, ',') + 1);
                        $imagenBinary = base64_decode($imagenData, true);
                        
                        if ($imagenBinary !== false && !empty($imagenBinary)) {
                            error_log("Imagen decodificada correctamente, tamaño: " . strlen($imagenBinary) . " bytes");
                            // Verificar si ya existe archivo para este producto
                            $stmtCheckArchivo = $pdo->prepare("SELECT id_archivo FROM archivos WHERE id_emprendimiento = ? AND id_producto = ? LIMIT 1");
                            $stmtCheckArchivo->execute([$id_emprendimiento, $idProd]);
                            $archivoExistente = $stmtCheckArchivo->fetch();
                            
                            if ($archivoExistente) {
                                // Actualizar archivo existente
                                error_log("Actualizando archivo existente ID=" . $archivoExistente['id_archivo']);
                                $stmtUpdateArchivo = $pdo->prepare("
                                    UPDATE archivos 
                                    SET imagen = ?
                                    WHERE id_archivo = ?
                                ");
                                $stmtUpdateArchivo->execute([$imagenBinary, $archivoExistente['id_archivo']]);
                                error_log("Archivo actualizado exitosamente");
                            } else {
                                // Insertar nuevo archivo con id_producto
                                error_log("Insertando nuevo archivo para producto ID=$idProd");
                                $stmtInsertArchivo = $pdo->prepare("
                                    INSERT INTO archivos (id_emprendimiento, id_producto, imagen)
                                    VALUES (?, ?, ?)
                                ");
                                $stmtInsertArchivo->execute([$id_emprendimiento, $idProd, $imagenBinary]);
                                
                                // Obtener ID del archivo insertado
                                $idArchivo = $pdo->lastInsertId();
                                error_log("Archivo insertado con ID=$idArchivo");
                                
                                // Vincular archivo con producto
                                $stmtVincularArchivo = $pdo->prepare("
                                    UPDATE producto 
                                    SET id_archivo = ?
                                    WHERE id_producto = ?
                                ");
                                $stmtVincularArchivo->execute([$idArchivo, $idProd]);
                            }
                        }
                    } catch (Exception $e) {
                        error_log('Error al procesar imagen de producto: ' . $e->getMessage());
                    }
                }
            } else {
                // Insertar nuevo producto
                $stmtInsertProducto->execute([
                    ':id_emp' => $id_emprendimiento,
                    ':descripcion' => $desc,
                    ':precio' => $precio,
                ]);
                
                $idProdNuevo = $pdo->lastInsertId();
                
                // Procesar imagen si viene
                if ($imagenUrl && strpos($imagenUrl, 'data:image') === 0) {
                    try {
                        $imagenData = substr($imagenUrl, strpos($imagenUrl, ',') + 1);
                        $imagenBinary = base64_decode($imagenData, true);
                        
                        if ($imagenBinary !== false && !empty($imagenBinary)) {
                            // Insertar archivo con id_producto
                            $stmtInsertArchivo = $pdo->prepare("
                                INSERT INTO archivos (id_emprendimiento, id_producto, imagen)
                                VALUES (?, ?, ?)
                            ");
                            $stmtInsertArchivo->execute([$id_emprendimiento, $idProdNuevo, $imagenBinary]);
                            
                            // Obtener ID del archivo
                            $idArchivo = $pdo->lastInsertId();
                            
                            // Vincular archivo con producto
                            $stmtVincularArchivo = $pdo->prepare("
                                UPDATE producto 
                                SET id_archivo = ?
                                WHERE id_producto = ?
                            ");
                            $stmtVincularArchivo->execute([$idArchivo, $idProdNuevo]);
                        }
                    } catch (Exception $e) {
                        error_log('Error al procesar imagen de producto nuevo: ' . $e->getMessage());
                    }
                }
            }
        }
    }

    // Gestionar horarios: actualizar, insertar, eliminar por día
    $horarios = $input['horarios'] ?? [];
    $diasActuales = array_column($horarios, 'dia_semana');
    $ubicacionGeneral = $input['ubicacion'] ?? '';
    
    // Obtener horarios existentes para este emprendimiento
    $stmtExistentes = $pdo->prepare("SELECT id_horario, dia_semana FROM horarios WHERE id_emprendimiento = ?");
    $stmtExistentes->execute([$id_emprendimiento]);
    $horariosExistentes = $stmtExistentes->fetchAll(PDO::FETCH_ASSOC);
    $diasExistentes = array_column($horariosExistentes, 'dia_semana');
    $horariosMap = array_column($horariosExistentes, 'id_horario', 'dia_semana');
    
    // Eliminar días que ya no están seleccionados
    $diasAEliminar = array_diff($diasExistentes, $diasActuales);
    if (!empty($diasAEliminar)) {
        $stmtDeleteHor = $pdo->prepare("DELETE FROM horarios WHERE id_emprendimiento = ? AND dia_semana = ?");
        foreach ($diasAEliminar as $dia) {
            $stmtDeleteHor->execute([$id_emprendimiento, $dia]);
        }
    }
    
    // Actualizar o insertar horarios
    foreach ($horarios as $horario) {
        $dia = $horario['dia_semana'] ?? '';
        $horaIni = $horario['hora_inicial'] ?? '09:00:00';
        $horaFin = $horario['hora_final'] ?? '17:00:00';
        // Si tiene ubicación específica, usarla; si no, usar la ubicación general
        $ubicacion = (!empty($horario['ubicacion']) ? $horario['ubicacion'] : $ubicacionGeneral) ?? '';
        
        if (isset($horariosMap[$dia])) {
            // Actualizar horario existente
            $idHor = $horariosMap[$dia];
            $stmtUpdateHor = $pdo->prepare("
                UPDATE horarios 
                SET hora_inicial = ?, hora_final = ?, ubicacion = ?
                WHERE id_horario = ? AND id_emprendimiento = ?
            ");
            $stmtUpdateHor->execute([$horaIni, $horaFin, $ubicacion, $idHor, $id_emprendimiento]);
        } else {
            // Insertar nuevo horario
            $stmtInsertHor = $pdo->prepare("
                INSERT INTO horarios (id_emprendimiento, dia_semana, hora_inicial, hora_final, ubicacion)
                VALUES (?, ?, ?, ?, ?)
            ");
            $stmtInsertHor->execute([$id_emprendimiento, $dia, $horaIni, $horaFin, $ubicacion]);
        }
    }

    
    // Confirmar transacción
    $pdo->commit();

    http_response_code(200);
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode([
        'success' => true,
        'message' => 'Emprendimiento actualizado exitosamente',
        'id_emprendimiento' => (int)$id_emprendimiento
    ], JSON_UNESCAPED_UNICODE);
    exit;

} catch (PDOException $e) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }
    http_response_code(500);
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode([
        'success' => false,
        'message' => 'Error al actualizar emprendimiento',
        'detail' => $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
    exit;
} catch (Exception $e) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }
    http_response_code(500);
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode([
        'success' => false,
        'message' => 'Error interno',
        'detail' => $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
    exit;

?>
