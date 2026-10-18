# División de trabajo — TP Unidad 6 (Food Store)

Mantenimiento, respaldo y recuperación. Equipo de tres integrantes. Este documento dice **quién hace qué,
quién depende de quién y en qué orden** se avanza. Se actualiza si el reparto cambia.

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

- Una rama por parte: `parte-1-spec`, `parte-2-respaldo`, `parte-3a-health-check`, `parte-3b-maintenance`,
  `parte-4-simulacro`, `parte-5-informe`. **Mariano también trabaja en rama**, no directo sobre `main`.
- Se mergea por Pull Request. **Primero entra `parte-1-spec`**; las demás se crean a partir de `main` ya con
  la spec incorporada.
- Mensajes de commit descriptivos: `feat(respaldo): ...`, `feat(monitoreo): ...`,
  `feat(mantenimiento): ...`, `docs(informe): ...`. Un commit por entregable, y los arreglos con un mensaje
  que diga qué se arregló.
- Sin contraseñas, respaldos ni logs sin revisar en ningún commit.

## 8. Bitácora

Aunque la consigna no la pide, la llevamos para poder volver a ver qué hicimos y por qué.

- **Cada integrante arma la suya**, en `bitacoras/bitacora_<nombre>.md`, a partir de
  `bitacoras/PLANTILLA_bitacora.md`. Al ser archivos separados no hay conflictos al mergear.
- **Al final, Mariano las unifica** en `BITACORA.md`, comparando cada fila contra la evidencia del repo.
- Se anota lo que realmente pasó, incluidos los casos en que OpenCode **no** se equivocó. Las respuestas se
  resumen; nunca se anotan contraseñas.
