# División de trabajo — TP Unidad 6 (Food Store)

Mantenimiento, respaldo y recuperación. Equipo de tres integrantes. Este documento dice **quién hace qué,
quién depende de quién y en qué orden** se avanza. Se actualiza si el reparto cambia.

## 0. Estado al 2026-10-20 y qué falta (leer esto primero)

Mariano terminó su parte y también `health_check.sql`. **Ahora sigue Andrés** (`maintenance.sql`); **Facundo** arma el
informe y puede empezar ya, porque sus valores salen de `datos_para_informe.md`, que está completo. Lo que figura
como hecho tiene evidencia en el repo.

| Tarea | Responsable | Estado |
|---|---|---|
| H0 entorno | Cada uno en su servidor | Mariano: hecho (`pgpass.conf` y `foodstore` con volumen: `evidencias/conteos_antes.txt`). Andrés: **falta confirmar** |
| H1 `SPEC_U6.md` | Mariano | Hecho |
| H2 `backup_foodstore.ps1` | Mariano | Hecho y probado (caso éxito y caso error) |
| H3a `health_check.sql` | Mariano | Hecho y ejecutado: `health_check.sql` y `evidencias/health_check_salida.txt` |
| H3b `maintenance.sql` | **Andrés** | **Falta** (ver su sección: tiene que justificarse con lo que él observe) |
| H4 simulacro (`restore_test.ps1`) | Mariano | Hecho: dos corridas, la oficial con RTO 6,19 s y RPO 1,45 h |
| Datos para el informe | Mariano | Hecho: `Datos para Facundo/Parte de Mariano para el informe/datos_para_informe.md` |
| H5 revisión cruzada | Andrés y Mariano | **Falta** (ver sección 6) |
| H6 `informe_u6.pdf` | **Facundo** | **Falta** (puede empezar ya) |
| H6 `README.md` | Mariano | Hecho |
| H6 bitácoras y `BITACORA.md` unificada | Los tres / Mariano | **Falta**: Andrés y Facundo entregan la suya; Mariano unifica |
| Revisión del informe | Andrés y Mariano | **Falta** (cuando Facundo lo entregue) |

### Orden para avanzar

1. **Andrés** (ahora): arma su entorno si no lo hizo, revisa el respaldo, observa el estado de sus tablas y hace
   `maintenance.sql`. Es lo único que bloquea la entrega de la Parte 3. Cuando termina, **le deja a Facundo una nota
   con lo que hizo** (paso 7 de su sección) y escribe su bitácora.
2. **Facundo** (en paralelo, sin esperar a nadie): arma `informe_u6.pdf` desde `datos_para_informe.md`, lee la nota
   de Andrés cuando llegue y escribe su bitácora.
3. **Mariano** (cuando `maintenance.sql` esté en `main` y Facundo entregue el informe): revisa `maintenance.sql`,
   revisa el informe junto con Facundo y decide con él si se agrega algo del monitoreo y del mantenimiento, y unifica
   `BITACORA.md`.
4. Los tres entregan su bitácora y **Mariano** unifica.

### Lo que Mariano ya dejó listo para usar

- `SPEC_U6.md` y `AGENTS.md` (con la lista de ocho preguntas para revisar código generado por IA).
- `backup_foodstore.ps1` y `restore_test.ps1`, con sus pruebas en `evidencias/`.
- `health_check.sql` (raíz del repo) y `evidencias/health_check_salida.txt` (su corrida en el servidor de Mariano).
- `Datos para Facundo/Parte de Mariano para el informe/datos_para_informe.md`: todos los valores del simulacro (respaldo
  usado, dos corridas, RPO y RTO, validaciones, los dos problemas reales, la mejora propuesta, uso de OpenCode). **El
  informe se arma desde ahí; no se inventa ningún valor.**
- `Para Facundo y Andres/PLANTILLA_bitacora.md` para la bitácora personal.

## 1. Reparto

| Integrante | A su cargo | Partes de la consigna |
|---|---|---|
| **Mariano Chirino** | `SPEC_U6.md` (Parte 1), `backup_foodstore.ps1` (Parte 2), `health_check.sql` (mitad de la Parte 3), **simulacro contra reloj** con RTO y RPO (Parte 4), `README.md`, revisión de `maintenance.sql` y del informe, y la **unificación de las bitácoras** | Partes 1, 2 y 4, y la mitad de la Parte 3 |
| **Andrés** | **`maintenance.sql`** (mitad de la Parte 3), revisión cruzada del respaldo y revisión del informe | La mitad de la Parte 3 |
| **Facundo** | **`informe_u6.pdf`** (Parte 5) | Parte 5 |

- La Parte 3 se divide: Mariano hizo el monitoreo (`health_check.sql`) y Andrés hace el mantenimiento
  (`maintenance.sql`).
- Si prefieren cambiar algo, se intercambia y se actualiza esta tabla.

## 2. Matriz de dependencias

| # | Tarea | Responsable | Necesita de… | Bloquea a… |
|---|---|---|---|---|
| H0 | Entorno propio listo (sección 4) | **Cada uno, en su servidor** | — | Todo lo que se ejecuta |
| H1 | `SPEC_U6.md` aprobado | **Mariano** | H0 | Hecho |
| H2 | `backup_foodstore.ps1` probado, un `.dump`, log y conteos previos | **Mariano** | H1 | Hecho |
| H3a | `health_check.sql` probado | **Mariano** | H1 | Hecho |
| H3b | `maintenance.sql` probado y justificado | **Andrés** | H0 propio y la observación de **su** servidor | La revisión de Mariano |
| H4 | Simulacro: restauración, validaciones, RTO y RPO | **Mariano** | H2 | Hecho |
| H5 | Revisión cruzada | **Andrés y Mariano** | H2, H3a, H3b y H4 | La entrega |
| H6 | `informe_u6.pdf` | **Facundo** | H4 (hecho) y `datos_para_informe.md` | La revisión del informe |

- **El informe de Facundo no depende de `maintenance.sql`.** La consigna no pide en el informe resultados de monitoreo
  ni de mantenimiento. Lo que se decida agregar sobre eso se decide **después**, cuando el informe esté hecho
  (Mariano y Facundo, con lo que entregue Andrés).
- **`maintenance.sql` depende de la observación del propio servidor de Andrés**, no de la de Mariano. Cada integrante
  tiene su PostgreSQL, y el estado de las tablas puede ser distinto.

## 3. Qué se entrega de uno a otro (puntos de traspaso)

| De | A | Qué | Dónde queda |
|---|---|---|---|
| Mariano | Andrés y Facundo | `SPEC_U6.md` final y `AGENTS.md` | raíz del repo |
| Mariano | Andrés | `health_check.sql` y su salida (referencia, no sustituye a la observación propia) | raíz y `evidencias/` |
| Mariano | Facundo | Tiempos del simulacro, antigüedad del respaldo, validaciones, problema real y mejora | `Datos para Facundo/Parte de Mariano para el informe/datos_para_informe.md` |
| Andrés | **Facundo** | **Nota de mantenimiento**: qué observó, qué acción eligió y por qué, qué resultado dio y qué asistió OpenCode (plantilla en el paso 7 de Andrés) | `Datos para Facundo/Parte de Andres para el informe/nota_mantenimiento.md` |
| Andrés | Mariano | `maintenance.sql`, sus dos salidas y su bitácora | raíz, `evidencias/` y `bitacoras/` |
| Facundo | Andrés y Mariano | `informe_u6.pdf` y su bitácora | raíz y `bitacoras/` |
| Los tres | Mariano | Su bitácora personal, para unificarla | `bitacoras/` |

## 4. Armado del entorno (H0): lo hace cada uno en su propio servidor

Cada integrante que ejecute algo crea la base de cero en pgAdmin 4, en este orden:

1. Crear la base `plantilla_food_store`. En su Query Tool ejecutar, **uno por vez y en este orden**:
   `base_heredada/schema.sql` → `base_heredada/objects.sql` → `base_heredada/data.sql`.
2. Desconectar la plantilla (nadie puede estar conectado a ella) y crear la base **`foodstore`** con
   *Template* = `plantilla_food_store`.
3. En `foodstore`, ejecutar en orden: `carga_masiva.sql` → `indices_semana3.sql` → `indices.sql` →
   `views.sql` → `materializadas.sql`.
4. Crear `pgpass.conf` en `%APPDATA%\postgresql\` con la línea `localhost:5432:*:postgres:<clave>`.
   **Ese archivo no va al repo** (el `.gitignore` ya lo excluye) y la clave no se escribe en ningún otro lado.
5. Comprobar que la base tiene volumen (sin volumen no hay nada que observar) y anotar los conteos en la
   bitácora personal: `usuario` ronda las 20.000 filas, `producto` supera las 50.000 y `pedido` las 200.000.

Hito H0 cumplido cuando el integrante tiene `foodstore` con datos y `pgpass.conf` funcionando
(`psql -h localhost -U postgres -d foodstore -w -c "SELECT 1"` responde sin pedir clave).
**Facundo no necesita armar la base para escribir el informe**: alcanza con el repo.

## 5. Qué hace cada uno, en detalle

### Andrés — `maintenance.sql` y revisión del respaldo (lo que sigue ahora)

Todos los comandos se escriben en **PowerShell, parado en la raíz del repo** (la carpeta `TP-Unidad6-BD2`), y se copia
**solo el comando**, sin el `PS C:\...>`. Si el repo está en otra ruta, no importa: lo que importa es estar en su raíz.
Las carpetas `Datos para Facundo` y `Para Facundo y Andres` llevan comillas en la consola por los espacios.

**Paso 1. Dejar el repo al día y el entorno listo.**
- En GitHub Desktop: *Fetch origin* y *Pull origin*. Tienen que aparecer `health_check.sql`, `restore_test.ps1` y las
  carpetas `evidencias/` y `Datos para Facundo/`.
- Si todavía no tiene `foodstore`, armarla con la sección 4 y dejar `pgpass.conf` funcionando.
- Anotar en la bitácora los conteos de su base (`categoria`, `usuario`, `producto`, `pedido`, `detalle_pedido`).

**Paso 2. Revisión cruzada del respaldo.** Correr el script de Mariano en **su** servidor y comprobar que no depende de
nada de la máquina de Mariano (rutas, usuario, clave):

```
.\backup_foodstore.ps1
```

- Tiene que terminar con `RESULTADO: OK`, generar un `.dump` y su `.sha256` en `backups\`, y un log en `logs\`.
- Si falla porque las herramientas de PostgreSQL están en otra carpeta, se pasa la ruta por parámetro
  (por ejemplo `-PgDump "C:\...\pg_dump.exe" -PgRestore "C:\...\pg_restore.exe"`). Eso **no es un error del script**: se
  anota igual en la bitácora.
- Aplicar la lista de ocho preguntas de `AGENTS.md` al script. Registrar en la bitácora qué revisó y qué encontró
  (si no encontró nada, también se anota). Si encuentra un problema, avisarle a Mariano: no se cambia el script sin avisar.

**Paso 3. Dejar lista la base descartable.** Correr el simulacro, que además crea y llena `foodstore_restore_test`:

```
.\restore_test.ps1
```

- Comparar contra `evidencias/restore_log_ok.txt`: los conteos tienen que coincidir con los de **su** `foodstore`,
  `productos_invalidos` y `detalles_invalidos` en 0, y RTO y RPO registrados. Anotar qué revisó y qué encontró.

**Paso 4. Observar el estado de sus tablas (esto es lo que justifica `maintenance.sql`).** Correr el monitoreo de
Mariano sobre **su** `foodstore`:

```
& "C:\Program Files\PostgreSQL\17\bin\psql.exe" -h localhost -U postgres -d foodstore -w -f .\health_check.sql -o .\evidencias\health_check_salida_andres.txt
```

- Si la carpeta de PostgreSQL es otra, se cambia la ruta de `psql.exe`.
- Para comprobar que el archivo se creó:
  `Get-ChildItem .\evidencias | Sort-Object LastWriteTime -Descending | Select-Object -First 3 Name, Length, LastWriteTime`
- Mirar sobre todo el **CONTROL 3** (estado de tablas) y el **CONTROL 5** (parámetros de autovacuum).

**Paso 5. Escribir `maintenance.sql`** en la raíz del repo. Requisitos de la consigna y de esta spec:

- **Observación previa:** estado de las tablas (`n_live_tup`, `n_dead_tup`, `n_mod_since_analyze`, `last_autovacuum`,
  `last_autoanalyze`) y configuración de autovacuum. Conviene calcular con esos parámetros el **umbral** al que
  autovacuum limpiaría cada tabla: `autovacuum_vacuum_threshold + autovacuum_vacuum_scale_factor * n_live_tup`, y
  compararlo con `n_dead_tup`.
- **Una acción segura y justificada por lo observado.** La justificación tiene que corresponder a la acción:
  - `VACUUM` elimina tuplas muertas: se justifica si `n_dead_tup` se acerca al umbral o autovacuum no corrió.
  - `ANALYZE` actualiza estadísticas: se justifica si `n_mod_since_analyze` es alto o `last_analyze` y
    `last_autoanalyze` están vacíos o viejos. **`ANALYZE` no limpia tuplas muertas.**
- **Sin `VACUUM FULL`** (bloqueo exclusivo; no es mantenimiento periódico). Si hace falta, `VACUUM (ANALYZE)` común.
- **Observación posterior** a la acción, para mostrar el efecto.
- **No inventar el motivo.** En el servidor de Mariano el estado es sano (como máximo 1 tupla muerta en `producto` y
  `n_mod_since_analyze` en 0 en todas las tablas): ahí **no hay nada que justifique** un `VACUUM` ni un `ANALYZE`
  sobre `foodstore`. En el de Andrés puede ser distinto: **se decide mirando su salida**. Si también está sano, hay dos
  caminos honestos, y se anota cuál se eligió y por qué:
  1. **Ensayo en `foodstore_restore_test`** (permitido: las pruebas destructivas van solo en la base descartable). Por
     ejemplo, una actualización masiva sobre `producto` que no cambie valores genera tuplas muertas; se observan, se
     corre `VACUUM` y se observa de nuevo. Se aclara en el script y en la bitácora que es un **ensayo**, no
     mantenimiento real. `foodstore` no se toca.
  2. **Decisión de no actuar sobre `foodstore`**, documentada con los números: lo observado no justifica la acción y
     autovacuum alcanza. Es lo más fiel a los datos, pero la consigna pide una acción, así que es más arriesgado.
- **`VACUUM` no corre dentro de una transacción**, y pgAdmin manda el script como una sola sentencia: **se ejecuta con
  `psql -f`**, no con el Query Tool. Por eso el script no usa `BEGIN`.
- Puede generarlo con OpenCode a partir de `SPEC_U6.md` y `AGENTS.md`, pasándole los requisitos de arriba y los
  números de su observación (son nombres de tablas y conteos, no datos personales). **No se abre `backups/` con
  OpenCode.** Se revisa con la lista de ocho preguntas y se ejecuta antes de aceptarlo.

**Paso 6. Ejecutarlo y guardar la salida.** Sobre la base donde se aplica la acción (`foodstore`, o
`foodstore_restore_test` si se eligió el ensayo; el nombre va en `-d`):

```
& "C:\Program Files\PostgreSQL\17\bin\psql.exe" -h localhost -U postgres -d foodstore_restore_test -w -f .\maintenance.sql -o .\evidencias\maintenance_salida.txt
```

Revisar que el archivo muestre las tres partes (antes, acción, después). `-o` evita que PowerShell 5.1 guarde el archivo
en UTF-16.

**Paso 7. Dejarle información a Facundo.** Facundo arma el informe y necesita saber, con valores reales, qué se hizo
en el mantenimiento. Andrés crea el archivo `Datos para Facundo/Parte de Andres para el informe/nota_mantenimiento.md`
(carpeta con espacios: va entre comillas en la consola) y lo sube a `main`. Tiene que decir, cada dato con el
archivo de `evidencias/` que lo respalda:

| Dato | Qué escribir | Evidencia |
|---|---|---|
| Base y fecha | Dónde se aplicó la acción (`foodstore` o `foodstore_restore_test`) y cuándo | `maintenance_salida.txt` |
| Observación previa | Tablas con más tuplas muertas, `n_mod_since_analyze`, `last_autovacuum` y `last_autoanalyze` (los números de **su** servidor) | `health_check_salida_andres.txt` |
| Parámetros de autovacuum | Valores que vio (umbral y factor) y el umbral calculado | `health_check_salida_andres.txt` |
| Acción elegida | Cuál (`VACUUM`, `ANALYZE` o ninguna) y **por qué**, con los números que la justifican | `maintenance.sql` y su salida |
| Resultado | Qué cambió en la observación posterior | `maintenance_salida.txt` |
| Problema real, si lo hubo | Qué falló, cómo se detectó y cómo se resolvió. Si no hubo, escribir "no ocurrió" | su bitácora |
| Uso de OpenCode | Qué parte asistió, qué prompt, qué devolvió, qué se corrigió y cómo se verificó antes de aceptarlo | su bitácora |

Reglas de la nota: solo valores **observados**, nada estimado ni copiado de otro servidor, y si algo no ocurrió se
escribe "no ocurrió". Si Andrés eligió el ensayo en `foodstore_restore_test`, la nota lo dice así: es un ensayo, no
mantenimiento real. Después le avisa a Facundo que la nota está subida.

**Paso 8. Revisión del informe**, cuando Facundo lo entregue: cada valor del informe tiene que tener su evidencia en
`evidencias/` o en `datos_para_informe.md`, y el informe tiene que diferenciar **RPO** de **RTO**.

**Paso 9. Bitácora personal (obligatoria para este equipo):** `bitacoras/bitacora_andres.md`, desde
`Para Facundo y Andres/PLANTILLA_bitacora.md`. Qué tiene que tener, sección por sección, está en la sección 8 de este
documento. Se escribe **a medida que se hace cada paso**, no al final de memoria.

**Paso 10. Git:** rama `parte-3b-maintenance`, commits descriptivos (`feat(mantenimiento): ...`), Pull Request a
`main`. Subir `maintenance.sql`, `evidencias/health_check_salida_andres.txt`, `evidencias/maintenance_salida.txt`, la
nota para Facundo y la bitácora. **No subir** `backups/`, `logs/` ni ningún `.dump`. Avisarle a Mariano cuando esté.

**Qué entrega Andrés:**
- **A Mariano:** `maintenance.sql` en `main`, las dos salidas y su bitácora con la revisión del respaldo y del simulacro.
- **A Facundo:** la nota `nota_mantenimiento.md` (paso 7).

### Facundo — `informe_u6.pdf` (puede empezar ya)

1. **Dejar el repo al día:** en GitHub Desktop, *Fetch origin* y *Pull origin*.
2. **Leer** `Datos para Facundo/Parte de Mariano para el informe/datos_para_informe.md`. Ahí están todos los valores del
   simulacro, cada uno con el archivo de `evidencias/` que lo respalda.
3. **Armar `informe_u6.pdf` (una página como máximo)**, entregado como PDF. Tiene que incluir:
   - fecha y hora del respaldo usado (2026-10-18 09:49:32, `foodstore_20261018_094932.dump`);
   - tiempo total de restauración y validación (**RTO observado**) y **RPO observado**, **diferenciados**, junto con los
     **previstos** (RPO hasta 24 h, RTO menos de 20 min);
   - resultado de las validaciones de tablas y de las restricciones lógicas;
   - **un problema real** encontrado (hubo dos: línea 43 del respaldo y línea 152 de la restauración);
   - **una mejora concreta** (respaldar roles con `pg_dumpall --globals-only --no-role-passwords`);
   - qué parte asistió OpenCode y cómo se verificó antes de aceptarla (sección 7 de `datos_para_informe.md`);
   - la aclaración de que la consigna dice `cliente` y en esta base la tabla se llama `usuario`;
   - como se hicieron dos corridas del simulacro, informar las dos y marcar cuál es la oficial.
4. **No inventar valores:** los que no estén en `evidencias/` o en `datos_para_informe.md`, no van. Las filas de monitoreo
   y mantenimiento de la tabla de OpenCode se dejan para la revisión conjunta con Mariano. **La nota de Andrés**
   (`Datos para Facundo/Parte de Andres para el informe/nota_mantenimiento.md`) es el insumo de esa revisión: Facundo
   la lee cuando llegue y, si se decide agregar el mantenimiento al informe, los valores salen de ahí. Si Andrés
   todavía no la dejó, no se escribe nada de mantenimiento: se le pide.
5. **Comprobar que entra en una página** al exportar el PDF. Si no entra, se resume (tablas compactas); no se achica la
   letra hasta que no se lea.
6. **Bitácora personal (obligatoria para este equipo):** `bitacoras/bitacora_facundo.md`, desde
   `Para Facundo y Andres/PLANTILLA_bitacora.md`. Qué tiene que tener, sección por sección, está en la sección 8 de este
   documento. Anotar lo que realmente pasó, incluido si usó una IA para redactar el informe y cómo revisó cada valor
   contra la evidencia. Se escribe mientras se hace el informe, no al final.
7. **Git:** rama `parte-5-informe`, commits descriptivos (`docs(informe): ...`), Pull Request a `main`. Subir
   `informe_u6.pdf` y la bitácora. Avisarle a Mariano y a Andrés cuando esté.

### Mariano: lo que queda (depende de los otros dos)

1. **Revisar `maintenance.sql`** de Andrés: correrlo y validar que la acción esté justificada por lo observado.
2. **Revisar el informe de Facundo** junto con él y decidir si se agrega algo del monitoreo (`health_check.sql`) y del
   mantenimiento, y completar esas filas de la tabla de OpenCode si se decide agregarlas.
3. **Corregir `datos_para_informe.md`, sección 7:** las filas de la tabla de OpenCode dicen que `health_check.sql` es de
   Andrés y `maintenance.sql` de Facundo. Ahora `health_check.sql` es de Mariano (generado con Claude, no con
   OpenCode) y `maintenance.sql` es de Andrés.
4. **Unificar `BITACORA.md`**, comparando cada fila contra la evidencia, cuando lleguen las bitácoras de Andrés y Facundo.
5. **Revisión final del repo antes de entregar:** sin contraseñas, sin `.dump` ni logs sin revisar, informe en PDF,
   todos los entregables en `main`.

### Reglas que valen para todos

- Sin contraseñas en ningún archivo ni commit. `pgpass.conf` queda fuera del repo.
- `foodstore` solo se lee salvo un `VACUUM` o `ANALYZE` común justificado; las pruebas destructivas van solo en
  `foodstore_restore_test`.
- El código de OpenCode se revisa y se ejecuta antes de aceptarse; en la bitácora se anota lo que realmente pasó,
  incluso si OpenCode no se equivocó.
- No abrir ni pegar `backups/*.dump` en ninguna IA.
- Cada integrante tiene su propio PostgreSQL: no se asume que la configuración de otro servidor se hereda.

## 6. Revisión cruzada

| Se revisa | Lo revisa | Cómo |
|---|---|---|
| `SPEC_U6.md` | Andrés | Que sea implementable y que las condiciones de éxito se puedan comprobar |
| `backup_foodstore.ps1` | Andrés | Lo corre en su servidor y aplica la lista de revisión de `AGENTS.md` |
| `health_check.sql` | Andrés | Lo corre en su servidor; su salida es la observación previa de `maintenance.sql` |
| `maintenance.sql` | Mariano | Lo corre y valida que la acción esté justificada por lo observado |
| Simulacro y `restore_test.ps1` | Andrés | Lo repite en su servidor y compara contra la evidencia |
| `informe_u6.pdf` | Andrés y Mariano | Que cada valor del informe tenga evidencia en `evidencias/` y que RPO y RTO estén diferenciados |

Cada revisor registra en su bitácora qué revisó y qué encontró. Si no encontró nada, también se anota.

## 7. Trabajo con Git

- Una rama por parte para Andrés y Facundo: `parte-3b-maintenance` y `parte-5-informe`. **Mariano commitea sus partes
  directo en `main`**, que es la que usa.
- Se mergea por Pull Request a `main`. Las ramas se crean a partir de `main` actualizada (*Fetch* y *Pull* antes).
- Mensajes de commit descriptivos: `feat(mantenimiento): ...`, `docs(informe): ...`. Un commit por entregable, y los
  arreglos con un mensaje que diga qué se arregló. Evitar mensajes como "arreglos" o "cambios".
- Sin contraseñas, respaldos ni logs sin revisar en ningún commit.

## 8. Bitácora: qué tiene que hacer cada uno

La consigna no la pide, pero este equipo la lleva para poder volver a ver qué se hizo y por qué, y porque **Mariano
unifica todas en `BITACORA.md`**. Si falta la de alguno, esa parte queda sin registro. **Andrés y Facundo tienen que
hacer la suya.**

**Cómo se empieza (los dos):**
1. Copiar `Para Facundo y Andres/PLANTILLA_bitacora.md` a `bitacoras/bitacora_andres.md` o
   `bitacoras/bitacora_facundo.md`, y poner el nombre en el título.
2. Completar **solo lo que corresponde a su parte**; las secciones que no apliquen se dejan vacías o se borran.
3. Escribirla **a medida que se trabaja**: cada paso, cuando se termina.
4. Subirla en la misma rama que el resto de su trabajo (`parte-3b-maintenance` o `parte-5-informe`).

**Reglas (valen para los dos):**
- Se anota lo que **realmente pasó**. Si OpenCode no se equivocó, se escribe que no se equivocó.
- Las respuestas de la IA se **resumen fielmente**: si dijo "potencial", no se anota "confirmado".
- Nunca contraseñas ni datos que no deban estar en el repo.
- Mariano compara cada fila contra la evidencia antes de unificar: lo que no tenga respaldo en `evidencias/` o en el
  repo se corrige o se saca.

**Qué va en cada sección de la plantilla:**

| Sección | Andrés | Facundo |
|---|---|---|
| Mi parte | `maintenance.sql`, revisión cruzada del respaldo y del simulacro, revisión del informe | `informe_u6.pdf` |
| Mi entorno (H0) | Versión de PostgreSQL, conteos de su `foodstore`, problemas al armarla | Solo si armó la base; si no, "no armé la base: el informe sale del repo" |
| Interacciones con OpenCode | Prompt que le dio para `maintenance.sql`, qué devolvió, qué corrigió o aceptó y cómo lo verificó (ocho preguntas, ejecución) | Si usó una IA para redactar el informe: qué pidió, qué devolvió y cómo revisó cada valor. Si no usó ninguna, lo anota |
| Revisión cruzada que hice | Respaldo y simulacro en **su** servidor, y el informe: qué revisó y qué encontró (si no encontró nada, también se anota) | La revisión del informe la hace Andrés; Facundo anota los cambios que le pidieron y qué hizo |
| Mediciones | Estado de sus tablas (antes y después), RTO y RPO que midió en su servidor | Los valores del informe y de qué archivo salió cada uno |
| Problemas encontrados | Fecha, problema, causa y solución | Ídem |
| Decisiones tomadas | Qué acción de mantenimiento eligió y por qué (alternativas: ensayo, no actuar) | Qué incluyó y qué dejó fuera del informe, y por qué |

**Cuándo se entrega:** apenas cada uno termina su parte, no al final de todo. Mariano no puede unificar `BITACORA.md`
hasta que estén las de los dos.
