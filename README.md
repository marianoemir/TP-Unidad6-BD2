# TP Unidad 6 - Food Store: mantenimiento, respaldo y recuperacion

Trabajo practico de Bases de Datos II (Tecnicatura Universitaria en Programacion, UTN FRM). Integra respaldo,
monitoreo, mantenimiento y recuperacion sobre la base `foodstore` (PostgreSQL 16 o superior; probado en 17, Windows,
PowerShell 5.1). Equipo: Mariano Chirino, Andres y Facundo.

El procedimiento: generar un respaldo custom de `foodstore`, monitorear su salud, mantenerla y restaurar el ultimo
respaldo en `foodstore_restore_test` midiendo el tiempo de recuperacion (RTO) y la antiguedad del respaldo (RPO observado).

## Entregables

| Archivo | Contenido | Responsable |
|---|---|---|
| `SPEC_U6.md` | Plan: tareas, frecuencia, condicion de exito, RPO/RTO previstos, reglas de seguridad | Mariano |
| `backup_foodstore.ps1` | Respaldo `pg_dump -Fc` con fecha y hora, log, `.parcial`, error si `pg_dump` falla | Mariano |
| `health_check.sql` | Consultas de monitoreo (tamano, conexiones, estado de tablas, consultas activas) | Andres |
| `maintenance.sql` | Revision de autovacuum/ANALYZE y accion de mantenimiento justificada | Facundo |
| `restore_test.ps1` | Simulacro de restauracion con cronometro y validaciones (opcional en la consigna) | Mariano |
| `informe_u6.pdf` | Informe post-incidente de una pagina | Facundo |

Material de apoyo: `evidencias/` (copias de logs y conteos), `Datos para Facundo/` (insumos del informe),
`bitacoras/` y `BITACORA.md` (registro de lo hecho), `AGENTS.md` y `.kiro/steering/` (reglas del proyecto para la
IA), `base_heredada/` (los `.sql` de Food Store de las unidades anteriores, sin modificar).

## Requisitos

- PostgreSQL 16+ con las herramientas `pg_dump`, `pg_restore`, `createdb`, `dropdb` y `psql`. No estan en el PATH:
  los scripts las buscan por parametro (por defecto `C:\Program Files\PostgreSQL\17\bin\`).
- La base `foodstore` cargada (orden de armado en `Para Facundo y Andres/DIVISION_DE_TRABAJO.md`, seccion 4).
- **Sin contrasenas en el repo.** La clave va en `%APPDATA%\postgresql\pgpass.conf` (fuera del repo, ignorado por
  `.gitignore`) con una linea `localhost:5432:*:postgres:<clave>`; las herramientas se invocan con `-w`.

## Uso

Desde PowerShell, en la raiz del repo:

```
.\backup_foodstore.ps1
.\restore_test.ps1
```

- `backup_foodstore.ps1` escribe `backups\foodstore_AAAAMMDD_HHMMSS.dump` (primero como `.parcial`, renombrado al
  final), su `.sha256` y un log en `logs\`. Verifica el respaldo con `pg_restore --list` y termina con codigo 1 si falla.
- `restore_test.ps1` toma el **ultimo** `.dump`, crea `foodstore_restore_test` (si existia, la elimina antes del
  cronometro), restaura con `--no-owner --no-privileges`, ejecuta las validaciones y registra RTO y RPO en `logs\`.
  Se niega a actuar si el destino es `foodstore`.
- `backups\` y `logs\` son locales y no se versionan; la evidencia se entrega como copia en `evidencias/`.

## Resultados observados (2026-10-18)

| | Previsto | Observado |
|---|---|---|
| RPO | hasta 24 h | 1,45 h (respaldo de las 09:49:32; simulacro iniciado a las 11:16:42) |
| RTO | menos de 20 min | 6,19 s (corrida oficial; la primera corrida, con un error del script, dio 5,51 s) |

Validaciones despues de restaurar: los conteos de `categoria`, `usuario`, `producto`, `pedido` y `detalle_pedido`
coinciden con los previos al respaldo, y `productos_invalidos` y `detalles_invalidos` dan 0. La consigna nombra la tabla
`cliente`; en esta base se llama `usuario`. Los respaldos se hicieron a mano; no hay tarea programada. Detalle,
problemas encontrados y mejora propuesta en `Datos para Facundo/Parte de Mariano para el informe/datos_para_informe.md`
y en el informe.

## Uso de OpenCode

Los scripts `.ps1` los genero OpenCode a partir de `SPEC_U6.md` y `AGENTS.md`. Se revisaron con la lista de preguntas
de `AGENTS.md` y se ejecutaron antes de aceptarlos; la ejecucion encontro dos errores que la lectura no habia visto
(`BITACORA.md` y el informe los detallan).
