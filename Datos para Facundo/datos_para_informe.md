# Datos para el informe — simulacro de la Unidad 6

**Lo completa Mariano, a medida que ocurre cada paso.** Facundo estructura y redacta el informe a partir de este
archivo. Regla: solo valores **observados** en la ejecución, cada uno con el archivo de `evidencias/` que lo
respalda. Si algo no ocurrió, se escribe "no ocurrió" (por ejemplo, si no hubo ningún problema real).

## 1. Respaldo utilizado

| Dato | Valor | Evidencia |
|---|---|---|
| Nombre del archivo `.dump` | | |
| Fecha y hora de creación | | |
| Tamaño | | |
| Resultado de `pg_restore --list` | | |
| Huella SHA-256 (si se generó) | | |

Respaldos generados al probar `backup_foodstore.ps1` (2026-10-18), antes del simulacro:

| Archivo | Tamaño | Observación |
|---|---|---|
| `foodstore_20261018_094708.dump` | 10.650.048 bytes (SHA-256 `54F84A53...B895FA`) | Primera corrida válida; `pg_restore --list` de 74 líneas |
| `foodstore_20261018_094932.dump` | (anotar) | Segunda corrida, `$LASTEXITCODE` 0. Si no se genera otro, es el "último respaldo" del simulacro |

Prueba del caso de error (`-Base foodstore_no_existe`): `RESULTADO: ERROR`, código de salida 1 y sin archivo
`.parcial` en `backups/`. Evidencia: `evidencias/backup_log_ok.txt` y `evidencias/backup_log_error.txt`.

## 2. Simulacro de restauración

| Dato | Valor | Evidencia |
|---|---|---|
| Hora de inicio del cronómetro (antes de crear `foodstore_restore_test`) | | |
| Hora en que terminaron las validaciones | | |
| **Tiempo total (RTO observado)** | | |
| Servidor y versión de PostgreSQL | | |

## 3. RPO y RTO

| | Previsto | Observado | Cómo se calculó el observado |
|---|---|---|---|
| **RPO** | hasta 24 h (respaldo diario) | | Hora de inicio del simulacro menos hora de creación del respaldo |
| **RTO** | menos de 20 min | | Cronómetro desde antes de crear la base hasta el fin de las validaciones |

Comentario sobre la diferencia entre RPO y RTO en este simulacro (si hace falta):

## 4. Validaciones

| Control | Antes del respaldo (`foodstore`) | Después de restaurar (`foodstore_restore_test`) | Coincide |
|---|---|---|---|
| Filas de `categoria` | | | |
| Filas de `usuario` (la consigna dice `cliente`) | | | |
| Filas de `producto` | | | |
| Filas de `pedido` | | | |
| Filas de `detalle_pedido` | | | |
| `productos_invalidos` (debe ser 0) | | | |
| `detalles_invalidos` (debe ser 0) | | | |

Nota que va en el informe: la consigna usa la tabla `cliente`; en esta base se llama `usuario`.

## 5. Problema real encontrado

Al ejecutar por primera vez `backup_foodstore.ps1` (generado con OpenCode), PowerShell rechazó el archivo con un
`ParserError` en la línea 43: el texto `'$Servidor:$Puerto'` es sintaxis inválida, porque `$Servidor:` se interpreta
como una unidad (como `C:`). Se corrigió escribiendo `${Servidor}:${Puerto}`. Lo detectó el intérprete al ejecutar, no
la revisión previa del código. No se ejecutó nada del script antes del arreglo, así que no quedó ningún respaldo
parcial. Evidencia: `evidencias/error_sintaxis_backup.txt`.

(Si durante el simulacro aparece otro problema, agregarlo acá.)

## 6. Mejora concreta propuesta

(Una mejora para reducir riesgo o tiempo en la próxima ejecución, y por qué.)

Otras candidatas observadas: (a) el script se conecta como `postgres`, que es superusuario; un rol de solo
lectura sería suficiente para `pg_dump`; (b) el chequeo de tamaño mayor a cero ocurre después de renombrar el
`.parcial`; es redundante con `pg_restore --list`, pero convendría hacerlo antes.

Candidata ya identificada: respaldar también los roles con `pg_dumpall --globals-only --no-role-passwords`,
porque `pg_dump` no los incluye y la restauración con `--no-owner --no-privileges` no los trae.

## 7. Uso de OpenCode y cómo se verificó

| Parte | Qué asistió OpenCode | Cómo se verificó antes de aceptarlo |
|---|---|---|
| Respaldo (`backup_foodstore.ps1`) | Generó el script completo a partir de la spec y de `AGENTS.md` y aplicó tres ajustes pedidos (tamaño mayor a cero, log menos ruidoso, mensaje `RESULTADO` por consola) | Lectura con la lista de ocho preguntas, comprobación del archivo real (8 `RESULTADO`, ASCII, primera y última línea), ejecución manual de los casos de éxito y de error. La ejecución encontró un `ParserError` que la lectura no vio |
| Restauración (`restore_test.ps1`, si existe) | | |
| Monitoreo (`health_check.sql`, Andrés) | | |
| Mantenimiento (`maintenance.sql`, Facundo) | | |

(Se completa con lo que cada uno anotó en su bitácora personal.)
