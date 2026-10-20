-- health_check.sql
-- TP Unidad 6 - Food Store: chequeo de salud de la base foodstore.
-- Solo lectura. PostgreSQL 16 o superior. Sin contrasenas ni datos personales.
--
-- Como se ejecuta (PowerShell, desde la raiz del repo). Se usa psql y no el Query
-- Tool de pgAdmin porque pgAdmin muestra solo la grilla de la ultima sentencia:
--   & "C:\Program Files\PostgreSQL\17\bin\psql.exe" -h localhost -U postgres -d foodstore -w -f .\health_check.sql -o .\evidencias\health_check_salida.txt
--
-- Controles:
--   1. Tamano de la base y de las tablas mas grandes
--   2. Actividad de conexiones
--   3. Estado de tablas (tuplas vivas y muertas, estadisticas, autovacuum)
--   4. Consultas activas (sin contar esta misma sesion)
--   5. Parametros de autovacuum (complementario: apoya a maintenance.sql)

BEGIN TRANSACTION READ ONLY;

-- ---------------------------------------------------------------------------
SELECT 'CONTROL 1 - Tamano de la base y de las tablas mas grandes' AS control;

SELECT current_database() AS base,
       pg_size_pretty(pg_database_size(current_database())) AS tamano;

SELECT relname,
       pg_size_pretty(pg_total_relation_size(relid)) AS tamano_total
FROM pg_stat_user_tables
ORDER BY pg_total_relation_size(relid) DESC
LIMIT 5;

-- ---------------------------------------------------------------------------
SELECT 'CONTROL 2 - Actividad de conexiones' AS control;

SELECT numbackends,
       xact_commit,
       xact_rollback,
       round(100.0 * blks_hit / NULLIF(blks_hit + blks_read, 0), 2) AS pct_aciertos_cache
FROM pg_stat_database
WHERE datname = current_database();

-- Incluye esta misma sesion.
SELECT count(*) AS conexiones_cliente_servidor,
       count(*) FILTER (WHERE datname = current_database()) AS conexiones_en_esta_base,
       current_setting('max_connections')::int AS max_connections
FROM pg_stat_activity
WHERE backend_type = 'client backend';

-- ---------------------------------------------------------------------------
SELECT 'CONTROL 3 - Estado de tablas' AS control;

SELECT relname,
       n_live_tup,
       n_dead_tup,
       round(100.0 * n_dead_tup / NULLIF(n_live_tup + n_dead_tup, 0), 2) AS pct_muertas,
       n_mod_since_analyze,
       last_autovacuum,
       last_autoanalyze,
       last_vacuum,
       last_analyze
FROM pg_stat_user_tables
ORDER BY n_dead_tup DESC, relname;

-- ---------------------------------------------------------------------------
SELECT 'CONTROL 4 - Consultas activas (sin contar esta sesion)' AS control;

-- Si no hay otra actividad, el resultado es cero filas: es lo esperado.
SELECT pid,
       usename,
       state,
       now() - query_start AS duracion,
       wait_event_type,
       left(query, 120) AS query
FROM pg_stat_activity
WHERE datname = current_database()
  AND state <> 'idle'
  AND pid <> pg_backend_pid()
ORDER BY query_start;

-- ---------------------------------------------------------------------------
SELECT 'CONTROL 5 - Parametros de autovacuum (complementario)' AS control;

SELECT name, setting, unit
FROM pg_settings
WHERE name IN ('autovacuum',
               'track_counts',
               'autovacuum_vacuum_threshold',
               'autovacuum_vacuum_scale_factor',
               'autovacuum_analyze_threshold',
               'autovacuum_analyze_scale_factor')
ORDER BY name;

COMMIT;
