# Datos para el informe — simulacro de la Unidad 6

**Lo completa Mariano, a medida que ocurre cada paso.** Facundo estructura y redacta el informe a partir de este
archivo. Regla: solo valores **observados** en la ejecución, cada uno con el archivo de `evidencias/` que lo
respalda. Si algo no ocurrió, se escribe "no ocurrió" (por ejemplo, si no hubo ningún problema real).

Todo lo de este archivo ocurrió el 2026-10-18.

## 1. Respaldo utilizado

| Dato | Valor | Evidencia |
|---|---|---|
| Nombre del archivo `.dump` | `foodstore_20261018_094932.dump` (el "último respaldo": lo eligió `restore_test.ps1` por fecha) | `evidencias/restore_log_ok.txt` |
| Fecha y hora de creación | 2026-10-18 09:49:32 (el log del respaldo va de 09:49:32 a 09:49:37) | `evidencias/backup_log_094932.txt`, `evidencias/backups_listado.txt` |
| Tamaño | 10.650.048 bytes | `evidencias/backups_listado.txt`, `evidencias/backup_log_094932.txt` |
| Resultado de `pg_restore --list` | Correcto: 74 líneas de salida, sin error | `evidencias/backup_log_094932.txt` |
| Huella SHA-256 | `9FF281D97A399EB7D8BFA583B4C83EEA30EDACF1DBCF3362278806E0178B55FB` | `evidencias/backup_log_094932.txt` |

Respaldos generados al probar `backup_foodstore.ps1`, antes del simulacro:

| Archivo | Tamaño | Observación |
|---|---|---|
| `foodstore_20261018_094708.dump` | 10.650.048 bytes (SHA-256 `54F84A53...B895FA`) | Primera corrida válida; `pg_restore --list` de 74 líneas |
| `foodstore_20261018_094932.dump` | 10.650.048 bytes (SHA-256 `9FF281D9...B55FB`) | Segunda corrida, código de salida 0. Es el respaldo usado en el simulacro |

Prueba del caso de error (`-Base foodstore_no_existe`, 09:48:09): `RESULTADO: ERROR`, código de salida 1 y sin archivo
`.parcial` en `backups/`. Evidencia: `evidencias/backup_log_ok.txt` y `evidencias/backup_log_error.txt`.

Los dos respaldos se generaron **a mano**, durante las pruebas del script. No hay tarea programada (la programación
automática quedó fuera de alcance según `SPEC_U6.md`).

## 2. Simulacro de restauración

Se hicieron dos corridas de `restore_test.ps1` sobre el mismo respaldo. La primera encontró un error del script (ver
sección 5); la segunda, con el script corregido, es la **oficial**.

| Dato | Primera corrida (con el error) | Segunda corrida (oficial) | Evidencia |
|---|---|---|---|
| Estado previo de `foodstore_restore_test` | No existía | Existía: el script la eliminó con `dropdb` antes del cronómetro | `restore_log_con_error.txt`, `restore_log_ok.txt` |
| Inicio del cronómetro (antes de crear la base) | 11:14:12 | 11:16:42 | ídem |
| Fin (terminaron las validaciones) | 11:14:18 | 11:16:48 | ídem |
| **Tiempo total (RTO observado)** | 5,51 s (00:00:05.5108279) | **6,19 s (00:00:06.1878335)** | ídem |
| Código de salida | 0 | 0 | consola |

- Servidor: PostgreSQL 17 sobre Windows, `localhost:5432` (versión menor no registrada). Evidencia: `AGENTS.md` y la
  bitácora de Mariano (H0).
- El RTO mide `createdb`, `pg_restore` y las siete consultas de validación. **No incluye** la verificación de si la
  base existía ni el `dropdb` previo, que corren antes del cronómetro.
- El RTO no incluye un `ANALYZE` posterior: no se ejecutó en el simulacro.

Prueba del rechazo (`-BaseDestino foodstore`): el script respondió `RESULTADO: ERROR - Base destino no permitida
('foodstore')` y terminó con código 1, sin tocar ninguna base. Evidencia: `evidencias/restore_log_rechazo.txt` y la
salida de consola.

## 3. RPO y RTO

| | Previsto | Observado (corrida oficial) | Cómo se calculó el observado |
|---|---|---|---|
| **RPO** | hasta 24 h (respaldo diario) | **1,45 h (01:27:10)** | Inicio del simulacro (11:16:42) menos creación del respaldo (09:49:32) |
| **RTO** | menos de 20 min | **6,19 s** | Cronómetro desde antes de crear la base hasta el fin de las validaciones |

En la primera corrida: RPO 1,41 h (01:24:40) y RTO 5,51 s.

Comentario sobre la diferencia entre RPO y RTO en este simulacro:

- El **RPO** habla de datos: el valor observado es la antigüedad del respaldo cuando empezó la restauración. Si el
  incidente hubiera ocurrido en ese momento, se habrían perdido como máximo los cambios hechos en esas 1,45 h. Cumple
  lo previsto (hasta 24 h), pero con una salvedad: los respaldos se hicieron a mano durante las pruebas; no hay
  respaldo diario programado que lo sostenga.
- El **RTO** habla de tiempo: 6,19 s para restaurar y validar, frente a los 20 min previstos. Es una base de
  prueba (respaldo de unos 10,6 MB) en el mismo equipo, así que no es una cifra para extrapolar a producción.
- Son independientes: el RPO no cambia aunque la restauración tarde más o menos, y el RTO no depende de qué tan
  viejo sea el respaldo.

## 4. Validaciones

| Control | Antes del respaldo (`foodstore`) | Después de restaurar (`foodstore_restore_test`) | Coincide |
|---|---|---|---|
| Filas de `categoria` | 6 | 6 | Sí |
| Filas de `usuario` (la consigna dice `cliente`) | 20.006 | 20.006 | Sí |
| Filas de `producto` | 50.016 | 50.016 | Sí |
| Filas de `pedido` | 200.006 | 200.006 | Sí |
| Filas de `detalle_pedido` | 400.013 | 400.013 | Sí |
| `productos_invalidos` (debe ser 0) | 0 | 0 | Sí |
| `detalles_invalidos` (debe ser 0) | 0 | 0 | Sí |

Evidencia: `evidencias/conteos_antes.txt` (2026-10-18 09:35) y `evidencias/restore_log_ok.txt`. Los mismos valores
dieron en la primera corrida (`restore_log_con_error.txt`).

La comparación de los conteos contra `conteos_antes.txt` la hizo una persona: el script imprime los valores pero no
los compara solo.

Nota que va en el informe: la consigna usa la tabla `cliente`; en esta base se llama `usuario`.

## 5. Problemas reales encontrados

El código de ambos scripts lo generó OpenCode. Los dos problemas los detectó **la ejecución**, no la revisión previa
(ni la de Mariano ni la de Claude con la lista de ocho preguntas).

**Problema 1 — `backup_foodstore.ps1`: error de sintaxis.** Al ejecutarlo por primera vez, PowerShell rechazó el
archivo con un `ParserError` en la línea 43: el texto `'$Servidor:$Puerto'` es sintaxis inválida, porque `$Servidor:`
se interpreta como una unidad (como `C:`). Se corrigió escribiendo `${Servidor}:${Puerto}`. No se ejecutó nada del
script antes del arreglo, así que no quedó ningún respaldo parcial. Evidencia: `Datos para Facundo/Parte de Mariano para el informe/error_sintaxis_backup.txt`.
Nota: OpenCode señaló esta misma línea (`$var:` sin llaves) en su respuesta al generar `restore_test.ps1`, pero recién después de que el error ya había aparecido al ejecutar; no lo advirtió antes.

**Problema 2 — `restore_test.ps1`: error en la línea 152 cuando la base destino no existe.** En la primera corrida,
`psql` no devolvió filas al buscar `foodstore_restore_test` (la base no existía) y la línea
`$existeBase = (([string]$resultadoExiste).Trim() -eq "1")` falló con "No se puede llamar a un método en una
expresión con valor NULL" (`InvokeMethodOnNull`). Causa probable: el resultado vacío quedó como valor nulo y no se
pudo aplicar `.Trim()`; no se reprodujo fuera del equipo.
- El error no abortó el script (no es terminante) y **no quedó en el log**: solo apareció en la consola. Como la base
  no existía, la rama "se creará desde cero" era la correcta y la primera corrida terminó con `RESULTADO: OK`.
- Corrección: `$existeBase = ("$resultadoExiste".Trim() -eq "1")` (la interpolación de una cadena trata el nulo como
  cadena vacía). Se comprobó la sintaxis con el analizador de PowerShell y se repitió el simulacro: la segunda
  corrida pasó por la rama que elimina la base existente, sin errores.
- Evidencia: `Datos para Facundo/Parte de Mariano para el informe/error_restore_consola.txt` (texto de la consola, que no se guardó en archivo),
  `evidencias/restore_log_con_error.txt` y `evidencias/restore_log_ok.txt`.

## 6. Mejora concreta propuesta

**Respaldar también los roles** con `pg_dumpall --globals-only --no-role-passwords`, como un paso más de
`backup_foodstore.ps1`, guardando el resultado junto al `.dump`.

Por qué: `pg_dump` no incluye roles ni permisos, y la restauración con `--no-owner --no-privileges` tampoco los
trae. En el simulacro la base volvió con sus datos, pero **sin dueños ni permisos asignados**; y en un desastre
real, sobre un servidor nuevo, tampoco existirían los roles: habría que rearmarlos a mano antes de dar acceso. Reduce el riesgo y el tiempo de
recuperación real, que el RTO de 6,19 s no refleja.

Estado: **propuesta, no implementada ni probada** en este TP. Las contraseñas no se incluyen (`--no-role-passwords`)
y habría que reasignarlas al restaurar.

Otras candidatas observadas:
- (a) El script se conecta como `postgres`, que es superusuario; un rol de solo lectura alcanzaría para `pg_dump`.
- (b) En `backup_foodstore.ps1`, el chequeo de tamaño mayor a cero ocurre después de renombrar el `.parcial`; es
  redundante con `pg_restore --list`, pero convendría hacerlo antes.
- (c) Un error de PowerShell como el de la línea 152 no queda en el log, porque el script solo registra errores de las
  herramientas externas. Un `try/catch` con `$ErrorActionPreference = 'Stop'` en esos tramos lo registraría.
- (d) Un respaldo no trae las estadísticas del planificador: después de restaurar convendría correr `ANALYZE` en la
  base restaurada (y sumarlo a la medición del RTO).

## 7. Uso de OpenCode y cómo se verificó

| Parte | Qué asistió OpenCode | Cómo se verificó antes de aceptarlo |
|---|---|---|
| Respaldo (`backup_foodstore.ps1`) | Generó el script completo a partir de la spec y de `AGENTS.md` y aplicó tres ajustes pedidos (tamaño mayor a cero, log menos ruidoso, mensaje `RESULTADO` por consola) | Lectura con la lista de ocho preguntas, comprobación del archivo real (8 `RESULTADO`, ASCII, primera y última línea), ejecución manual de los casos de éxito y de error. La ejecución encontró un `ParserError` que la lectura no vio |
| Restauración (`restore_test.ps1`) | Generó el script completo a partir de la spec y de `AGENTS.md` con un prompt preparado con Claude: destino fijo, elección del último respaldo, cronómetro, validaciones, RTO y RPO | Lectura con la lista de ocho preguntas (sin hallazgos de seguridad); comprobación de sintaxis con el analizador de PowerShell; prueba del rechazo con `-BaseDestino foodstore` (código 1); dos ejecuciones reales. La primera encontró el error de la línea 152, que la lectura no vio; se corrigió y la segunda salió limpia |
| Monitoreo (`health_check.sql`, Andrés) | | |
| Mantenimiento (`maintenance.sql`, Facundo) | | |

(Se completa con lo que cada uno anotó en su bitácora personal.)
