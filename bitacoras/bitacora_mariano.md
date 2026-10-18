# Bitácora personal — Mariano Chirino

Registro de lo que hice y por qué, para poder volver a consultarlo. Se unifica al final en `BITACORA.md`.

Reglas de uso:
- Anoto lo que realmente pasó. Si OpenCode no se equivoca, escribo que no se equivocó.
- Resumo las respuestas, no las copio completas.
- Sin contraseñas ni datos que no deban estar en el repo.

## Mi parte

Según `DIVISION_DE_TRABAJO.md`: `SPEC_U6.md` (Parte 1), `backup_foodstore.ps1` (Parte 2), simulacro con RTO y RPO
(Parte 4), `README.md`, corrida oficial, `evidencias/datos_para_informe.md` y unificación de las bitácoras.

## Herramientas que uso

| Herramienta | Para qué |
|---|---|
| Claude (claude.ai) | Armar `SPEC_U6.md`, `AGENTS.md`, los archivos de Kiro, `DIVISION_DE_TRABAJO.md`, las plantillas de bitácora y de datos para el informe, y guiarme paso a paso con los comandos |
| OpenCode | Generar `backup_foodstore.ps1` (y `restore_test.ps1` si lo hago) a partir de `SPEC_U6.md` y `AGENTS.md` |
| pgAdmin 4, `psql` | Armar la base y consultar |

## Mi entorno (H0)

| Servidor y versión | Conteos de `usuario`, `producto`, `pedido` | Problemas y cómo se resolvieron |
|---|---|---|
| PostgreSQL 17, Windows, `localhost:5432`. Base `foodstore`. **[CONFIRMAR: si la armé de cero esta vez o ya existía]** | `usuario` 20.006, `producto` 50.016, `pedido` 200.006 (2026-10-18) | `psql -w` dio `fe_sendauth: no password supplied`: faltaba `pgpass.conf`. Lo creé en `%APPDATA%\postgresql\` con una línea `localhost:5432:*:postgres:<clave>`. Comprobé que el archivo existe con ese nombre exacto (32 bytes, no `.txt`) y repetí la consulta: respondió sin pedir clave |

## Interacciones con OpenCode

| Prompt enviado a la IA | Respuesta relevante recibida (resumida) | Validación o corrección humana aplicada |
|---|---|---|
| Generar `backup_foodstore.ps1` a partir de `SPEC_U6.md` y `AGENTS.md`: parámetros con valores por defecto, `.parcial` renombrado al final, `pg_dump -Fc -w -v`, sin contraseña ni `PGPASSWORD`, log con `Add-Content -Encoding ASCII`, error con `exit 1` si falla, `pg_restore --list` y SHA-256, ASCII puro. Pedí que **no ejecutara nada**. (Prompt preparado con Claude) | Script con parámetros, carpetas desde `$PSScriptRoot`, `.parcial` renombrado al final, verificación con `pg_restore --list`, SHA-256, log ASCII y salida con `exit 1` en los errores, más una lista de cuatro supuestos | Lo revisé con la lista de ocho preguntas de `AGENTS.md` (con Claude): sin hallazgos de seguridad (sin contraseñas, solo borra su propio `.parcial`, sin bloqueos exclusivos). Quedaron tres ajustes: comprobar tamaño mayor a cero (lo exige la spec), no volcar al log todo el `pg_restore --list` y mostrar un `RESULTADO` por consola. Observación: se conecta como `postgres` (superusuario) |
| Seguimiento: aplicar solo esos tres ajustes y mostrar el diff, sin ejecutar nada | Dijo que los cambios **ya estaban aplicados** en el archivo y mostró el diff. El texto que yo había recibido antes no los tenía | No acepté su palabra: verifiqué el archivo real. `Select-String 'RESULTADO'` dio 8 (siete errores y el éxito), no hay caracteres no ASCII, la primera línea es `<#` y la última `exit 0` |
| (No es un prompt) Primera ejecución de `backup_foodstore.ps1` | PowerShell rechazó el archivo: `ParserError` en la línea 43, `'$Servidor:$Puerto'` se interpreta como una referencia a una unidad (como `C:`) y es sintaxis inválida | **Corrección humana.** Lo cambié a `${Servidor}:${Puerto}` con un `Replace` y repetí la prueba. Lo detectó el intérprete, no la lectura: ni mi revisión con la lista de preguntas ni la ayuda de Claude lo vieron |

## Interacciones con Claude (fuera de OpenCode)

| Qué pedí | Qué entregó (resumido) | Qué hice con eso |
|---|---|---|
| `SPEC_U6.md` de una página con tareas, frecuencia, condición de éxito, RPO y RTO previstos y reglas de seguridad | Spec de 52 líneas con tabla de tareas, objetivos de recuperación (RPO hasta 24 h, RTO menos de 20 min), convenciones, reglas y límites | La dejé en la raíz del repo para commitearla en `main` |
| Revisión de `backup_foodstore.ps1` con las ocho preguntas de `AGENTS.md` | Tabla pregunta por pregunta, sin hallazgos de seguridad y tres ajustes recomendados. **No detectó el error de sintaxis de la línea 43** | Corrí el script y apareció el `ParserError`; lo corregí (ver arriba) |
| Pasos para armar el entorno y guardar los conteos previos | Comandos de PowerShell para `pgpass.conf` y para escribir `evidencias/conteos_antes.txt` con `Out-File -Encoding ASCII` (por el UTF-16 de PowerShell 5.1) | Los ejecuté y comprobé la salida: `pgpass.conf` funciona y el archivo de conteos tiene siete filas con los dos controles de inválidos en 0 |

## Revisión cruzada que hice

| Qué revisé | En qué servidor lo ejecuté | Qué encontré |
|---|---|---|
| (Pendiente: `maintenance.sql` de Facundo) | | |

## Mediciones (valores observados, no estimados)

| Dato | Valor | Cómo se midió |
|---|---|---|
| Conteos antes del respaldo | `categoria` 6, `usuario` 20.006, `producto` 50.016, `pedido` 200.006, `detalle_pedido` 400.013, `productos_invalidos` 0, `detalles_invalidos` 0 | Consulta con `psql` sobre `foodstore`, guardada en `evidencias/conteos_antes.txt` el 2026-10-18 a las 09:35 |
| Archivo de respaldo, tamaño y hora | Primer respaldo válido: `foodstore_20261018_094708.dump`, 10.650.048 bytes, 2026-10-18 09:47. SHA-256: `54F84A53664A84D3C25844BA60B5641FCB710A46F2E6CA0F43D0BD41BFB895FA`. Segundo respaldo: `foodstore_20261018_094932.dump` (tamaño pendiente de anotar) | Log de la ejecución (`Tamano: 10650048 bytes`) y `dir .\backups` |
| Prueba del script, caso éxito | `RESULTADO: OK`, `$LASTEXITCODE` 0 (segunda corrida), `.dump` y `.dump.sha256` sin `.parcial`, `pg_restore --list` de 74 líneas | Consola y log |
| Prueba del script, caso error (`-Base foodstore_no_existe`) | `RESULTADO: ERROR - pg_dump fallo con codigo 1`, `$LASTEXITCODE` 1, el log registra el `FATAL` y "Archivo parcial eliminado"; `backups\` sin `.parcial` | Consola, `dir .\backups` y log |
| Conteos después de restaurar | Pendiente | |
| RTO observado | Pendiente | |
| Antigüedad del respaldo (RPO observado) | Pendiente | |

## Problemas encontrados y cómo se resolvieron

| Fecha | Problema | Causa | Solución |
|---|---|---|---|
| 2026-10-18 | `psql -w` falló con `no password supplied` | No existía `pgpass.conf` | Crearlo en `%APPDATA%\postgresql\` con una línea de la forma `host:puerto:base:usuario:clave` |
| 2026-10-18 | `backup_foodstore.ps1` no arrancó: `ParserError` en la línea 43 | OpenCode escribió `'$Servidor:$Puerto'`; PowerShell interpreta `$Servidor:` como una unidad | Reemplazar por `${Servidor}:${Puerto}`. No se ejecutó nada del script antes del arreglo: no hubo respaldo, log ni `.parcial` |

## Decisiones tomadas

| Decisión | Alternativas | Por qué |
|---|---|---|
| Reparto con la carga más pesada para mí: spec, respaldo, simulacro, README y unificación de bitácoras. Andrés hace `health_check.sql` y Facundo `maintenance.sql` e informe | Que yo escribiera también el informe | Concentrar las partes que condicionan al resto y que Facundo arme el informe a partir de lo que yo anoto |
| Anotar los datos del simulacro en `evidencias/datos_para_informe.md` y que Facundo estructure el informe | Que Facundo repita todo el simulacro para conseguir los datos | Los valores solo salen de mi ejecución; así el informe no estima nada |
| Cada integrante lleva su bitácora personal y las unifico al final | Un solo archivo compartido | Evitar conflictos al mergear |
| Commitear la spec directo en `main`, que es la rama que uso | Rama `parte-1-spec` | Es lo primero que tiene que estar y lo necesitan los otros dos |
| Guardar los conteos previos con `Out-File -Encoding ASCII` | Redirección con `>` | En PowerShell 5.1 `>` escribe UTF-16 |
