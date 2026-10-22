# Bitácora — TP Unidad 6 (Food Store: mantenimiento, respaldo y recuperación)

Registro unificado de lo que hicimos y por qué, para poder volver a consultarlo. La consigna no lo exige: lo llevamos
nosotros. Cada integrante llevó su bitácora personal en `bitacoras/bitacora_<nombre>.md` y **Mariano las unificó acá**,
comparando cada fila contra la evidencia del repo.

Reglas de uso:
- Se anota lo que realmente pasó. Si OpenCode no se equivocó, se escribe que no se equivocó.
- Las respuestas se **resumen**, no se copian completas.
- No se anotan contraseñas ni datos que no deban estar en el repo.
- Cada fila lleva el nombre de quien la escribió. Lo que Mariano completó por otro integrante está indicado.

## Herramientas usadas

| Herramienta | Quién | Para qué |
|---|---|---|
| OpenCode | Mariano, Andrés | Generar `backup_foodstore.ps1`, `restore_test.ps1` (Mariano) y `maintenance.sql` (Andrés) a partir de `SPEC_U6.md` y `AGENTS.md` |
| Claude (claude.ai) | Mariano | Armar `SPEC_U6.md`, `AGENTS.md`, `DIVISION_DE_TRABAJO.md`, las plantillas y `health_check.sql`; preparar los prompts para OpenCode; revisar scripts con la lista de ocho preguntas; corregir `maintenance.sql`; armar `informe_u6.pdf` y esta bitácora; guiar los comandos paso a paso |
| pgAdmin 4, `psql`, `pg_dump`, `pg_restore` | Mariano, Andrés | Armar las bases, ejecutar los scripts y consultar |

## H0 — Entorno (cada integrante)

| Quién | Servidor y versión | Conteos de `usuario`, `producto`, `pedido` | Problemas y cómo se resolvieron |
|---|---|---|---|
| Mariano | PostgreSQL 17, Windows, `localhost:5432`. Base `foodstore` armada siguiendo los pasos de H0 | `usuario` 20.006, `producto` 50.016, `pedido` 200.006 (2026-10-18) | `psql -w` dio `fe_sendauth: no password supplied`: faltaba `pgpass.conf`. Lo creó en `%APPDATA%\postgresql\` con una línea `localhost:5432:*:postgres:<clave>`, comprobó que el archivo existe con ese nombre exacto (32 bytes, no `.txt`) y repitió la consulta: respondió sin pedir clave |
| Andrés | PostgreSQL 17 (local) | `usuario` 20.006, `producto` 50.016, `pedido` 200.006 | Faltaba `pgpass.conf`. Se creó en `%APPDATA%\postgresql\` con permisos restringidos mediante `icacls` |
| Facundo | Sin registro propio en este TP | — | — |

## Parte 1 — Especificación (Mariano)

| Prompt o pedido | Respuesta relevante recibida (resumida) | Validación o corrección humana aplicada |
|---|---|---|
| **Mariano · Claude:** `SPEC_U6.md` de una página con tareas, frecuencia, condición de éxito, RPO y RTO previstos y reglas de seguridad | Spec de 52 líneas con tabla de tareas, objetivos de recuperación (RPO hasta 24 h, RTO menos de 20 min), convenciones, reglas y límites | Quedó en la raíz del repo y se commiteó en `main`. Pendiente de comprobar al exportarla que ocupe una sola página |

## Parte 2 — Respaldo (Mariano; revisión cruzada: Andrés)

| Prompt enviado a la IA | Respuesta relevante recibida (resumida) | Validación o corrección humana aplicada |
|---|---|---|
| **Mariano · OpenCode:** generar `backup_foodstore.ps1` desde `SPEC_U6.md` y `AGENTS.md`: parámetros con valores por defecto, `.parcial` renombrado al final, `pg_dump -Fc -w -v`, sin contraseña ni `PGPASSWORD`, log ASCII, `exit 1` si falla, `pg_restore --list` y SHA-256. Pidió que **no ejecutara nada** (prompt preparado con Claude) | Script con parámetros, carpetas desde `$PSScriptRoot`, verificación con `pg_restore --list`, SHA-256, log ASCII y `exit 1` ante errores, más una lista de cuatro supuestos | Revisión con la lista de ocho preguntas (con Claude): sin hallazgos de seguridad (sin contraseñas, solo borra su propio `.parcial`, sin bloqueos exclusivos). Tres ajustes: tamaño mayor a cero, no volcar todo el `pg_restore --list` al log y mostrar un `RESULTADO` por consola. Observación: se conecta como `postgres` (superusuario) |
| **Mariano · OpenCode:** aplicar solo esos tres ajustes y mostrar el diff, sin ejecutar nada | Dijo que los cambios **ya estaban aplicados** y mostró el diff, pero el texto recibido antes no los tenía | No aceptó su palabra: verificó el archivo real. `Select-String 'RESULTADO'` dio 8 (siete errores y el éxito), sin caracteres no ASCII, primera línea `<#` y última `exit 0` |
| **Mariano** (no es un prompt): primera ejecución de `backup_foodstore.ps1` | PowerShell rechazó el archivo: `ParserError` en la línea 43; `'$Servidor:$Puerto'` se interpreta como una unidad (como `C:`) | **Corrección humana:** cambió a `${Servidor}:${Puerto}` y repitió. Lo detectó el intérprete: ni la revisión con la lista ni la de Claude lo vieron. OpenCode lo señaló después, en su respuesta para `restore_test.ps1`, cuando el error ya había aparecido |

Revisión cruzada (**Andrés**): según lo que dejó escrito, corrió `backup_foodstore.ps1` en su servidor y terminó con
`RESULTADO: OK`, generando el `.dump`, el `.sha256` y el log, después de crear `pgpass.conf`. **No hay logs suyos
adjuntos** que lo respalden.

## Parte 3 — Monitoreo y mantenimiento

### Monitoreo: `health_check.sql` (Mariano)

| Prompt o pedido | Respuesta relevante recibida (resumida) | Validación o corrección humana aplicada |
|---|---|---|
| **Mariano · Claude** (no OpenCode): un `health_check.sql` de solo lectura con los cuatro controles de la consigna | Script con cinco controles (tamaño, conexiones, estado de tablas, consultas activas, parámetros de autovacuum) dentro de una transacción `READ ONLY`, ASCII, ejecutable con `psql -f` | Lo corrió en su servidor: salió sin errores y con los cinco controles completos (`evidencias/health_check_salida.txt`). Control 4 con cero filas, lo esperado |

Observación en el servidor de Mariano: `foodstore` pesa 136 MB, con 1 conexión y 99,99 % de aciertos de caché; la tabla con más
tuplas muertas tiene 1 (0,00 %) y `n_mod_since_analyze` es 0 en todas. Estado sano: no había nada que justificar un
`VACUUM` ni un `ANALYZE` sobre `foodstore`.

### Mantenimiento: `maintenance.sql` (Andrés; corrección y corrida final: Mariano)

| Prompt enviado a la IA | Respuesta relevante recibida (resumida) | Validación o corrección humana aplicada |
|---|---|---|
| **Andrés · OpenCode:** estructurar `maintenance.sql` en cuatro fases siguiendo `SPEC_U6.md` y `AGENTS.md` (resumen del pedido, no el texto literal) | Script con ensayo en la base descartable, cálculo del umbral de autovacuum y `VACUUM (ANALYZE, VERBOSE)` sin bloques transaccionales | Ocho preguntas de `AGENTS.md`; ausencia de `BEGIN`/`COMMIT`. **La revisión no detectó** que las observaciones salían con retraso: se vio al leer la salida |
| **Mariano · Claude:** revisar la entrega de Andrés (script, salidas, nota y bitácora) contra la consigna y la evidencia | Detectó que la salida contradecía lo afirmado (observación previa en 0 y posterior en 50.015 tuplas muertas) y que los textos tenían marcas de citas sueltas de otra herramienta de IA | Mariano comprobó la salida, aceptó agregar `pg_sleep(2)` y una observación base, y quitó `VERBOSE` (escribe en stderr y no aparece en el archivo de salida). Ejecutó la versión corregida el 2026-10-21 a las 21:59 |

Observación y resultado (todos sobre `foodstore_restore_test`, tabla `producto`; umbral teórico de autovacuum
50 + 0,2 × 50.016 = **10.053,2**):

| Momento | `n_dead_tup` | Evidencia |
|---|---|---|
| Primera corrida de Andrés (21:04), observación "previa" | 0 | `maintenance_salida_corrida1_andres.txt` |
| Primera corrida de Andrés (21:04), observación "posterior" | 50.015 (**al revés de lo esperado**) | ídem |
| Corrida final de Mariano (21:59): base, previa a la acción, posterior | 0 → 50.015 → 0 | `maintenance_salida.txt` |

La acción es un **ensayo** (`UPDATE producto SET precio = precio WHERE eliminado = FALSE;` de 50.015 filas, y después
`VACUUM (ANALYZE) producto;`), no mantenimiento real: `foodstore` estaba limpia.

Revisión cruzada: **Mariano** ejecutó la versión final de `maintenance.sql`. Andrés ejecutó `health_check.sql` en su
servidor (`health_check_salida_andres.txt`: `n_dead_tup` en 0 en todas sus tablas).

## Parte 4 — Simulacro de desastre (Mariano; revisión cruzada: Andrés)

| Prompt enviado a la IA | Respuesta relevante recibida (resumida) | Validación o corrección humana aplicada |
|---|---|---|
| **Mariano · OpenCode:** generar `restore_test.ps1` desde `SPEC_U6.md` y `AGENTS.md`: destino fijo `foodstore_restore_test`, elección del último respaldo (ignora `.parcial`), cronómetro, validaciones, RTO y RPO (prompt preparado con Claude; un solo prompt, sin rondas de ajuste) | Script con destino fijo, elección del último respaldo por fecha, cronómetro, siete consultas de validación, RTO y RPO, más una lista de supuestos. **Avisó, sin tocar el archivo, que `backup_foodstore.ps1` línea 43 usa `$var:` sin llaves**; lo dijo después de que Mariano ya había visto el `ParserError` | Ocho preguntas (con Claude): sin hallazgos de seguridad. Análisis de sintaxis con PowerShell y prueba de rechazo con `-BaseDestino foodstore` (código 1, sin tocar ninguna base). La primera ejecución real encontró el error de la línea 152, que la lectura no vio |
| **Mariano** (no es un prompt): primera corrida de `restore_test.ps1` (11:14:12) | La base destino no existía; la línea 152 dio `InvokeMethodOnNull` por consola, el script siguió y terminó con `RESULTADO: OK` (RTO 5,51 s). El error no quedó en el log | **Corrección humana:** cambió a `$existeBase = ("$resultadoExiste".Trim() -eq "1")`, validó la sintaxis y repitió. Segunda corrida (11:16:42): eliminó la base existente con `dropdb`, sin errores, RTO 6,19 s |

Revisión cruzada (**Andrés**): según lo que dejó escrito, repitió el simulacro en su servidor con restauración exitosa,
conteos coincidentes y registros inválidos en cero. **No hay logs suyos adjuntos** que lo respalden.

## Parte 5 — Informe (Mariano)

| Prompt o pedido | Respuesta relevante recibida (resumida) | Validación o corrección humana aplicada |
|---|---|---|
| **Mariano · Claude:** armar `datos_para_informe.md` con las mediciones del simulacro y la transcripción del error de consola | Archivo con respaldo usado, dos corridas, RPO y RTO, validaciones, problemas, mejora propuesta y uso de OpenCode | Mariano comparó los valores contra `evidencias/` y quitó lo que no estaba respaldado por lo observado |
| **Mariano · Claude:** armar `informe_u6.pdf` de una página desde `datos_para_informe.md` y las salidas de monitoreo y mantenimiento | PDF de una página con respaldo, RPO y RTO, validaciones, problema real, mejora y tabla de asistencia con IA. Comprobado el largo (una página) y el diseño | Mariano lo lee y lo compara contra `datos_para_informe.md` y `evidencias/` antes de subirlo |

**Facundo:** sin registro propio en este TP. El informe y las partes de esta bitácora que le correspondían se elaboraron
a partir de los datos de Mariano.

## Mediciones (valores observados, no estimados)

| Dato | Valor | Cómo se midió | Quién |
|---|---|---|---|
| Conteos antes del respaldo | `categoria` 6, `usuario` 20.006, `producto` 50.016, `pedido` 200.006, `detalle_pedido` 400.013, `productos_invalidos` 0, `detalles_invalidos` 0 | `psql` sobre `foodstore`, `evidencias/conteos_antes.txt` (2026-10-18 09:35) | Mariano |
| Archivo de respaldo, tamaño y hora | Primer respaldo válido: `foodstore_20261018_094708.dump`, 10.650.048 bytes, SHA-256 `54F84A53664A84D3C25844BA60B5641FCB710A46F2E6CA0F43D0BD41BFB895FA`. Segundo (el del simulacro): `foodstore_20261018_094932.dump`, 10.650.048 bytes, 09:49:32 a 09:49:37, SHA-256 `9FF281D97A399EB7D8BFA583B4C83EEA30EDACF1DBCF3362278806E0178B55FB` | Log (`Tamano: 10650048 bytes`) y `dir .\backups` | Mariano |
| Prueba del respaldo, caso éxito | `RESULTADO: OK`, código de salida 0, `.dump` y `.dump.sha256` sin `.parcial`, `pg_restore --list` de 74 líneas | Consola y log | Mariano |
| Prueba del respaldo, caso error (`-Base foodstore_no_existe`) | `RESULTADO: ERROR - pg_dump fallo con codigo 1`, código 1, log con el `FATAL`, `backups\` sin `.parcial` | Consola, `dir .\backups` y log | Mariano |
| Conteos después de restaurar | Iguales a los de antes, con `productos_invalidos` y `detalles_invalidos` en 0 (comparación hecha por una persona) | `evidencias/restore_log_ok.txt` contra `conteos_antes.txt` | Mariano |
| RTO observado | Corrida oficial **6,19 s** (11:16:42 a 11:16:48). Primera corrida, con el error: 5,51 s | Cronómetro de `restore_test.ps1` desde antes de `createdb` hasta el fin de las validaciones | Mariano |
| Antigüedad del respaldo (RPO observado) | Corrida oficial **1,45 h (01:27:10)**. Primera corrida: 1,41 h | Inicio del simulacro menos hora de creación del respaldo (09:49:32) | Mariano |
| Rechazo del destino `foodstore` | `RESULTADO: ERROR - Base destino no permitida ('foodstore')`, código 1, sin tocar ninguna base | Consola y `evidencias/restore_log_rechazo.txt` | Mariano |
| Estado de `foodstore` (monitoreo) | 136 MB; `n_dead_tup` máximo 1; `n_mod_since_analyze` 0; autovacuum activo con umbral 50 y factor 0,2 | `evidencias/health_check_salida.txt` | Mariano |
| Estado de `foodstore` en el servidor de Andrés | 136 MB; `n_dead_tup` 0 en todas las tablas | `evidencias/health_check_salida_andres.txt` | Andrés |
| Ensayo de mantenimiento | `n_dead_tup` 0 → 50.015 → 0 (umbral 10.053,2); `last_vacuum` y `last_analyze` de la hora de la corrida | `evidencias/maintenance_salida.txt` | Mariano (ejecución), Andrés (script original) |

## Problemas encontrados y cómo se resolvieron

| Fecha | Quién | Problema | Causa | Solución |
|---|---|---|---|---|
| 2026-10-18 | Mariano | `psql -w` falló con `no password supplied` | No existía `pgpass.conf` | Crearlo en `%APPDATA%\postgresql\` con una línea `host:puerto:base:usuario:clave` |
| 2026-10-18 | Mariano | `backup_foodstore.ps1` no arrancó: `ParserError` en la línea 43 | OpenCode escribió `'$Servidor:$Puerto'`; PowerShell interpreta `$Servidor:` como una unidad | Reemplazar por `${Servidor}:${Puerto}`. No se ejecutó nada antes del arreglo: sin respaldo, log ni `.parcial` |
| 2026-10-18 | Mariano | `restore_test.ps1`, línea 152: `InvokeMethodOnNull` si la base destino no existe | `psql` no devolvió filas y el resultado quedó nulo (causa probable, no reproducida fuera del equipo). El error no aborta el script ni queda en el log | `$existeBase = ("$resultadoExiste".Trim() -eq "1")`; sintaxis validada y simulacro repetido sin errores |
| 2026-10-21 | Andrés | `pg_dump` falló con `fe_sendauth: no password supplied` | No existía `pgpass.conf` en su perfil | Crear el archivo en `%APPDATA%\postgresql\` con permisos seguros |
| 2026-10-21 | Andrés (detectado y corregido por Mariano) | La salida de `maintenance.sql` mostraba 0 tuplas muertas antes del `VACUUM` y 50.015 después | Las estadísticas de `pg_stat_user_tables` se actualizan con retraso (causa más probable; no se probó otra) | Pausas `pg_sleep(2)` y observación base. Corrida final: 0 → 50.015 → 0 |

## Decisiones tomadas

| Decisión | Alternativas | Por qué |
|---|---|---|
| Reparto inicial con la carga más pesada para Mariano (spec, respaldo, simulacro, README y bitácoras) | Un reparto parejo | Concentrar las partes que condicionan al resto |
| El reparto se ajustó durante el trabajo: Mariano hizo `health_check.sql` y el informe, y Andrés hizo `maintenance.sql` | Mantener el reparto original | Cada parte se cerró con quien podía ejecutarla, y quedó documentado quién hizo qué |
| Anotar los datos del simulacro en `Datos para Facundo/Parte de Mariano para el informe/datos_para_informe.md` | Repetir todo el simulacro para obtener los datos | Los valores solo salen de la ejecución de Mariano: el informe no estima nada |
| Cada integrante lleva su bitácora personal y se unifican al final | Un solo archivo compartido | Evitar conflictos al mergear |
| Commitear la spec y las partes de Mariano directo en `main` | Una rama por parte | Es la rama que usa y las demás partes parten de ahí |
| Guardar los conteos previos con `Out-File -Encoding ASCII` | Redirección con `>` | En PowerShell 5.1 `>` escribe UTF-16 |
| Dos corridas del simulacro, informando las dos (la primera con el error, la segunda oficial) | Informar solo la corrida limpia | El error de la línea 152 es un problema real encontrado por la ejecución |
| Mantener `restore_test.ps1` aunque la consigna lo marca como opcional | Restaurar a mano con los comandos de referencia | Hace repetible el simulacro, mide el RTO con un cronómetro único y se niega a actuar sobre `foodstore` |
| Ensayo de `VACUUM` en `foodstore_restore_test`, no sobre `foodstore` | Actuar sobre `foodstore` o no hacer ninguna acción | `foodstore` estaba limpia: ahí no había nada que justificar |
| No usar `VACUUM FULL` | Usar `VACUUM FULL` | Toma un bloqueo exclusivo que interrumpe la disponibilidad |
| Que Mariano completara `maintenance.sql`, la nota y las bitácoras que faltaban | Dejarlas sin evidencia válida | La salida original no respaldaba las afirmaciones y no había forma de corregirla con su autor |

## Qué haríamos distinto la próxima vez

- **Ejecutar antes de confiar en la revisión:** tres errores (el `ParserError`, la línea 152 y el retraso de estadísticas) los
  encontró la ejecución y no la lectura con la lista de ocho preguntas. Conviene ejecutar y leer la salida
  apenas hay una primera versión.
- **Leer la salida contra lo que se afirma:** la nota de mantenimiento decía algo que su propia salida contradecía.
- **Pedir evidencia adjunta en cada revisión cruzada**, para no tener afirmaciones que no se pueden comprobar.
- **Cerrar el reparto y las fechas de entrega al principio**, y revisar a mitad de camino si cada parte avanza.
- **Programar el respaldo** y probar la mejora propuesta (respaldar los roles con `pg_dumpall`), que quedó solo como propuesta.

## Historial de Git

Hasta el 2026-10-18 el historial tiene un commit por entregable de Mariano (estructura preliminar, `SPEC_U6`, evidencias y
simulacro, datos para el informe, ajustes), commiteados directo en `main`. Los commits posteriores (monitoreo, mantenimiento,
informe y bitácoras) se suman sobre esos. Mantener un commit por entregable y mensajes que digan qué se hizo.
