# TP Unidad 6 - Food Store: mantenimiento, respaldo y recuperacion

[![Repositorio en GitHub](https://img.shields.io/badge/GitHub-TP--Unidad6--BD2-181717?logo=github&logoColor=white)](https://github.com/marianoemir/TP-Unidad6-BD2)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16%2B-336791?logo=postgresql&logoColor=white)
![PowerShell](https://img.shields.io/badge/PowerShell-5.1-5391FE?logo=powershell&logoColor=white)

> 📦 **Repositorio del trabajo:** [github.com/marianoemir/TP-Unidad6-BD2](https://github.com/marianoemir/TP-Unidad6-BD2)

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
| `health_check.sql` | Consultas de monitoreo (tamano, conexiones, estado de tablas, consultas activas) | Mariano |
| `maintenance.sql` | Revision de autovacuum/ANALYZE y accion de mantenimiento justificada | Andres (version original); correccion y corrida final: Mariano |
| `restore_test.ps1` | Simulacro de restauracion con cronometro y validaciones (opcional en la consigna) | Mariano |
| `informe_u6.pdf` | Informe post-incidente de una pagina | Equipo |

Material de apoyo: `evidencias/` (copias de logs, conteos y salidas de los scripts), `BITACORA.md` (registro de lo
hecho), `AGENTS.md` y `.kiro/steering/` (reglas del proyecto para la IA), `base_heredada/` (los `.sql` de Food Store de
las unidades anteriores, sin modificar).

## Requisitos

- PostgreSQL 16+ con las herramientas `pg_dump`, `pg_restore`, `createdb`, `dropdb` y `psql`. No estan en el PATH:
  los scripts las buscan por parametro (por defecto `C:\Program Files\PostgreSQL\17\bin\`).
- La base `foodstore` cargada (orden de armado en `AGENTS.md`, seccion "Como se arma `foodstore`").
- **Sin contrasenas en el repo.** La clave va en `%APPDATA%\postgresql\pgpass.conf` (fuera del repo, ignorado por
  `.gitignore`) con una linea `localhost:5432:*:postgres:<clave>`; las herramientas se invocan con `-w`.

## Uso

Desde PowerShell, en la raiz del repo:

```
.\backup_foodstore.ps1
.\restore_test.ps1
& "C:\Program Files\PostgreSQL\17\bin\psql.exe" -h localhost -U postgres -d foodstore -w -f .\health_check.sql
& "C:\Program Files\PostgreSQL\17\bin\psql.exe" -h localhost -U postgres -d foodstore_restore_test -w -f .\maintenance.sql
```

- `backup_foodstore.ps1` escribe `backups\foodstore_AAAAMMDD_HHMMSS.dump` (primero como `.parcial`, renombrado al
  final), su `.sha256` y un log en `logs\`. Verifica el respaldo con `pg_restore --list` y termina con codigo 1 si falla.
- `restore_test.ps1` toma el **ultimo** `.dump`, crea `foodstore_restore_test` (si existia, la elimina antes del
  cronometro), restaura con `--no-owner --no-privileges`, ejecuta las validaciones y registra RTO y RPO en `logs\`.
  Se niega a actuar si el destino es `foodstore`.
- `health_check.sql` es de solo lectura. `maintenance.sql` se ejecuta con `psql -f` (no con el Query Tool de pgAdmin, porque
  `VACUUM` no corre dentro de una transaccion) y trabaja solo sobre `foodstore_restore_test`.
- `backups\` y `logs\` son locales y no se versionan; la evidencia se entrega como copia en `evidencias/`.

## Resultados observados (2026-10-18)

| | Previsto | Observado |
|---|---|---|
| RPO | hasta 24 h | 1,45 h (respaldo de las 09:49:32; simulacro iniciado a las 11:16:42) |
| RTO | menos de 20 min | 6,19 s (corrida oficial; la primera corrida, con un error del script, dio 5,51 s) |

Validaciones despues de restaurar: los conteos de `categoria`, `usuario`, `producto`, `pedido` y `detalle_pedido`
coinciden con los previos al respaldo, y `productos_invalidos` y `detalles_invalidos` dan 0. La consigna nombra la tabla
`cliente`; en esta base se llama `usuario`. Los respaldos se hicieron a mano; no hay tarea programada. Detalle,
problemas encontrados y mejora propuesta en el informe y en `evidencias/`.

## Uso de OpenCode

Los scripts `.ps1` y la primera version de `maintenance.sql` los genero OpenCode a partir de `SPEC_U6.md` y `AGENTS.md`;
`health_check.sql` se hizo con Claude. Todo se reviso con la lista de preguntas de `AGENTS.md` y se ejecuto antes de aceptarlo:
la ejecucion encontro dos errores en los `.ps1` que la lectura no habia visto, y la salida de `maintenance.sql` mostro un
retraso en las estadisticas que se corrigio (`BITACORA.md` y el informe lo detallan).
