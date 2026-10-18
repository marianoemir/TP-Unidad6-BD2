# Food Store — Visión General del Proyecto

## Descripción

Sistema de venta de comida implementado íntegramente en **PostgreSQL**.
Cubre el ciclo completo: categorías → productos → usuarios → pedidos con sus
detalles. Las Unidades 1 a 4 construyeron y optimizaron el modelo, y la
Unidad 5 le agregó administración y seguridad. La **Unidad 6** se ocupa de que
la base se pueda **mantener, respaldar y recuperar**: copias automatizables,
monitoreo, mantenimiento y un simulacro de desastre contra reloj.

## Metodología: dos bases con roles distintos

- **`foodstore`** — base principal. Se arma desde `plantilla_food_store` (que
  tiene `schema.sql` → `objects.sql` → `data.sql`) y se le aplican
  `carga_masiva.sql`, `indices_semana3.sql`, `indices.sql`, `views.sql` y
  `materializadas.sql`. **No se elimina ni se reemplaza** durante el simulacro:
  solo se lee con `pg_dump` y con las consultas de monitoreo.
- **`foodstore_restore_test`** — base descartable donde se restaura el
  respaldo y donde se permiten las pruebas destructivas.

No se reutilizan `copia_trabajo`, `copia_fnbc` ni `copia_u5` de unidades
anteriores. Los roles pertenecen al servidor, no a la base: una restauración
con `--no-owner --no-privileges` no los trae. Detalle en `AGENTS.md`.

## Trabajo Práctico en curso: Unidad 6 (Mantenimiento, respaldo y recuperación)

Cinco partes, cada una con evidencia técnica verificable:

| Parte | Tema | Evidencia |
|---|---|---|
| 1 | Especificación y plan de mantenimiento | `SPEC_U6.md` (una página como máximo) |
| 2 | Respaldo automatizable | `backup_foodstore.ps1`, archivo `.dump` con fecha y hora, log en `logs/` |
| 3 | Monitoreo y mantenimiento | `health_check.sql` (≥4 controles), `maintenance.sql` |
| 4 | Simulacro de desastre contra reloj | Restauración en `foodstore_restore_test`, validaciones, RTO y RPO observados (`restore_test.ps1` opcional) |
| 5 | Informe post-incidente | `informe_u6.pdf` (una página como máximo) |

Herramientas: **OpenCode** (genera la primera versión de los scripts a partir
de `SPEC_U6.md` y `AGENTS.md`, siempre subordinado a la revisión y la prueba
humanas) y **Git**. Todo se ejecuta únicamente contra el servidor propio.

### Plan de mantenimiento que propone la consigna

| Tarea | Frecuencia | Evidencia |
|---|---|---|
| Respaldo de `foodstore` | Diaria | Archivo `.dump` con fecha y log |
| Chequeo de salud | Diaria | Salida de `health_check.sql` |
| Revisión de mantenimiento | Semanal | Tuplas muertas, autovacuum y estadísticas |
| Restauración de prueba | Semanal | `foodstore_restore_test` validada |

### Objetivos de recuperación previstos para el laboratorio

RPO de hasta 24 h (un respaldo diario) y RTO menor a 20 min. En el simulacro se
informan junto con los valores **observados**, y siempre por separado.

## Archivos del proyecto

### Base heredada (`base_heredada/`, sin modificar)

| Archivo | Contenido |
|---|---|
| `schema.sql` | Tipos ENUM, tablas, constraints y los 3 índices originales |
| `objects.sql` | 4 vistas base, `calcular_total_pedido`, triggers, `sp_crear_pedido` |
| `data.sql` | Datos de prueba chicos (ficticios) |
| `carga_masiva.sql` | ≥50.000 productos, ≥20.000 usuarios, ≥200.000 pedidos (hashes de contraseña ficticios) |
| `indices_semana3.sql` | 2 índices parciales sobre `pedido` |
| `indices.sql` | `idx_producto_nombre_lower_vigente` |
| `views.sql` | `v_usuario_seguro` |
| `materializadas.sql` | `mv_facturacion_categoria_mes` + índice único |
| `queries.sql` | Banco de consultas (no se ejecuta de una vez) |
| `transacciones.sql` | Escenarios de atomicidad y concurrencia |

### Entregables de la U6

`SPEC_U6.md`, `backup_foodstore.ps1`, `health_check.sql`, `maintenance.sql`,
`restore_test.ps1` (opcional) e `informe_u6.pdf`, más `evidencias/`. Árbol
completo en `AGENTS.md`.

## Orden de ejecución

```
plantilla_food_store:  schema.sql → objects.sql → data.sql
foodstore:             carga_masiva.sql → indices_semana3.sql → indices.sql
                       → views.sql → materializadas.sql
Parte 2:               backup_foodstore.ps1
Parte 3:               health_check.sql → maintenance.sql
Parte 4:               restauración en foodstore_restore_test → validaciones
```

## Tablas del modelo

```
categoria
producto       → FK categoria_id → categoria
usuario
pedido         → FK usuario_id   → usuario
detalle_pedido → FK pedido_id    → pedido
               → FK producto_id  → producto
```

## Tipos ENUM definidos

```sql
CREATE TYPE rol           AS ENUM ('ADMIN','USUARIO');
CREATE TYPE estado_pedido AS ENUM ('PENDIENTE','CONFIRMADO','TERMINADO','CANCELADO');
CREATE TYPE forma_pago    AS ENUM ('TARJETA','TRANSFERENCIA','EFECTIVO');
```

`rol` es un dato de la aplicación (columna `usuario.rol`). **No** es un rol de
PostgreSQL.

## Vistas disponibles

| Vista | Descripción | Archivo |
|---|---|---|
| `v_categorias_vigentes` | Categorías con `eliminado = FALSE` | `objects.sql` |
| `v_productos_vigentes` | Productos y categorías activos | `objects.sql` |
| `v_pedidos_resumen` | Pedidos vigentes con nombre completo del usuario | `objects.sql` |
| `v_pedido_detalle` | Líneas de detalle vigentes con nombre del producto | `objects.sql` |
| `v_usuario_seguro` | Usuarios sin la columna `contrasena` | `views.sql` |

## Vista materializada

| Vista materializada | Descripción | Archivo |
|---|---|---|
| `mv_facturacion_categoria_mes` | Facturación agregada por categoría y mes (solo pedidos `CONFIRMADO` vigentes). No se actualiza sola: requiere `REFRESH MATERIALIZED VIEW CONCURRENTLY`. Índice único `(categoria_id, mes)`. | `materializadas.sql` |
