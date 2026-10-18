# Food Store — Instrucciones para Agentes

TP Unidad 6 — Mantenimiento, respaldo y recuperación (Base de Datos II, UTN).
Actividad breve de laboratorio, semana 10. Se construye un procedimiento pequeño pero
completo: respaldar `foodstore`, monitorearla, mantenerla y restaurarla en una base
descartable midiendo el tiempo de recuperación.

**Cómo se usa este archivo:** OpenCode genera la primera versión de los scripts a partir de
`SPEC_U6.md` y de este `AGENTS.md`. Todo lo que genere se revisa línea por línea y se prueba
antes de aceptarse. No se evalúa la cantidad de texto generado, sino que el procedimiento
final sea correcto.

## Stack Tecnológico

| Componente | Tecnología / Versión | Propósito |
|---|---|---|
| Motor BD | PostgreSQL 16+ (el servidor del equipo corre 17) | Base de datos relacional |
| Scripts | PowerShell (`.ps1`) sobre Windows | Respaldo y restauración automatizables |
| SQL | `health_check.sql`, `maintenance.sql` | Monitoreo y mantenimiento |
| Herramientas de PostgreSQL | `pg_dump`, `pg_restore`, `createdb`, `psql` | En `C:\Program Files\PostgreSQL\17\bin\` (no están en el PATH: los scripts reciben la ruta como parámetro) |
| Cliente gráfico | pgAdmin 4 | Solo para consultar; ver "Trampas conocidas" |
| Herramientas del TP | OpenCode, Git | OpenCode queda subordinado a la revisión y la prueba humanas |

## Alcance (regla principal)

Todo se ejecuta **solo contra el servidor propio de desarrollo**, con dos bases:

| Base | Rol en el TP | Qué se puede hacer |
|---|---|---|
| `foodstore` | Base principal | Se **lee** (`pg_dump`, consultas de monitoreo). **Nunca se elimina ni se reemplaza.** |
| `foodstore_restore_test` | Base de restauración, descartable | Único lugar donde se restaura y donde se permiten pruebas destructivas |
| `plantilla_food_store` | Referencia de las unidades anteriores | No se toca |

## Cómo se arma `foodstore` (cada vez que se recrea)

```
En plantilla_food_store (ya existe de la U4):
  base_heredada/schema.sql → objects.sql → data.sql

En foodstore (CREATE DATABASE foodstore TEMPLATE plantilla_food_store):
  carga_masiva.sql → indices_semana3.sql → indices.sql → views.sql → materializadas.sql
```

Con `carga_masiva.sql` la base queda con volumen real (≥50.000 productos, ≥20.000 usuarios,
≥200.000 pedidos). Eso importa: sin volumen, el tiempo de restauración (RTO) no dice nada.
Crear una base con `TEMPLATE` exige que nadie esté conectado a la plantilla.

## Las cinco partes del TP

| Parte | Qué se entrega | Archivo |
|---|---|---|
| 1. Especificación | Qué se automatiza, con qué frecuencia y qué confirma que terminó bien (una página como máximo) | `SPEC_U6.md` |
| 2. Respaldo | Script que genera un respaldo custom de `foodstore`, con fecha y hora en el nombre, log en `logs/` y error si `pg_dump` falla. Sin contraseña. Probado a mano | `backup_foodstore.ps1` |
| 3. Monitoreo y mantenimiento | Al menos cuatro controles (tamaño, conexiones, estado de tablas, consultas activas) y una revisión de autovacuum/ANALYZE con una acción segura y justificada | `health_check.sql`, `maintenance.sql` |
| 4. Simulacro contra reloj | Restaurar el último respaldo en `foodstore_restore_test`, validar y medir el tiempo (RTO) y la antigüedad del respaldo (RPO observado) | `restore_test.ps1` (opcional) |
| 5. Informe post-incidente | Una página como máximo | `informe_u6.pdf` |

Tareas que propone la consigna para el plan: respaldo diario (archivo `.dump` con fecha y log),
chequeo de salud diario (salida de `health_check.sql`), revisión de mantenimiento semanal
(tuplas muertas, autovacuum, estadísticas) y restauración de prueba semanal
(`foodstore_restore_test` validada).

## Estructura de carpetas

```
food-store-tp-u6/
├── SPEC_U6.md
├── backup_foodstore.ps1
├── health_check.sql
├── maintenance.sql
├── restore_test.ps1          (opcional)
├── informe_u6.pdf
├── evidencias/               salidas, tamaños, tiempos, copias de logs
│   └── datos_para_informe.md   datos del simulacro que completa Mariano
├── bitacoras/                una bitácora personal por integrante (se unifican al final)
├── BITACORA.md               bitácora unificada (se arma al cerrar el trabajo)
├── DIVISION_DE_TRABAJO.md    quién hace qué y quién depende de quién
├── base_heredada/            los 10 .sql de Food Store (U1–U4), sin modificar
├── AGENTS.md  README.md
└── .kiro/steering/           contexto del proyecto
```

`backups/` y `logs/` existen solo en local y **no se versionan**. La evidencia de un log se
entrega como copia en `evidencias/`. Si el aula limita el tamaño de los archivos, el `.dump`
puede omitirse: en ese caso se incorpora evidencia de su creación, su tamaño y su restauración
exitosa.

## Reglas Duras del Proyecto

Heredadas de las unidades anteriores:

1. **Nombres de tablas:** singular y español.
2. **Borrado lógico:** nunca `DELETE`; `UPDATE … SET eliminado = TRUE`.
3. **Altas de pedidos:** siempre `CALL sp_crear_pedido(...)`.
4. **Triggers automáticos:** no modificar `trg_subtotal`, `trg_total_ins`, `trg_total_upd`,
   `trg_validar_estado_pedido`.
5. **Vistas vigentes:** usarlas en vez de escribir el filtro a mano.
6. **JOINs y borrado lógico:** `eliminado = FALSE` en cada tabla del JOIN.

Propias de la Unidad 6:

7. **`foodstore` no se elimina ni se reemplaza.** Ningún script de este TP ejecuta `DROP DATABASE`
   ni `CREATE DATABASE` con ese nombre. Un `DROP DATABASE` solo puede apuntar, de forma explícita
   y fija, a `foodstore_restore_test`.
8. **La restauración va solo a `foodstore_restore_test`.** Los scripts de restauración verifican
   el nombre de destino antes de actuar y se niegan a continuar si es `foodstore`.
9. **Sin contraseñas.** Ninguna contraseña en scripts, comandos, logs, evidencias ni informe. Se
   usa `pgpass.conf` (en Windows: `%APPDATA%\postgresql\pgpass.conf`, fuera del repo) y las
   herramientas se invocan con `-w` para que **fallen en lugar de quedar esperando** una clave.
   No se usa `PGPASSWORD` en los scripts (queda en el entorno y en el historial de la consola).
10. **Respaldo en formato custom** (`pg_dump -Fc`), con fecha y hora en el nombre
    (`foodstore_AAAAMMDD_HHMMSS.dump`), un log por ejecución y **código de salida distinto de 0**
    si `pg_dump` falla. Si falla, el archivo parcial se borra. Buenas prácticas del material del
    curso: escribir primero a `foodstore_..._HHMMSS.dump.parcial` y **renombrar solo al final**
    (un respaldo truncado nunca lleva el nombre de uno válido), comprobar el archivo con
    `pg_restore --list` y, opcionalmente, guardar su huella SHA-256.
11. **Restauración con `--no-owner --no-privileges`** vía `pg_restore`. Consecuencia que se
    documenta: los roles y permisos no vuelven (los roles son del servidor, no de la base).
    `pg_dump` tampoco los respalda: se resguardan aparte con
    `pg_dumpall --globals-only --no-role-passwords` (y las contraseñas se reasignan al restaurar).
12. **Sin `VACUUM FULL` como mantenimiento periódico** (reescribe la tabla y toma un bloqueo
    exclusivo). Un `VACUUM` o `ANALYZE` manual se justifica con la observación previa del estado de
    las tablas (`n_dead_tup`, `n_mod_since_analyze`, `last_autovacuum`, `last_autoanalyze`).
    La justificación tiene que corresponder a la acción: **`ANALYZE` actualiza estadísticas del
    planificador y no elimina tuplas muertas** (eso lo hace `VACUUM`).
13. **El agente propone, el equipo ejecuta.** Un agente no corre comandos contra el servidor por su
    cuenta: genera el script, el equipo lo lee línea por línea y lo prueba a mano antes de darlo
    por apto para programar. Las pruebas destructivas solo sobre entornos descartables.
14. **Los respaldos no van a una IA.** No se abren, leen ni pegan archivos de `backups/`, y el
    contenido de un `.dump` no se adjunta a ningún asistente. Los datos de este proyecto son
    ficticios, pero un respaldo es pesado, binario y contiene toda la base: se trata igual.
15. **Mediciones reales.** RPO y RTO se registran como los valores **observados** en la ejecución,
    junto con los previstos. No se estiman ni se inventan. Los valores y el "problema encontrado"
    que aparecen en los ejemplos del material del curso son ilustrativos: no se copian.
16. **Todo script deja registro** de fecha, operación y resultado (OK o ERROR) y lleva comentarios
    legibles. Un script se prueba a mano antes de programarlo, y una tarea programada cuyo log
    nadie revisa no cuenta como mantenimiento.
17. **Rutas y codificación.** Las carpetas `backups/` y `logs/` se resuelven desde la ubicación del
    script (`$PSScriptRoot`), no desde el directorio de trabajo. Los logs se escriben con
    codificación explícita (`Add-Content -Encoding ASCII`) y no con `Out-File` o `2>>` a secas.

## Diferencia clave entre la consigna y la base real

| La consigna usa | La base real tiene | Qué hacer |
|---|---|---|
| Tabla `cliente` (en la validación mínima) | La tabla se llama **`usuario`** | Reemplazar `cliente` por `usuario` en las validaciones y dejarlo asentado en el informe. Sin el cambio, la consulta falla |
| Columnas `producto(precio, stock)` y `detalle_pedido(cantidad, precio_unitario)` | Existen con esos nombres y con `CHECK` | Sin cambios |
| Base `foodstore` | En proyectos anteriores se trabajó en `copia_u5` o `copia_trabajo` | Para este TP la base principal se llama **`foodstore`**; no reutilizar las anteriores |
| Scripts de ejemplo del curso con base `food_store`, usuario `mant_backup`, PostgreSQL 16 y rutas `D:\` | Este TP usa `foodstore`, `postgres` y PostgreSQL 17 local | Son material de apoyo, no plantilla de entrega: valen los nombres de la consigna. Sí se puede tomar de ahí la idea (`.parcial`, `--list`, SHA-256) |

`usuario.rol` (ENUM `ADMIN`/`USUARIO`) es un dato de la aplicación; **no** es un rol de PostgreSQL.

## Trampas conocidas

- **`VACUUM` no corre dentro de un bloque de transacción.** El Query Tool de pgAdmin manda un script
  de varias sentencias como una sola; ahí `VACUUM` falla. Ejecutarlo sentencia por sentencia o con
  `psql -f`. `ANALYZE` sí puede ir en un bloque.
- **pgAdmin solo muestra la grilla de la última sentencia** de un script. Para `health_check.sql`
  conviene `psql -f` o correr las consultas de a una.
- **PowerShell y los `.ps1`:** guardarlos en ASCII (sin tildes): Windows PowerShell 5.1 lee mal un
  `.ps1` en UTF-8 sin BOM. Revisar siempre `$LASTEXITCODE` después de llamar a `pg_dump` o
  `pg_restore`: los errores de herramientas externas no son excepciones de PowerShell.
- **Logs en UTF-16:** en Windows PowerShell 5.1, `Out-File` y los redireccionamientos (`>`, `2>>`)
  escriben UTF-16 por omisión, y el log se ve mal en muchos visores. Usar `Add-Content -Encoding ASCII`.
- **`$ErrorActionPreference = 'Stop'` y herramientas externas:** en PowerShell 5.1, redirigir el
  error de `pg_dump` con `2>&1` convierte su salida en excepciones. Para esa llamada dejar
  `'Continue'` y decidir con `$LASTEXITCODE`.
- **`createdb` falla si la base ya existe.** Para repetir el ensayo, eliminar antes
  `foodstore_restore_test` (solo esa) fuera del cronómetro, y registrarlo.
- **Las estadísticas del planificador no vienen en un respaldo** (en PostgreSQL 17 y anteriores).
  Después de restaurar, `ANALYZE` en la base restaurada antes de medir o comparar planes.
- **Los hashes de `carga_masiva.sql` son ficticios** y los datos son de prueba: no hay nada real
  en la base.
- **Crear una base con `TEMPLATE`** exige que nadie esté conectado a la plantilla.

## Criterios de aprobación técnica

- La restauración se hace en `foodstore_restore_test`, nunca sobre `foodstore`.
- El respaldo se restaura de forma efectiva.
- Ningún script expone contraseñas.
- Las consultas de monitoreo corren en PostgreSQL 16+.
- El informe distingue **RPO** de **RTO** y registra valores observados.
- La intervención de OpenCode queda subordinada a revisión y prueba humana.

| Criterio | Puntaje |
|---|---|
| Especificación clara y plan de mantenimiento coherente | 2,0 |
| Respaldo automatizable, seguro y probado | 2,0 |
| Monitoreo y mantenimiento técnicamente correctos | 2,0 |
| Restauración, validaciones y medición RPO/RTO | 3,0 |
| Informe breve, evidencias y verificación del trabajo asistido con OpenCode | 1,0 |

## Condición de éxito de cada tarea

| Tarea | Se considera terminada correctamente cuando… |
|---|---|
| Respaldo | `pg_dump` devuelve código 0, el `.dump` existe con tamaño mayor a cero, `pg_restore --list` lo lee y el log registra el resultado |
| Chequeo de salud | `health_check.sql` corre sin errores y muestra tamaño, conexiones, estado de tablas y consultas activas |
| Revisión de mantenimiento | Se observó el estado de las tablas y hay una decisión documentada (actuar sobre cuáles tablas y por qué, o no actuar) |
| Restauración de prueba | La restauración termina sin errores en `foodstore_restore_test`, los conteos coinciden con los registrados antes del respaldo y los controles de inválidos dan cero |

El script de restauración elige **el último respaldo generado** por fecha (ignorando los
`.parcial`), en lugar de recibir la ruta a mano.

## Definiciones que se usan en el informe

- **RPO** (*recovery point objective*): cuánta información, medida en tiempo, se acepta perder. Con
  respaldo diario, el RPO previsto es de hasta 24 horas. En el simulacro se **observa** como la
  antigüedad del respaldo al momento de restaurar (hora actual menos la fecha del `.dump`).
- **RTO** (*recovery time objective*): cuánto tarda en volver a estar utilizable. El cronómetro
  arranca **inmediatamente antes de crear** `foodstore_restore_test` y se detiene cuando las
  validaciones mínimas terminan correctamente.
- **Objetivos previstos para el laboratorio** (tabla del material teórico): **RPO de hasta 24 h**
  (un respaldo diario) y **RTO menor a 20 min**. Se informan junto con los observados.
- Son cosas distintas: el RPO habla de datos perdidos y el RTO de tiempo de recuperación.

## Reglas de proceso que se evalúan

- **OpenCode:** se le entrega `SPEC_U6.md` y este `AGENTS.md`. El informe indica qué parte fue
  asistida y cómo se verificó antes de aceptarla (lectura línea por línea, ejecución manual,
  comparación contra la evidencia).
- **Revisión de un script generado por IA** (preguntas del material del curso): ¿con qué rol se
  conecta y es el mínimo?; ¿hay contraseñas o datos personales en el código?; ¿qué pasa si falta
  una variable o falla un comando?; ¿qué borra exactamente?; ¿toma bloqueos exclusivos y cuánto
  duran?; ¿deja registro de éxito y de falla?; ¿se probó en un entorno descartable?; ¿puedo
  explicar cada línea en una defensa?
- **Evidencias:** salida del respaldo (archivo, tamaño, log), salida de `health_check.sql`,
  conteos de filas antes del respaldo y después de restaurar, resultado de los controles de
  productos y detalles inválidos (deben dar cero) y el tiempo total.
- **Git:** avance por partes, con commits legibles; sin contraseñas ni respaldos en el repo.

## Vistas y objetos heredados (NO recrear)

Están en `base_heredada/`.

- `objects.sql`: `v_categorias_vigentes`, `v_productos_vigentes`, `v_pedidos_resumen`,
  `v_pedido_detalle`; función `calcular_total_pedido`; triggers `trg_subtotal`, `trg_total_ins`,
  `trg_total_upd`, `trg_validar_estado_pedido`; procedimiento `sp_crear_pedido(BIGINT, forma_pago, JSONB)`.
- `views.sql`: `v_usuario_seguro`.
- `materializadas.sql`: `mv_facturacion_categoria_mes` (requiere `REFRESH MATERIALIZED VIEW
  CONCURRENTLY`; no se actualiza sola).
- Índices (6, en `schema.sql`, `indices_semana3.sql` e `indices.sql`): no se proponen índices
  nuevos en este TP.

## Base de Conocimiento y Steering

- `.kiro/steering/project-overview.md`: visión general, orden de ejecución y entregables.
- `.kiro/steering/conventions.md`: convenciones de base de datos y de respaldo/recuperación.
- `.kiro/steering/objects-and-patterns.md`: objetos heredados y patrones de scripts y consultas.
- `SPEC_U6.md`: especificación del plan; es la fuente para generar los scripts.
