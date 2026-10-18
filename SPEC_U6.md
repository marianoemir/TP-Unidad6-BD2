# SPEC_U6 — Mantenimiento, respaldo y recuperación de Food Store

**Alcance.** Automatizar el respaldo de `foodstore`, monitorear su salud, mantenerla y comprobar que se
puede recuperar. Motor: PostgreSQL 16 o superior (servidor del equipo: 17), Windows y PowerShell.
Todo se ejecuta solo en el servidor propio. La restauración y las pruebas destructivas van únicamente
en `foodstore_restore_test`; `foodstore` no se elimina ni se reemplaza.

## 1. Tareas, frecuencia y condición de éxito

| Tarea | Archivo | Frecuencia propuesta | Se considera terminada correctamente cuando… |
|---|---|---|---|
| Respaldo de `foodstore` | `backup_foodstore.ps1` | Diaria | `pg_dump` termina con código 0, el `.dump` existe con tamaño mayor a cero, `pg_restore --list` lo lee y el log registra el resultado |
| Chequeo de salud | `health_check.sql` | Diaria | Corre sin errores y muestra tamaño, conexiones, estado de tablas y consultas activas |
| Revisión de mantenimiento | `maintenance.sql` | Semanal | Se observó el estado de las tablas (tuplas muertas, autovacuum, estadísticas) y hay una decisión documentada sobre qué hacer y por qué |
| Restauración de prueba | `restore_test.ps1` (opcional) | Semanal | Restaura sin errores en `foodstore_restore_test`, los conteos coinciden con los previos al respaldo y los dos controles de inválidos dan cero |

La programación automática (Programador de tareas de Windows) queda fuera de este TP: primero cada script
se ejecuta y se prueba a mano.

## 2. Objetivos de recuperación previstos para el laboratorio

| | Previsto | Qué mide | Cómo se observa en el simulacro |
|---|---|---|---|
| **RPO** | Hasta 24 h (respaldo diario) | Cuántos datos, en tiempo, se aceptan perder | Antigüedad del respaldo al iniciar la restauración |
| **RTO** | Menos de 20 min | Cuánto tarda en volver a estar utilizable | Cronómetro desde antes de crear `foodstore_restore_test` hasta terminar las validaciones |

## 3. Convenciones

- Respaldo en formato custom (`pg_dump -Fc`): `backups/foodstore_AAAAMMDD_HHMMSS.dump`. Se escribe como
  `.parcial` y se renombra solo al final. Log por ejecución: `logs/backup_AAAAMMDD_HHMMSS.log`.
- La restauración usa `pg_restore --no-owner --no-privileges` sobre el **último** respaldo.
- Validación mínima: conteos de `categoria`, `usuario`, `producto`, `pedido` y `detalle_pedido` antes y después;
  `productos_invalidos` y `detalles_invalidos` deben dar 0. La consigna nombra la tabla `cliente`: en esta base
  se llama `usuario`.
- Mantenimiento: sin `VACUUM FULL`. Un `VACUUM` o `ANALYZE` manual se justifica con la observación previa
  (`n_dead_tup`, `n_mod_since_analyze`, `last_autovacuum`, `last_autoanalyze`).
- `backups/` y `logs/` no se versionan; la evidencia se entrega como copia en `evidencias/`.

## 4. Reglas de seguridad

1. **Ninguna contraseña** en scripts, logs, evidencias, informe ni repositorio. Se usa `pgpass.conf`
   (fuera del repo) y las herramientas se invocan con `-w`.
2. Restaurar **solo** en `foodstore_restore_test`; los scripts se niegan a actuar si el destino es `foodstore`.
3. Si `pg_dump` falla, el script termina con error y no deja un respaldo parcial.
4. Todo script registra fecha, operación y resultado, y se prueba a mano antes de darlo por apto.
5. El código generado con OpenCode se revisa línea por línea y se ejecuta antes de aceptarse; el informe indica
   qué parte fue asistida y cómo se verificó.

## 5. Límites conocidos

`pg_dump` no respalda los roles ni sus permisos (son del servidor): con `--no-owner --no-privileges` no vuelven
en la base restaurada. Se resguardarían aparte con `pg_dumpall --globals-only --no-role-passwords`.
