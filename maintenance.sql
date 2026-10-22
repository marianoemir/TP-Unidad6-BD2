-- ===================================================================
-- maintenance.sql - Revision de mantenimiento semanal (Unidad 6)
-- Proyecto: Food Store - Base de Datos II
-- Motor: PostgreSQL 17
--
-- BASE OBJETIVO: foodstore_restore_test (base descartable para ensayos).
-- Nunca ejecutar contra la base de produccion 'foodstore'.
--
-- RESTRICCION: Este script NO usa BEGIN/COMMIT. VACUUM no puede
-- ejecutarse dentro de un bloque transaccional. Cada sentencia se
-- ejecuta en autocombito (autocommit).
-- ===================================================================

\set ON_ERROR_STOP on

\connect foodstore_restore_test

-- ===================================================================
-- FASE 1: Generacion de tuplas muertas de prueba (ensayo seguro)
-- ===================================================================
-- Se genera una actualizacion masiva sin cambios reales sobre la tabla
-- producto para crear tuplas muertas (dead tuples) en la base descartable.
-- La cláusula WHERE eliminado = FALSE respeta el borrado logico del TP.
UPDATE producto SET precio = precio WHERE eliminado = FALSE;

-- ===================================================================
-- FASE 2: Observacion previa - estado de la tabla producto
-- ===================================================================
-- Se consulta pg_stat_user_tables para ver el estado de tuplas y las
-- marcas de tiempo de vaciado/analisis previo.
-- Se calcula explicitamente el umbral teorico de autovacuum:
--   umbral = autovacuum_vacuum_threshold + autovacuum_vacuum_scale_factor * n_live_tup
-- Valores por defecto del motor: threshold = 50, scale_factor = 0.2.
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
-- FASE 3: Accion segura y justificada - VACUUM (ANALYZE, VERBOSE)
-- ===================================================================
-- Se ejecuta VACUUM con ANALYZE y VERBOSE sobre producto.
--
-- Por qué NO se usa VACUUM FULL:
--   - VACUUM FULL reescribe la tabla completa y toma un bloqueo
--     exclusivo (AccessExclusiveLock), bloqueando lecturas y escrituras
--     durante toda la operacion. En produccion afecta la disponibilidad
--     del servicio y no es adecuado como mantenimiento periodico.
--   - VACUUM (sin FULL) solo requiere un bloqueo SHARE UPDATE EXCLUSIVE,
--     que permite consultas concurrentes y es seguro para entornos en
--     produccion.
--   - ANALYZE actualiza las estadísticas del planificador (no elimina
--     tuplas muertas; eso lo hace VACUUM).
VACUUM (ANALYZE, VERBOSE) producto;

-- ===================================================================
-- FASE 4: Observacion posterior - verificacion de limpieza
-- ===================================================================
-- Se repite la consulta para confirmar que n_dead_tup regreso a 0 y que
-- las marcas de mantenimiento manual / estadísticas se actualizaron.
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
