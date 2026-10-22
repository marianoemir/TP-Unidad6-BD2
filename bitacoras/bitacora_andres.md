# Bitácora personal — Andrés

Registro de lo que hice y por qué, para poder volver a consultarlo. Copiá este archivo como
`bitacoras/bitacora_<nombre>.md` y completá solo lo que corresponde a tus partes. Al final se unifica en
`BITACORA.md`.

Reglas de uso:
- Anotá lo que realmente pasó. Si OpenCode no se equivocó, escribí que no se equivocó.
- Resumí las respuestas, no las copies completas.
- Sin contraseñas ni datos que no deban estar en el repo.

## Mi parte

`maintenance.sql` (mitad de la Parte 3), revisión cruzada del respaldo, revisión del simulacro de restauración y revisión posterior del informe[cite: 1].

## Mi entorno (H0)

| Servidor y versión | Conteos de `usuario`, `producto`, `pedido` | Problemas y cómo se resolvieron |
|---|---|---|
| PostgreSQL 17 (Local)[cite: 1, 19] | `usuario`: 20.006<br>`producto`: 50.016<br>`pedido`: 200.006[cite: 1, 19] | Falta inicial del archivo `pgpass.conf`. Se solucionó creando el archivo en `%APPDATA%\postgresql\` con permisos restringidos mediante `icacls`[cite: 1]. |

## Interacciones con OpenCode

| Prompt enviado a la IA | Respuesta relevante recibida (resumida) | Validación o corrección humana aplicada |
|---|---|---|
| Estructuración de `maintenance.sql` en 4 fases para PostgreSQL 16+ siguiendo `SPEC_U6.md` y `AGENTS.md`[cite: 1]. | Script SQL con fases de ensayo en base descartable, cálculo de umbral, y `VACUUM (ANALYZE)` sin bloques transaccionales[cite: 1, 20]. | Se aplicaron las 8 preguntas de `AGENTS.md`[cite: 1]. Se validó la ausencia de `BEGIN/COMMIT` por restricciones de `VACUUM` y se probó en `foodstore_restore_test`[cite: 1, 20]. |

## Revisión cruzada que hice

| Qué revisé | En qué servidor lo ejecuté | Qué encontré |
|---|---|---|
| `backup_foodstore.ps1`[cite: 1] | Servidor local (`foodstore`)[cite: 1] | Finalizó con `RESULTADO: OK`, generando el `.dump`, `.sha256` y el log tras configurar las credenciales[cite: 1, 3]. |
| Simulacro (`restore_test.ps1`)[cite: 1] | Servidor local (`foodstore_restore_test`)[cite: 1] | Restauración exitosa, conteos coincidentes con la base original y registros inválidos en cero[cite: 1, 5]. |

## Mediciones (valores observados, no estimados)

| Dato | Valor | Cómo se midió |
|---|---|---|
| Tuplas muertas iniciales (`n_dead_tup`)[cite: 1, 19] | `0` en todas las tablas[cite: 1, 19] | Mediante `health_check.sql` (`health_check_salida_andres.txt`)[cite: 1, 19]. |
| Umbral teórico de autovacuum (`producto`)[cite: 1, 19, 21] | `10.053,2` tuplas muertas[cite: 1, 19, 21] | Cálculo formal: `50 + (0.2 * 50.016)`[cite: 1, 19, 21]. |
| Ensayo de mantenimiento (`maintenance_salida.txt`)[cite: 1, 21] | 50.015 tuplas muertas generadas y limpiadas con éxito[cite: 20, 21] | Ejecución de `UPDATE` masivo y posterior `VACUUM (ANALYZE)` en base descartable[cite: 1, 20, 21]. |

## Problemas encontrados y cómo se resolvieron

| Fecha | Problema | Causa | Solución |
|---|---|---|---|
| 2026-10-21[cite: 21] | Error de autenticación `fe_sendauth: no password supplied` en `pg_dump`[cite: 3]. | Inexistencia del archivo de credenciales `pgpass.conf` en el perfil local[cite: 1, 3]. | Creación del archivo `pgpass.conf` en el directorio Appdata con permisos seguros[cite: 1]. |

## Decisiones tomadas

| Decisión | Alternativas | Por qué |
|---|---|---|
| Realizar ensayo en base descartable (`foodstore_restore_test`)[cite: 1, 20]. | Actuar directo sobre producción o no realizar acción[cite: 1]. | La base principal estaba 100% limpia (`n_dead_tup = 0`), por lo que el ensayo demostrativo permite cumplir la consigna sin alterar producción[cite: 1, 19, 20]. |
| Omitir el uso de `VACUUM FULL`[cite: 1, 20]. | Usar `VACUUM FULL`[cite: 1, 20]. | `VACUUM FULL` aplica un bloqueo exclusivo (`AccessExclusiveLock`) que interrumpe la disponibilidad en producción[cite: 1, 20]. |