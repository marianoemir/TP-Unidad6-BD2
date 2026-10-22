# SPEC_U6 — Mantenimiento de Food Store

**Alcance.** Automatizar el respaldo de `foodstore`, monitorear su salud, mantenerla y comprobar que se puede
recuperar. PostgreSQL 16+, Windows y PowerShell, solo en el servidor propio. La restauración y las pruebas
destructivas van únicamente en `foodstore_restore_test`; `foodstore` no se elimina ni se reemplaza.

## 1. Tareas, frecuencia y condición de éxito

- **Respaldo** (`backup_foodstore.ps1`, diaria): `pg_dump` devuelve 0, el `.dump` existe con tamaño mayor a cero,
  `pg_restore --list` lo lee y el log registra el resultado.
- **Chequeo de salud** (`health_check.sql`, diaria): corre sin errores y muestra tamaño, conexiones, tablas y consultas activas.
- **Revisión de mantenimiento** (`maintenance.sql`, semanal): se observó el estado de las tablas (tuplas muertas,
  autovacuum, estadísticas) y hay una decisión justificada.
- **Restauración de prueba** (`restore_test.ps1`, opcional, semanal): restaura sin errores en `foodstore_restore_test`,
  los conteos coinciden con los previos y los controles de inválidos dan cero.

## 2. Objetivos de recuperación previstos

- **RPO** (datos que se aceptan perder): hasta 24 h. Se observa como la antigüedad del respaldo al iniciar la restauración.
- **RTO** (tiempo para volver a operar): menos de 20 min. Se observa con un cronómetro desde antes de crear
  `foodstore_restore_test` hasta terminar las validaciones.

## 3. Convenciones y reglas de seguridad

- **Respaldo:** formato custom (`pg_dump -Fc`) en `backups/foodstore_AAAAMMDD_HHMMSS.dump`, escrito como `.parcial` y
  renombrado al final; un log por ejecución en `logs/`; si `pg_dump` falla, termina con error.
- **Restauración:** `pg_restore --no-owner --no-privileges` del último respaldo, solo en `foodstore_restore_test`; los
  scripts se niegan a actuar si el destino es `foodstore`.
- **Validación:** conteos de `categoria`, `usuario`, `producto`, `pedido` y `detalle_pedido` antes y después;
  `productos_invalidos` y `detalles_invalidos` en 0. La consigna dice `cliente`; en esta base es `usuario`.
- **Mantenimiento:** sin `VACUUM FULL`; todo `VACUUM` o `ANALYZE` manual se justifica con la observación previa.
- **Contraseñas:** ninguna en scripts, logs, evidencias, informe ni repositorio; se usa `pgpass.conf` y `-w`.
- **OpenCode:** su código se revisa y se ejecuta antes de aceptarse; el informe indica qué parte fue asistida.
