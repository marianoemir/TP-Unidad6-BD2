# Nota de Mantenimiento — Parte de Andrés

**Para:** Facundo  
**De:** Andrés  
**Fecha:** 2026-10-21  
**Repositorio:** TP-Unidad6-BD2  

---

## 1. Base de datos y fecha de ejecución
- **Base objetivo:** `foodstore_restore_test` (ensayo demostrativo en base descartable para no alterar la base de producción `foodstore`, la cual se encontraba 100% limpia)[cite: 1, 20].
- **Fecha y hora de ejecución:** 2026-10-21 (21:04hs aprox.)[cite: 21].
- **Evidencia:** `evidencias/maintenance_salida.txt`[cite: 1, 21].

---

## 2. Observación previa (Monitoreo sobre servidor propio)
- **Estado inicial de la base principal (`foodstore`):**
  - `n_live_tup`: 50.016 en `producto`, 400.013 en `detalle_pedido`, 200.006 en `pedido`[cite: 19].
  - `n_dead_tup`: 0 en todas las tablas[cite: 19].
  - `n_mod_since_analyze`: 0 en todas las tablas[cite: 19].
  - `last_autovacuum` / `last_autoanalyze`: Ejecutados previamente de forma automática durante la carga[cite: 19].
- **Evidencia:** `evidencias/health_check_salida_andres.txt`[cite: 1, 19].

---

## 3. Parámetros de Autovacuum
- **Parámetros observados:**
  - `autovacuum_vacuum_threshold`: 50[cite: 19].
  - `autovacuum_vacuum_scale_factor`: 0.2 (20%)[cite: 19].
- **Umbral teórico calculado para `producto`:**
  $$\text{Umbral} = 50 + (0.2 \times 50.016) = 10.053,2 \text{ tuplas muertas}$$
[cite: 1, 19, 21].
- **Evidencia:** `evidencias/health_check_salida_andres.txt`[cite: 1, 19].

---

## 4. Acción elegida y justificación
- **Acción:** Generación controlada de 50.015 tuplas muertas mediante un `UPDATE` masivo seguro (`UPDATE producto SET precio = precio WHERE eliminado = FALSE;`) seguido de un **`VACUUM (ANALYZE, VERBOSE) producto;`** en la base descartable `foodstore_restore_test`[cite: 1, 20, 21].
- **Justificación:** 
  - La base de producción estaba 100% limpia (`n_dead_tup = 0`), por lo que realizar un `VACUUM` en `foodstore` no estaba técnicamente justificado[cite: 1, 19].
  - Se realizó un ensayo en `foodstore_restore_test` donde las 50.015 tuplas muertas superaron ampliamente el umbral del autovacuum (10.053,2), justificando la ejecución del `VACUUM`[cite: 1, 21].
  - **No se utilizó `VACUUM FULL`** para evitar el bloqueo exclusivo (`AccessExclusiveLock`) que degrada la disponibilidad del servicio en entornos de producción[cite: 1, 20].
- **Evidencia:** `maintenance.sql` y `evidencias/maintenance_salida.txt`[cite: 1, 20, 21].

---

## 5. Resultado obtenido
- **Efecto de la acción (`maintenance_salida.txt`):**
  - `UPDATE` generó 50.015 modificaciones en la tabla `producto`[cite: 21].
  - `VACUUM (ANALYZE)` procesó la tabla, actualizó marcas de tiempo de `last_vacuum` y `last_analyze` (2026-10-21 21:04:54) y recalculó las estadísticas para el optimizador[cite: 20, 21].
- **Evidencia:** `evidencias/maintenance_salida.txt`[cite: 1, 21].

---

## 6. Problema real encontrado
- **Incidente:** Al intentar ejecutar el respaldo automatizado (`backup_foodstore.ps1`), `pg_dump` falló con código de salida 1 por error de autenticación (`fe_sendauth: no password supplied`)[cite: 3].
- **Causa:** Falta del archivo de configuración de credenciales `pgpass.conf` en la carpeta `%APPDATA%\postgresql\` del entorno local[cite: 1, 3].
- **Solución:** Se creó el archivo `pgpass.conf` con las credenciales correspondientes y permisos restringidos para el usuario local, logrando la ejecución exitosa del respaldo (`RESULTADO: OK`).

---

## 7. Uso de IA / OpenCode
- **Asistencia:** Se utilizó OpenCode para estructurar el script `maintenance.sql` siguiendo las pautas de `SPEC_U6.md` y `AGENTS.md`.
- **Prompt utilizado:** Solicitud de estructura en 4 fases (generación de tuplas muertas en base descartable, observación previa con cálculo explícito de umbral, ejecución de `VACUUM (ANALYZE)` sin transacciones y observación posterior).
- **Verificación humana:** Se aplicó la lista de verificación de 8 preguntas de `AGENTS.md`. Se constató la ausencia de `BEGIN/COMMIT` (ya que `VACUUM` no corre dentro de un bloque transaccional), se verificó el uso de la base de prueba `foodstore_restore_test` y se confirmó la salida mediante ejecución por consola con `psql`[cite: 1, 20, 21].