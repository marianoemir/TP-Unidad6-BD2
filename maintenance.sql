-- ===================================================================
-- maintenance.sql - Revision de mantenimiento semanal (Unidad 6)
-- Proyecto: Food Store - Base de Datos II
-- Motor: PostgreSQL 16 o superior
--
-- BASE OBJETIVO: foodstore_restore_test (base descartable para ensayos).
-- Nunca ejecutar este ensayo contra la base 'foodstore'.
--
-- RESTRICCION: este script NO usa BEGIN/COMMIT. VACUUM no puede
-- ejecutarse dentro de un bloque transaccional. Cada sentencia se
-- ejecuta en autocommit.
--
-- Como se ejecuta (PowerShell, desde la raiz del repo). Se usa psql -f
-- y no el Query Tool de pgAdmin:
--   & "C:\Program Files\PostgreSQL\17\bin\psql.exe" -h localhost -U postgres -d foodstore_restore_test -w -f .\maintenance.sql -o .\evidencias\maintenance_salida.txt
--
-- Por que hay pausas (pg_sleep): las estadisticas de pg_stat_user_tables
-- se actualizan con un pequeno retraso. Sin la pausa, la consulta de
-- observacion puede mostrar el estado anterior a la accion (en una
-- corrida anterior se vio n_dead_tup = 0 despues del UPDATE y 50015
-- despues del VACUUM, al reves de lo esperado).
-- ===================================================================

\set ON_ERROR_STOP on

\connect foodstore_restore_test

-- ===================================================================
-- FASE 1: Observacion base (antes de generar tuplas muertas)
-- ===================================================================
-- Umbral teorico de autovacuum:
--   umbral = autovacuum_vacuum_threshold + autovacuum_vacuum_scale_factor * n_live_tup
-- Valores por defecto del motor: threshold = 50, scale_factor = 0.2.
SELECT 'FASE 1 - Observacion base' AS fase;

SELECT
    relname                                         AS tabla,
    n_live_tup,
    n_dead_tup,
    n_mod_since_analyze,
    last_vacuum,
    last_autovacuum,
    last_analyze,
    last_autoanalyze,
    current_setting('autovacuum_vacuum_threshold')::int
      + current_setting('autovacuum_vacuum_scale_factor')::numeric * n_live_tup
      AS umbral_autovacuum_teorico
FROM pg_stat_user_tables
WHERE relname = 'producto';

-- ===================================================================
-- FASE 2: Generacion de tuplas muertas de prueba (ensayo seguro)
-- ===================================================================
-- Actualizacion masiva sin cambios reales de valores sobre la tabla
-- producto, para crear tuplas muertas en la base descartable. Es un
-- ENSAYO, no mantenimiento real: la base 'foodstore' no se toca.
-- La clausula WHERE eliminado = FALSE respeta el borrado logico del TP.
UPDATE producto SET precio = precio WHERE eliminado = FALSE;

-- Pausa para que las estadisticas reflejen el UPDATE.
SELECT pg_sleep(2);

-- ===================================================================
-- FASE 3: Observacion previa a la accion (con tuplas muertas)
-- ===================================================================
-- Se espera n_dead_tup muy por encima del umbral teorico.
SELECT 'FASE 3 - Observacion previa a la accion' AS fase;

SELECT
    relname                                         AS tabla,
    n_live_tup,
    n_dead_tup,
    n_mod_since_analyze,
    last_vacuum,
    last_autovacuum,
    last_analyze,
    last_autoanalyze,
    current_setting('autovacuum_vacuum_threshold')::int
      + current_setting('autovacuum_vacuum_scale_factor')::numeric * n_live_tup
      AS umbral_autovacuum_teorico
FROM pg_stat_user_tables
WHERE relname = 'producto';

-- ===================================================================
-- FASE 4: Accion segura y justificada - VACUUM (ANALYZE)
-- ===================================================================
-- Se ejecuta VACUUM con ANALYZE sobre producto.
--
-- Por que NO se usa VACUUM FULL:
--   - VACUUM FULL reescribe la tabla completa y toma un bloqueo
--     exclusivo (ACCESS EXCLUSIVE) que bloquea lecturas y escrituras
--     durante toda la operacion. No es adecuado como mantenimiento
--     periodico.
--   - VACUUM comun solo requiere un bloqueo SHARE UPDATE EXCLUSIVE,
--     que permite consultas concurrentes.
--   - ANALYZE actualiza las estadisticas del planificador; no elimina
--     tuplas muertas (eso lo hace VACUUM).
VACUUM (ANALYZE) producto;

-- Pausa para que las estadisticas reflejen el VACUUM.
SELECT pg_sleep(2);

-- ===================================================================
-- FASE 5: Observacion posterior - verificacion de limpieza
-- ===================================================================
-- Se espera n_dead_tup cerca de 0 y last_vacuum / last_analyze con la
-- hora de esta corrida.
SELECT 'FASE 5 - Observacion posterior' AS fase;

SELECT
    relname                                         AS tabla,
    n_live_tup,
    n_dead_tup,
    n_mod_since_analyze,
    last_vacuum,
    last_autovacuum,
    last_analyze,
    last_autoanalyze,
    current_setting('autovacuum_vacuum_threshold')::int
      + current_setting('autovacuum_vacuum_scale_factor')::numeric * n_live_tup
      AS umbral_autovacuum_teorico
FROM pg_stat_user_tables
WHERE relname = 'producto';
