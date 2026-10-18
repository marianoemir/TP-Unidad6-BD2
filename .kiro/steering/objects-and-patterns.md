# Food Store — Objetos del Esquema y Patrones

## Triggers — NO MODIFICAR

Funcionan de forma automática; no se tocan, reescriben ni reemplazan.

| Trigger | Tabla | Evento | Función | Qué hace |
|---|---|---|---|---|
| `trg_subtotal` | `detalle_pedido` | `BEFORE INSERT OR UPDATE` (fila) | `fn_set_subtotal()` | Copia `precio` de `producto` a `precio_unitario` si llega `NULL`; calcula `subtotal` |
| `trg_total_ins` | `detalle_pedido` | `AFTER INSERT` (sentencia) | `fn_recalcular_total()` | Recalcula `pedido.total` |
| `trg_total_upd` | `detalle_pedido` | `AFTER UPDATE` (sentencia) | `fn_recalcular_total()` | Ídem para `UPDATE` |
| `trg_validar_estado_pedido` | `pedido` | `BEFORE UPDATE OF estado` (fila) | `fn_validar_estado_pedido()` | Bloquea `CONFIRMADO → PENDIENTE` |

**Consecuencia para los permisos:** las funciones de trigger no son
`SECURITY DEFINER`, así que corren con los privilegios de quien dispara la
operación. Para insertar en `detalle_pedido`, el rol necesita además
`SELECT` sobre `producto` (lo lee `fn_set_subtotal`) y `UPDATE` sobre `pedido`
(lo escribe `fn_recalcular_total`).

## Procedimiento `sp_crear_pedido` — único camino para altas de pedidos

```sql
CALL sp_crear_pedido(
    p_usuario_id BIGINT,
    p_forma_pago forma_pago,
    p_items      JSONB   -- [{"producto_id": N, "cantidad": N}, ...]
);
```

Nunca `INSERT INTO pedido` + `INSERT INTO detalle_pedido` a mano. Garantiza:
usuario vigente, producto vigente y disponible, stock suficiente, descuento de
stock en la misma transacción, `FOR UPDATE` sobre el producto y rollback si
falla un ítem. Errores: usuario inexistente o eliminado; producto inexistente,
eliminado o no disponible; stock insuficiente.

**Consecuencia para los permisos:** es `SECURITY INVOKER` y, además de
insertar en `pedido` y `detalle_pedido`, **lee `usuario`**, hace `SELECT …
FOR UPDATE` sobre `producto` (requiere privilegio `UPDATE` sobre al menos una
columna) y **actualiza `producto.stock`**. Quien la ejecute necesita esos
privilegios, o la función debe cambiar de modelo. Es una decisión de diseño de
la Parte A (ver `AGENTS.md`); no se resuelve "a ojo".

## Vistas — usar en vez de reescribir el filtro a mano

| Vista | Para qué sirve | Archivo |
|---|---|---|
| `v_categorias_vigentes` | Categorías con `eliminado = FALSE` | `objects.sql` |
| `v_productos_vigentes` | Productos + categoría, ambos vigentes | `objects.sql` |
| `v_pedidos_resumen` | Pedidos vigentes + nombre completo del usuario | `objects.sql` |
| `v_pedido_detalle` | Líneas de detalle vigentes + nombre del producto | `objects.sql` |
| `v_usuario_seguro` | Usuarios **sin** `contrasena`; para listar/exponer usuarios, nunca `SELECT * FROM usuario` fuera de la autenticación | `views.sql` |

## Vista materializada `mv_facturacion_categoria_mes` (`materializadas.sql`)

Facturación por categoría y mes (pedidos `CONFIRMADO` vigentes). No se
actualiza sola: `REFRESH MATERIALIZED VIEW CONCURRENTLY
mv_facturacion_categoria_mes;`. El índice único `idx_mv_facturacion_cat_mes_pk`
`(categoria_id, mes)` es lo que permite el `CONCURRENTLY`: no borrarlo.

## Patrones de respaldo, monitoreo y recuperación (Unidad 6)

Los bloques de abajo son **patrones**, no la solución: se adaptan, se leen línea por línea y se
prueban a mano antes de aceptarse. Rutas de herramientas como parámetro (no están en el PATH):
`C:\Program Files\PostgreSQL\17\bin\`. Los `.ps1` se guardan en ASCII.

### 1. Respaldo custom con archivo parcial, log y error si falla

```powershell
$ts      = Get-Date -Format 'yyyyMMdd_HHmmss'
$dump    = Join-Path $DirBackups "foodstore_$ts.dump"
$parcial = "$dump.parcial"
$log     = Join-Path $DirLogs "backup_$ts.log"          # carpetas desde $PSScriptRoot

function Registrar($texto) {
    Add-Content -Path $log -Value "$(Get-Date -Format s) $texto" -Encoding ASCII
}

Registrar "INICIO respaldo de foodstore -> $dump"
$ErrorActionPreference = 'Continue'   # con 'Stop', el stderr de pg_dump se vuelve excepcion en PS 5.1
& $PgDump -h $Servidor -p $Puerto -U $Usuario -d foodstore -Fc -w -v -f $parcial 2>&1 |
    ForEach-Object { Registrar "$_" }
$codigo = $LASTEXITCODE

if ($codigo -ne 0) {
    Remove-Item $parcial -ErrorAction SilentlyContinue   # no dejar un respaldo parcial
    Registrar "ERROR: pg_dump termino con codigo $codigo"
    exit 1
}

& $PgRestore --list $parcial | Out-Null                  # el archivo debe poder leerse
if ($LASTEXITCODE -ne 0) { Remove-Item $parcial; Registrar "ERROR: respaldo ilegible"; exit 1 }

Move-Item $parcial $dump                                 # recien ahora lleva el nombre definitivo
(Get-FileHash $dump -Algorithm SHA256).Hash | Set-Content "$dump.sha256"   # opcional
Registrar "OK: $dump"
```

La clave sale de `pgpass.conf` (nunca `PGPASSWORD`); `-w` evita que el script quede esperando.
Los errores de una herramienta externa no son excepciones: se decide con `$LASTEXITCODE`.

### 2. Roles del servidor (no están en el respaldo de la base)

```powershell
& $PgDumpAll -h $Servidor -p $Puerto -U $Usuario -w --globals-only --no-role-passwords -f $globales
```

### 3. Restauración cronometrada con protección

```powershell
$Destino = 'foodstore_restore_test'
if ($Destino -eq 'foodstore') { throw 'Destino prohibido: foodstore' }

# ultimo respaldo por fecha (los *.dump.parcial no coinciden con el filtro)
$ultimo = Get-ChildItem $DirBackups -Filter 'foodstore_*.dump' -File |
          Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $ultimo) { throw 'No hay respaldos' }
& $PgRestore --list $ultimo.FullName | Out-Null

# (opcional, fuera del cronometro) eliminar solo la base descartable de un ensayo anterior
# & $DropDb -h $Servidor -p $Puerto -U $Usuario -w --if-exists $Destino

$sw = [Diagnostics.Stopwatch]::StartNew()                 # inmediatamente antes de crear
& $CreateDb  -h $Servidor -p $Puerto -U $Usuario -w $Destino
& $PgRestore -h $Servidor -p $Puerto -U $Usuario -w -d $Destino --no-owner --no-privileges $ultimo.FullName
# ... validaciones con psql sobre $Destino ...
$sw.Stop()                                                # al terminar bien las validaciones
```

### 4. Validación mínima (con `usuario` en lugar de `cliente`)

```sql
SELECT 'categoria' AS tabla, COUNT(*) AS filas FROM categoria
UNION ALL SELECT 'usuario',        COUNT(*) FROM usuario
UNION ALL SELECT 'producto',       COUNT(*) FROM producto
UNION ALL SELECT 'pedido',         COUNT(*) FROM pedido
UNION ALL SELECT 'detalle_pedido', COUNT(*) FROM detalle_pedido;

SELECT COUNT(*) AS productos_invalidos FROM producto WHERE precio < 0 OR stock < 0;
SELECT COUNT(*) AS detalles_invalidos  FROM detalle_pedido WHERE cantidad <= 0 OR precio_unitario < 0;
```

Los conteos se corren y se anotan **antes** del respaldo, sobre `foodstore`, y se comparan con los de
`foodstore_restore_test`. Los dos controles de inválidos deben dar cero.

### 5. Antigüedad del respaldo (RPO observado)

```powershell
$antiguedad = (Get-Date) - $ultimo.LastWriteTime
```

### 6. Controles de salud (solo lectura)

```sql
-- tamano
SELECT pg_size_pretty(pg_database_size('foodstore')) AS tamano;

-- conexiones
SELECT numbackends, xact_commit, xact_rollback
FROM pg_stat_database WHERE datname = 'foodstore';

-- estado de tablas
SELECT relname, n_live_tup, n_dead_tup, last_autovacuum, last_autoanalyze
FROM pg_stat_user_tables ORDER BY n_dead_tup DESC;

-- consultas activas (sin la propia sesion)
SELECT pid, state, now() - query_start AS duracion, query
FROM pg_stat_activity
WHERE datname = 'foodstore' AND state <> 'idle' AND pid <> pg_backend_pid();
```

Se ejecutan conectado a `foodstore`; `pg_stat_user_tables` mira la base de la conexión.

### 7. Mantenimiento justificado por observación

```sql
-- 1) observar
SELECT relname, n_live_tup, n_dead_tup,
       round(100.0 * n_dead_tup / NULLIF(n_live_tup + n_dead_tup, 0), 1) AS pct_muertas,
       n_mod_since_analyze, last_autovacuum, last_autoanalyze
FROM pg_stat_user_tables ORDER BY n_dead_tup DESC;

SELECT name, setting FROM pg_settings WHERE name LIKE 'autovacuum%';

-- 2) actuar solo donde la observacion lo justifica, sentencia por sentencia
ANALYZE producto;                      -- ACTUALIZA ESTADISTICAS (no elimina tuplas muertas):
                                       -- si n_mod_since_analyze es alto o no hay last_autoanalyze
VACUUM (VERBOSE, ANALYZE) pedido;      -- ELIMINA TUPLAS MUERTAS: si pct_muertas es relevante;
                                       -- nunca VACUUM FULL

-- 3) volver a observar y comparar
```

`VACUUM FULL` reescribe la tabla y toma un bloqueo exclusivo: no es mantenimiento periódico.

## Patrones de consulta heredados

- Preferir las vistas vigentes antes que reescribir `eliminado = FALSE`.
- Filtrar `eliminado = FALSE` en todas las tablas participantes.
- `SUM` con `COALESCE(..., 0)` para evitar `NULL`.
- Productos sin ventas: `LEFT JOIN … WHERE fk IS NULL`, no `NOT IN`.
