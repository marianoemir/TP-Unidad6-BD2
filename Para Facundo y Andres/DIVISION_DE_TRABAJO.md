# División de trabajo — TP Unidad 6 (Food Store)

Mantenimiento, respaldo y recuperación. Equipo de tres integrantes. Este documento dice **quién hace qué,
quién depende de quién y en qué orden** se avanza. Se actualiza si el reparto cambia.

## 0. Estado al 2026-10-18 y qué falta (leer esto primero)

Mariano terminó su parte de producción. **Para que pueda cerrar el trabajo le faltan cosas de Andrés y de Facundo**:
sin los dos SQL no puede hacer la corrida oficial, y sin las bitácoras no puede unificar. Lo que figura como hecho
tiene evidencia en el repo. A esta fecha **no hay** `health_check.sql`, `maintenance.sql` ni `informe_u6.pdf`; si ya
avanzaron, avisen y actualicen esta tabla.

| Tarea | Responsable | Estado |
|---|---|---|
| H0 entorno | Mariano | Hecho (`pgpass.conf` y `foodstore` con volumen: `evidencias/conteos_antes.txt`) |
| H1 `SPEC_U6.md` | Mariano | Hecho |
| H2 `backup_foodstore.ps1` | Mariano | Hecho y probado (caso éxito y caso error) |
| H3a `health_check.sql` | **Andrés** | **Falta** |
| H3b `maintenance.sql` | **Facundo** | **Falta** (necesita la salida de H3a) |
| H4 simulacro (`restore_test.ps1`) | Mariano | Hecho: dos corridas, la oficial con RTO 6,19 s y RPO 1,45 h |
| Datos para el informe | Mariano | Hecho: `Datos para Facundo/Parte de Mariano para el informe/datos_para_informe.md` |
| H5 revisión cruzada | Los tres | **Falta** (ver abajo quién revisa qué) |
| H6 `informe_u6.pdf` | **Facundo** | **Falta** (necesita H3a y H3b) |
| H6 `README.md` | Mariano | Hecho |
| H6 bitácoras y `BITACORA.md` unificada | Los tres / Mariano | **Falta**: Andrés y Facundo entregan la suya; Mariano unifica |
| Corrida oficial de punta a punta | Mariano | **Falta**: necesita H3a y H3b en `main` |

### Orden para avanzar (lo que bloquea a quién)

1. **Andrés** hace `health_check.sql` y le pasa la salida a Facundo. Es lo que desbloquea todo lo demás.
2. **Facundo** hace `maintenance.sql` con esa salida como observación previa.
3. **Mariano** (cuando los dos SQL estén en `main`) hace la corrida oficial y revisa `maintenance.sql`.
4. **Facundo** arma `informe_u6.pdf` con los datos reales y **Andrés** lo revisa.
5. Los tres entregan su bitácora y **Mariano** unifica `BITACORA.md`.

Mientras Andrés trabaja, Facundo puede adelantar el entorno, la bitácora, la revisión cruzada del simulacro y
la estructura del informe. Y Andrés, la revisión cruzada del respaldo.

### Lo que Mariano ya dejó listo para usar

- `SPEC_U6.md` y `AGENTS.md` (con la lista de ocho preguntas para revisar código generado por IA).
- `backup_foodstore.ps1` y `restore_test.ps1`, con sus pruebas en `evidencias/`.
- `Datos para Facundo/Parte de Mariano para el informe/datos_para_informe.md`: todos los valores del simulacro (respaldo
  usado, dos corridas, RPO y RTO, validaciones, los dos problemas reales, la mejora propuesta, uso de OpenCode). **El
  informe se arma desde ahí; no se inventa ningún valor.** Las filas de `health_check.sql` y `maintenance.sql` de la
  tabla de OpenCode (sección 7) las completan Andrés y Facundo con lo que anotaron en su bitácora.
- `Para Facundo y Andres/PLANTILLA_bitacora.md` para la bitácora personal.

### Andrés: qué tiene que hacer, paso a paso

1. **Entorno (H0), si no lo hizo:** `foodstore` con datos y `pgpass.conf` funcionando (sección 4). Anotar los conteos
   en su bitácora.
2. **`health_check.sql`**, en la raíz del repo, partiendo de las cuatro consultas de la consigna. Requisitos:
   - Mínimo cuatro controles: tamaño de la base, actividad de conexiones, **estado de tablas** y consultas activas.
   - En el estado de tablas, mostrar `n_live_tup`, `n_dead_tup`, **`n_mod_since_analyze`**, `last_autovacuum` y
     `last_autoanalyze` (la spec y el mantenimiento se apoyan en esas columnas).
   - En consultas activas, **no contar la propia sesión** (`pid <> pg_backend_pid()`).
   - Solo lectura; tiene que correr en PostgreSQL 16+. Sin contraseñas ni datos personales.
   - Puede generarlo con OpenCode a partir de `SPEC_U6.md` y `AGENTS.md`. **Se revisa con la lista de ocho preguntas
     y se ejecuta antes de aceptarlo.** Anotar en la bitácora qué se pidió, qué devolvió y qué corrigió.
3. **Ejecutarlo y guardar la salida.** Desde la raíz del repo, en PowerShell (copiar solo el comando):
   `& "C:\Program Files\PostgreSQL\17\bin\psql.exe" -h localhost -U postgres -d foodstore -w -f .\health_check.sql -o .\evidencias\health_check_salida.txt`
   Usar `-o` evita que PowerShell 5.1 guarde el archivo en UTF-16. Revisar que el archivo muestre los cuatro controles.
4. **Entregar a Facundo** la salida del control de estado de tablas (`evidencias/health_check_salida.txt`): es la
   observación previa de `maintenance.sql`. Avisarle apenas esté subida.
5. **Revisión cruzada del respaldo:** correr `backup_foodstore.ps1` en **su** servidor y comprobar que no depende de
   nada de la máquina de Mariano (rutas, usuario, clave), que genera el `.dump` y el log, y que termina con código 0.
   Aplicar la lista de ocho preguntas de `AGENTS.md`. Registrar en la bitácora qué revisó y qué encontró (si no encontró
   nada, también se anota). Si encuentra un problema, avisarle a Mariano: no se cambia el script sin avisar.
6. **Revisión del informe** cuando Facundo lo tenga: cada valor del informe tiene que tener su evidencia en
   `evidencias/` o en `datos_para_informe.md`, y el informe tiene que diferenciar RPO de RTO.
7. **Bitácora:** `bitacoras/bitacora_andres.md`, desde `Para Facundo y Andres/PLANTILLA_bitacora.md`.
8. **Git:** rama `parte-3a-health-check`, commits descriptivos (`feat(monitoreo): ...`), Pull Request a `main`.
   Subir `health_check.sql`, `evidencias/health_check_salida.txt` y la bitácora.

### Facundo: qué tiene que hacer, paso a paso

1. **Entorno (H0), si no lo hizo**, y anotar los conteos en su bitácora.
2. **`maintenance.sql`**, en la raíz del repo, **cuando tenga la salida de Andrés** (o corriendo a mano la misma consulta
   de estado de tablas). Requisitos:
   - **Observación previa:** estado de las tablas (`n_dead_tup`, `n_mod_since_analyze`, `last_autovacuum`,
     `last_autoanalyze`) y configuración de autovacuum.
   - **Una acción segura y justificada por lo observado.** La justificación tiene que corresponder a la acción:
     `ANALYZE` actualiza estadísticas; `VACUUM` elimina tuplas muertas. `ANALYZE` **no** limpia tuplas muertas.
   - **Sin `VACUUM FULL`** (bloqueo exclusivo; no es mantenimiento periódico). Si hace falta, `VACUUM (ANALYZE)` común.
   - **Observación posterior** a la acción, para mostrar el efecto.
   - `VACUUM` **no corre dentro de una transacción**, y pgAdmin manda el script como una sola sentencia: **ejecutarlo
     con `psql -f`**, no con el Query Tool.
   - Se revisa con la lista de ocho preguntas de `AGENTS.md` y se ejecuta antes de aceptarlo (si lo genera OpenCode).
3. **Ejecutarlo y guardar la salida** (antes, acción, después), desde la raíz del repo:
   `& "C:\Program Files\PostgreSQL\17\bin\psql.exe" -h localhost -U postgres -d foodstore -w -f .\maintenance.sql -o .\evidencias\maintenance_salida.txt`
4. **Revisión cruzada del simulacro:** en **su** servidor, correr primero `backup_foodstore.ps1` (para tener un `.dump`
   propio) y después `restore_test.ps1`. Comparar contra `evidencias/restore_log_ok.txt`: conteos que coincidan con
   los previos de **su** base, `productos_invalidos` y `detalles_invalidos` en 0 y RTO/RPO registrados. Anotar qué
   revisó y qué encontró. Si algo falla, avisarle a Mariano.
5. **`informe_u6.pdf`** (una página como máximo), cuando estén H3a y H3b, a partir de `datos_para_informe.md` y de las
   salidas de los dos SQL. Tiene que incluir:
   - fecha y hora del respaldo usado (2026-10-18 09:49:32, `foodstore_20261018_094932.dump`);
   - tiempo total de restauración y validación (RTO observado) y RPO observado, **diferenciados**, junto con los
     **previstos** (RPO hasta 24 h, RTO menos de 20 min);
   - resultado de las validaciones de tablas y de las restricciones lógicas;
   - **un problema real** encontrado (hubo dos: línea 43 del respaldo y línea 152 de la restauración);
   - **una mejora concreta** (respaldar roles con `pg_dumpall --globals-only --no-role-passwords`);
   - qué parte asistió OpenCode y cómo se verificó antes de aceptarla;
   - la aclaración de que la consigna dice `cliente` y en esta base la tabla se llama `usuario`;
   - cuando se hicieron dos corridas del simulacro, informar las dos y marcar la oficial.
   No inventar valores: los que no estén en las evidencias, no van. Entregarlo como PDF.
6. **Bitácora:** `bitacoras/bitacora_facundo.md`, desde la plantilla.
7. **Git:** ramas `parte-3b-maintenance` y `parte-5-informe`, commits descriptivos (`feat(mantenimiento): ...`,
   `docs(informe): ...`), Pull Request a `main`. Subir `maintenance.sql`, `evidencias/maintenance_salida.txt`,
   `informe_u6.pdf` y la bitácora.

### Mariano: lo que queda (depende de los otros dos)

1. **Corrida oficial de punta a punta** en su servidor, con `health_check.sql` y `maintenance.sql` ya en `main`.
2. **Revisión cruzada de `maintenance.sql`**: correrlo y validar que la acción esté justificada por lo observado.
3. **Unificar `BITACORA.md`**, comparando cada fila contra la evidencia, cuando lleguen las bitácoras de Andrés y Facundo.
4. **Revisión final del repo antes de entregar:** sin contraseñas, sin `.dump` ni logs sin revisar, informe en PDF,
   todos los entregables en `main`.

### Reglas que valen para los dos

- Sin contraseñas en ningún archivo ni commit. `pgpass.conf` queda fuera del repo.
- `foodstore` solo se lee; las pruebas destructivas van solo en `foodstore_restore_test`.
- El código de OpenCode se revisa y se ejecuta antes de aceptarse; en la bitácora se anota lo que realmente pasó,
  incluso si OpenCode no se equivocó.
- No abrir ni pegar `backups/*.dump` en ninguna IA.

## 1. Reparto

| Integrante | A su cargo | Peso en la nota | Carga |
|---|---|---|---|
| **Mariano Chirino** | `SPEC_U6.md` (Parte 1), `backup_foodstore.ps1` (Parte 2), **simulacro contra reloj** con RTO y RPO (Parte 4), `README.md`, la corrida oficial y la **unificación de las bitácoras** | 2,0 + 2,0 + 3,0 = **7,0** | **Alta** |
| **Andrés** | **`health_check.sql`** (mitad de la Parte 3) y la revisión cruzada del respaldo | ~1,0 | Media |
| **Facundo** | **`maintenance.sql`** (mitad de la Parte 3) y **`informe_u6.pdf`** (Parte 5) | 1,0 + 1,0 = **2,0** | Media |

- La Parte 3 se divide: Andrés hace el monitoreo y Facundo el mantenimiento. Si prefieren cambiar, se
  intercambian y se actualiza esta tabla.
- Mariano concentra las partes que más pesan (spec, respaldo y restauración medida) porque condicionan al
  resto: sin spec no se generan los scripts, sin respaldo no hay simulacro y sin simulacro no hay informe.
- La spec y el README los arma Mariano (con asistencia de Claude); los otros dos no tienen que escribirlos.

## 2. Matriz de dependencias

| # | Tarea | Responsable | Necesita de… | Bloquea a… |
|---|---|---|---|---|
| H0 | Entorno propio listo (sección 4) | **Los tres, cada uno en su servidor** | — | Todo lo demás |
| H1 | `SPEC_U6.md` aprobado | **Mariano** | H0 | H2, H3a y H3b (OpenCode genera los scripts a partir de la spec y de `AGENTS.md`) |
| H2 | `backup_foodstore.ps1` probado, un `.dump`, log y conteos previos | **Mariano** | H1 | H4 y la revisión de Andrés |
| H3a | `health_check.sql` probado | **Andrés** | H1 | H3b (su control del estado de las tablas es la "observación previa" del mantenimiento) y el informe |
| H3b | `maintenance.sql` probado y justificado | **Facundo** | H1 y **H3a** | El informe |
| H4 | Simulacro: restauración, validaciones, RTO y RPO (`restore_test.ps1` opcional) | **Mariano** | **H2** | El informe |
| H5 | Corrida oficial y revisión cruzada | **Los tres** | H2, H3a, H3b y H4 | H6 |
| H6 | `informe_u6.pdf`, `README.md`, bitácora unificada y entrega | **Facundo** (informe), **Mariano** (README y bitácora) | **H4**, H3a, H3b y H5 | — |

```
H0 entorno (los 3)
  └─> H1 SPEC (Mariano) ──┬─> H2 respaldo (Mariano) ──> H4 simulacro (Mariano) ──────────┐
                          ├─> H3a health_check (Andrés) ──┬──────────────────────────────┤
                          └───────────────────────────────┴─> H3b maintenance (Facundo) ─┼─> H5 revisión ─> H6 informe (Facundo)
                                                                                         │                  README + bitácora (Mariano)
```

- **H2 y H3a son independientes:** Mariano y Andrés avanzan en paralelo una vez aprobada la spec.
- **H3b depende de H3a:** el mantenimiento se justifica con lo que muestra el control del estado de tablas
  (`n_dead_tup`, `n_mod_since_analyze`, `last_autovacuum`, `last_autoanalyze`). Facundo puede empezar corriendo
  esa misma consulta a mano, pero el `maintenance.sql` final cita el `health_check.sql` de Andrés.
- **H4 depende solo de H2.** No hace falta esperar a los otros dos para restaurar.
- **El informe (H6) es lo último y depende de dos personas:** de Mariano (RTO, RPO, validaciones, problema real)
  y de Andrés y Facundo (evidencias de monitoreo y mantenimiento). Facundo puede dejar la estructura armada
  antes, pero los valores salen de las ejecuciones reales.

## 3. Qué se entrega de uno a otro (puntos de traspaso)

| De | A | Qué | Dónde queda |
|---|---|---|---|
| Mariano | Andrés y Facundo | `SPEC_U6.md` final: carpetas, nombres, condición de éxito, RPO y RTO previstos | raíz del repo |
| Mariano | Andrés y Facundo | Respaldo generado: nombre, tamaño, log y SHA-256; conteos **antes** del respaldo | `evidencias/` (el `.dump` no se versiona) |
| Andrés | Facundo | `health_check.sql` y su salida, en especial el control del estado de tablas | `health_check.sql` y `evidencias/` |
| Facundo | Mariano y Andrés | `maintenance.sql`: observación previa, acción, observación posterior y justificación | `maintenance.sql` y `evidencias/` |
| Mariano | Facundo | Tiempos del simulacro, antigüedad del respaldo, validaciones, problema real y mejora | `evidencias/` y su bitácora |
| Los tres | Mariano | Su bitácora personal, para unificarla | `bitacoras/` |

## 4. Armado del entorno (H0): lo hace cada uno en su propio servidor

Cada integrante crea la base de cero en pgAdmin 4, en este orden:

1. Crear la base `plantilla_food_store`. En su Query Tool ejecutar, **uno por vez y en este orden**:
   `base_heredada/schema.sql` → `base_heredada/objects.sql` → `base_heredada/data.sql`.
2. Desconectar la plantilla (nadie puede estar conectado a ella) y crear la base **`foodstore`** con
   *Template* = `plantilla_food_store`.
3. En `foodstore`, ejecutar en orden: `carga_masiva.sql` → `indices_semana3.sql` → `indices.sql` →
   `views.sql` → `materializadas.sql`.
4. Crear `pgpass.conf` en `%APPDATA%\postgresql\` con la línea `localhost:5432:*:postgres:<clave>`.
   **Ese archivo no va al repo** (el `.gitignore` ya lo excluye) y la clave no se escribe en ningún otro lado.
5. Comprobar que la base tiene volumen (sin volumen el RTO no significa nada) y anotar los conteos en la
   bitácora personal: `usuario` ronda las 20.000 filas, `producto` supera las 50.000 y `pedido` las 200.000.

Hito H0 cumplido cuando los tres tienen `foodstore` con datos y `pgpass.conf` funcionando
(`psql -h localhost -U postgres -d foodstore -w -c "SELECT 1"` responde sin pedir clave).

## 5. Qué hace cada uno, en detalle

### Mariano — spec, respaldo, simulacro, README e integración (carga alta)

1. **`SPEC_U6.md`** (una página como máximo): qué se automatiza, frecuencia, condición exacta de éxito de cada
   tarea, RPO y RTO previstos (24 h y menos de 20 min) y reglas de seguridad. **Es lo primero:** sin ella los
   otros dos no pueden pedirle nada a OpenCode.
2. **Respaldo:** con OpenCode, `backup_foodstore.ps1` a partir de la spec y de `AGENTS.md`. Lo revisa línea
   por línea (lista de revisión de `AGENTS.md`), lo ejecuta a mano y guarda las evidencias: archivo, tamaño, log.
3. **Conteos previos:** corre la validación sobre `foodstore` y los guarda en `evidencias/conteos_antes.txt`
   **antes** de respaldar.
4. **Simulacro:** restaura el último respaldo en `foodstore_restore_test` con el cronómetro, valida y calcula
   RTO y la antigüedad del respaldo (RPO observado). Opcional: `restore_test.ps1`.
5. **Corrida oficial:** al final, ejecuta una sola vez todo el procedimiento (respaldo, `health_check.sql`,
   `maintenance.sql`, restauración medida) para que el informe hable de una única base y de una única ejecución.
6. **Mejora a documentar:** respaldo de roles con `pg_dumpall --globals-only --no-role-passwords`, que
   `pg_dump` no incluye.
7. **`README.md`** final y **unificación de las bitácoras** (sección 8).

### Andrés — `health_check.sql` y revisión (carga media)

1. **`health_check.sql`:** al menos cuatro controles (tamaño, conexiones, estado de tablas, consultas
   activas). Solo lectura, ejecutable en PostgreSQL 16+, y sin contar su propia sesión entre las consultas activas.
2. **Entrega a Facundo:** la salida del control de estado de tablas, que es la observación previa que
   necesita `maintenance.sql`.
3. **Revisión cruzada de H2:** ejecuta `backup_foodstore.ps1` en **su** servidor y verifica que no dependa de
   nada de la máquina de Mariano (rutas, usuario, clave). Aplica la lista de revisión de `AGENTS.md`.

### Facundo — `maintenance.sql` e informe (carga media)

1. **`maintenance.sql`:** revisión de autovacuum y `ANALYZE`, y **una acción justificada** por lo observado.
   La justificación tiene que corresponder a la acción: `ANALYZE` actualiza estadísticas y `VACUUM` elimina
   tuplas muertas. Sin `VACUUM FULL`. Recordar que `VACUUM` no corre dentro de un bloque de transacción.
2. **Evidencia:** observación antes de la acción, la acción y observación después, en su servidor.
3. **`informe_u6.pdf`** (una página como máximo), con los valores reales de las ejecuciones: lo arma cuando
   H4 termina. Tiene que diferenciar RPO de RTO y registrar valores observados.
4. **Revisión cruzada de H4:** ejecuta el procedimiento de restauración en **su** servidor con su propio
   respaldo y confirma que funciona fuera de la máquina de Mariano.

## 6. Revisión cruzada

| Se revisa | Lo revisa | Cómo |
|---|---|---|
| `SPEC_U6.md` | Andrés y Facundo | Que sea implementable y que las condiciones de éxito se puedan comprobar |
| `backup_foodstore.ps1` | Andrés | Lo corre en su servidor y aplica la lista de revisión de `AGENTS.md` |
| `health_check.sql` | Facundo | Lo corre en su servidor y confirma que sirve como observación previa |
| `maintenance.sql` | Mariano | Lo corre y valida que la acción esté justificada por lo observado |
| Simulacro y `restore_test.ps1` | Facundo | Lo repite en su servidor y compara contra la evidencia |
| `informe_u6.pdf` | Andrés | Que cada valor del informe tenga evidencia en `evidencias/` |

Cada revisor registra en su bitácora qué revisó y qué encontró. Si no encontró nada, también se anota.

## 7. Trabajo con Git

- Una rama por parte: `parte-3a-health-check`, `parte-3b-maintenance`, `parte-5-informe` (Andrés y Facundo).
  **Mariano decidió commitear sus partes (spec, respaldo, simulacro) directo en `main`**, que es la que usa.
- Se mergea por Pull Request a `main`. La spec ya está en `main`: las ramas de Andrés y Facundo se crean a partir de ahí.
- Mensajes de commit descriptivos: `feat(respaldo): ...`, `feat(monitoreo): ...`,
  `feat(mantenimiento): ...`, `docs(informe): ...`. Un commit por entregable, y los arreglos con un mensaje
  que diga qué se arregló.
- Sin contraseñas, respaldos ni logs sin revisar en ningún commit.

## 8. Bitácora

Aunque la consigna no la pide, la llevamos para poder volver a ver qué hicimos y por qué.

- **Cada integrante arma la suya**, en `bitacoras/bitacora_<nombre>.md`, a partir de
  `Para Facundo y Andres/PLANTILLA_bitacora.md`. Al ser archivos separados no hay conflictos al mergear.
- **Al final, Mariano las unifica** en `BITACORA.md`, comparando cada fila contra la evidencia del repo.
- Se anota lo que realmente pasó, incluidos los casos en que OpenCode **no** se equivocó. Las respuestas se
  resumen; nunca se anotan contraseñas.
