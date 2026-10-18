# Food Store — Convenciones de Base de Datos y de Mantenimiento

## Nombres de tablas

Los nombres de tabla son **en singular y en español**:

```
categoria, producto, usuario, pedido, detalle_pedido
```

No usar plural (`productos`), ni inglés (`product`), ni PascalCase. Las
tablas nuevas siguen la misma regla.

## Columna `eliminado` — Borrado lógico

**Nunca se ejecuta `DELETE`** sobre las tablas del proyecto. Todas tienen
`eliminado BOOLEAN NOT NULL DEFAULT FALSE` y la baja es siempre:

```sql
UPDATE <tabla> SET eliminado = TRUE WHERE id = :id AND eliminado = FALSE;
```

Toda consulta de datos vigentes filtra `WHERE eliminado = FALSE`, **en cada
tabla del JOIN**, no solo en la principal. Las vistas `v_categorias_vigentes`,
`v_productos_vigentes`, `v_pedidos_resumen`, `v_pedido_detalle` y
`v_usuario_seguro` ya aplican el filtro: usarlas cuando cubran el caso.

Baja de un pedido completo (detalles primero, luego el pedido):

```sql
BEGIN;
    UPDATE detalle_pedido SET eliminado = TRUE WHERE pedido_id = :id;
    UPDATE pedido SET eliminado = TRUE WHERE id = :id;
COMMIT;
```

Esto vale también para la seguridad: `fn_autenticar` y `fn_resetear_password`
filtran `eliminado = FALSE`, de modo que un usuario dado de baja no puede
autenticarse ni recibir un reseteo.

## Columnas con reglas propias

- `detalle_pedido.precio_unitario` **congela** el precio al momento de la
  venta; no se recalcula si cambia `producto.precio`.
- `producto.disponible`: `sp_crear_pedido` rechaza productos con
  `disponible = FALSE` aunque tengan stock.
- `pedido.estado`: el trigger `trg_validar_estado_pedido` impide pasar de
  `CONFIRMADO` a `PENDIENTE`. No se valida a mano.

## Restricciones de integridad destacadas

- `categoria.nombre` → `UNIQUE`
- `usuario.mail` → `UNIQUE` + `CHECK` de formato (`chk_usuario_mail_formato`)
- `pedido.fecha` → `CHECK (fecha <= CURRENT_DATE)`
- `detalle_pedido(pedido_id, producto_id)` → `UNIQUE`
- `producto.precio >= 0`, `producto.stock >= 0`, `detalle_pedido.cantidad > 0`
- `detalle_pedido.pedido_id` con `ON DELETE RESTRICT`

## Tipos de datos a respetar

| Campo | Tipo |
|---|---|
| IDs | `BIGINT GENERATED ALWAYS AS IDENTITY` |
| Precios y totales | `NUMERIC(10,2)` / `NUMERIC(12,2)` |
| Fechas con zona | `TIMESTAMPTZ` (`created_at`) |
| Fecha del pedido | `DATE` |
| Contraseña | `VARCHAR(255)` — **solo hash**, nunca texto plano |

## Convenciones de mantenimiento, respaldo y recuperación (Unidad 6)

### Bases

- `foodstore`: base principal. Solo se lee (`pg_dump`, consultas de monitoreo). **Nunca se elimina
  ni se reemplaza.**
- `foodstore_restore_test`: descartable. Única base donde se restaura y se hacen pruebas destructivas.
- `plantilla_food_store`: referencia de unidades anteriores; no se toca.

### Respaldos

- Formato custom (`pg_dump -Fc`), para poder restaurar con `pg_restore`.
- Nombre `foodstore_AAAAMMDD_HHMMSS.dump` en `backups/`; un log por ejecución en
  `logs/backup_AAAAMMDD_HHMMSS.log`. Ninguna de las dos carpetas se versiona.
- El script termina con código distinto de 0 si `pg_dump` falla y borra el archivo parcial.
- Se escribe primero a `*.dump.parcial` y se renombra solo al final: un respaldo truncado nunca
  lleva el nombre de uno válido. La restauración elige el último `*.dump` e ignora los `.parcial`.
- Integridad rápida: `pg_restore --list` sobre el `.dump` debe leerlo sin error. Opcional: huella
  SHA-256 junto al archivo.
- Las carpetas se resuelven desde la ubicación del script (`$PSScriptRoot`). Los logs se escriben
  con codificación explícita (`Add-Content -Encoding ASCII`); `Out-File` y `2>>` escriben UTF-16
  en PowerShell 5.1.
- Todo script registra fecha, operación y resultado (OK o ERROR) y lleva comentarios legibles.
- `pg_dump` no respalda los roles: se resguardan con `pg_dumpall --globals-only --no-role-passwords`.
- Un respaldo que nunca se restauró no está probado: la restauración de prueba es parte del plan.

### Contraseñas

- Ninguna en scripts, comandos, logs, evidencias ni informe. No se usa `PGPASSWORD`. En Windows: `pgpass.conf` en
  `%APPDATA%\postgresql\` (formato `host:puerto:base:usuario:contraseña`), fuera del repo.
- Las herramientas se invocan con `-w` (nunca preguntar): si falta la credencial, fallan y se ve.

### Restauración

- Siempre en `foodstore_restore_test`, con `pg_restore --no-owner --no-privileges`.
- El script verifica el nombre de destino antes de actuar y se niega si es `foodstore`.
- No vuelven los roles ni los permisos (los roles son del servidor y no están en el respaldo de una
  base). Se documenta como limitación del ensayo.
- Después de restaurar, `ANALYZE` (las estadísticas no viajan en el respaldo en PostgreSQL 17 y
  anteriores).

### Validación mínima

- La consigna nombra la tabla `cliente`; en esta base es **`usuario`**.
- Conteos de `categoria`, `usuario`, `producto`, `pedido` y `detalle_pedido`, registrados **antes**
  del respaldo y comparados después de restaurar.
- `productos_invalidos` (`precio < 0 OR stock < 0`) y `detalles_invalidos`
  (`cantidad <= 0 OR precio_unitario < 0`) deben devolver **cero**.

### RPO y RTO

- **Previstos para el laboratorio:** RPO de hasta 24 h (respaldo diario) y RTO menor a 20 min.
- **RPO**: cuánta información, medida en tiempo, se acepta perder. Observado en el simulacro como la
  antigüedad del respaldo al momento de restaurar.
- **RTO**: cuánto tarda en volver a estar utilizable. Cronómetro desde inmediatamente antes de crear
  `foodstore_restore_test` hasta que las validaciones terminan bien.
- Se informan siempre **previstos y observados**, y se mantienen separados.

### Monitoreo y mantenimiento

- `health_check.sql` es de **solo lectura** y tiene al menos cuatro controles: tamaño de la base,
  actividad de conexiones, estado de tablas y consultas activas. Excluye la propia sesión
  (`pid <> pg_backend_pid()`).
- **Sin `VACUUM FULL`** como mantenimiento periódico. Un `VACUUM` o `ANALYZE` manual se justifica con
  la observación previa (`n_dead_tup`, `n_mod_since_analyze`, `last_autovacuum`, `last_autoanalyze`).
- La justificación debe corresponder a la acción: **`ANALYZE` actualiza estadísticas y no elimina
  tuplas muertas** (eso es `VACUUM`). Una acción de `ANALYZE` se justifica con `n_mod_since_analyze`
  alto o `last_autoanalyze` vacío; un `VACUUM` con un porcentaje relevante de tuplas muertas.
- `VACUUM` no corre dentro de un bloque de transacción: sentencia por sentencia en pgAdmin o con
  `psql -f`.

### Datos y asistentes de IA

- Los datos de este proyecto son ficticios, pero no se abren, leen ni adjuntan los archivos de
  `backups/` ni el contenido de un `.dump`.
- Los scripts generados por una IA se leen línea por línea y se prueban a mano antes de aceptarse.
  El informe indica qué parte fue asistida y cómo se verificó. Preguntas de revisión: ¿con qué rol
  se conecta?, ¿hay contraseñas o datos personales?, ¿qué pasa si falla un comando?, ¿qué borra
  exactamente?, ¿toma bloqueos exclusivos?, ¿deja registro de éxito y de falla?, ¿se probó en un
  entorno descartable?, ¿puedo explicar cada línea?

## Índices existentes (referencia; no se agregan índices en este TP)

```
schema.sql          idx_producto_categoria_id, idx_pedido_usuario_id,
                    idx_producto_nombre_vigente
indices_semana3.sql idx_pedido_fecha_estado_vigente,
                    idx_pedido_usuario_total_estado
indices.sql         idx_producto_nombre_lower_vigente
```
