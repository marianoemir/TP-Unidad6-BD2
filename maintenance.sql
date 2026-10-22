-- ===================================================================
-- maintenance.sql - Revision de mantenimiento semanal (Unidad 6)
-- Proyecto: Food Store - Base de Datos II
-- Motor: PostgreSQL 16 o superior
--
-- QUE HACE ESTE SCRIPT
--   FASE 0 (solo lectura, base 'foodstore'): revisa TODAS las tablas de la
--          base real y decide, con la observacion previa, si hace falta
--          VACUUM o ANALYZE manual.
--   FASES 1 a 5 (base 'foodstore_restore_test'): ensayo de una accion de
--          mantenimiento segura (VACUUM (ANALYZE)) en la base descartable.
--
-- SEGURIDAD: sobre 'foodstore' este script solo ejecuta SELECT dentro de una
-- transaccion READ ONLY. Todo lo que escribe (UPDATE, VACUUM) corre despues
-- de conectarse a 'foodstore_restore_test'. Si esa base no existe, el script
-- se detiene (ON_ERROR_STOP) y no hace nada mas.
--
-- RESTRICCION: las fases 1 a 5 no usan BEGIN/COMMIT. VACUUM no puede
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

-- ===================================================================
-- FASE 0: Revision de la base real 'foodstore' (SOLO LECTURA)
-- ===================================================================
-- Para cada tabla se compara el estado actual contra los umbrales
-- teoricos de autovacuum y autoanalyze (valores globales del servidor):
--   umbral VACUUM  = autovacuum_vacuum_threshold  + autovacuum_vacuum_scale_factor  * n_live_tup
--   umbral ANALYZE = autovacuum_analyze_threshold + autovacuum_analyze_scale_factor * n_live_tup
-- Decision:
--   n_dead_tup por encima del umbral de VACUUM            -> VACUUM recomendado
--   n_mod_since_analyze por encima del umbral de ANALYZE  -> ANALYZE recomendado
--   en otro caso                                          -> sin accion (el autovacuum alcanza)
-- Si todas las filas dicen 'sin accion', no hay nada que justificar un
-- VACUUM ni un ANALYZE manual sobre 'foodstore'. Los umbrales son
-- teoricos: no se consideran ajustes por tabla (reloptions).
\connect foodstore

BEGIN TRANSACTION READ ONLY;

SELECT 'FASE 0 - Revision de foodstore (solo lectura)' AS fase;

WITH p AS (
    SELECT current_setting('autovacuum_vacuum_threshold')::int          AS vac_umbral,
           current_setting('autovacuum_vacuum_scale_factor')::numeric   AS vac_factor,
           current_setting('autovacuum_analyze_threshold')::int         AS ana_umbral,
           current_setting('autovacuum_analyze_scale_factor')::numeric  AS ana_factor
)
SELECT
    s.relname                                                    AS tabla,
    s.n_live_tup,
    s.n_dead_tup,
    p.vac_umbral + p.vac_factor * s.n_live_tup                   AS umbral_vacuum,
    s.n_mod_since_analyze,
    p.ana_umbral + p.ana_factor * s.n_live_tup                   AS umbral_analyze,
    s.last_autovacuum,
    s.last_autoanalyze,
    CASE
        WHEN s.n_dead_tup > p.vac_umbral + p.vac_factor * s.n_live_tup
            THEN 'VACUUM recomendado'
        WHEN s.n_mod_since_analyze > p.ana_umbral + p.ana_factor * s.n_live_tup
            THEN 'ANALYZE recomendado'
        ELSE 'sin accion'
    END                                                          AS decision
FROM pg_stat_user_tables s
CROSS JOIN p
ORDER BY s.n_dead_tup DESC, s.relname;

COMMIT;

-- ===================================================================
-- A partir de aca, todo corre sobre la base descartable.
-- ===================================================================
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
-- ENSAYO, no mantenimiento real: la base 'foodstore' no se modifica.
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
