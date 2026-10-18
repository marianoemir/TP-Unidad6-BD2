<#
.SYNOPSIS
    Script de restauracion de prueba para la base de datos foodstore.
.DESCRIPTION
    Restaura el ultimo respaldo (.dump) de foodstore en la base descartable
    foodstore_restore_test, valida los conteos, mide el RTO y calcula el RPO
    observado. Nunca actua sobre la base foodstore.
#>

param (
    [string]$Createdb = "C:\Program Files\PostgreSQL\17\bin\createdb.exe",
    [string]$Dropdb = "C:\Program Files\PostgreSQL\17\bin\dropdb.exe",
    [string]$PgRestore = "C:\Program Files\PostgreSQL\17\bin\pg_restore.exe",
    [string]$Psql = "C:\Program Files\PostgreSQL\17\bin\psql.exe",
    [string]$Servidor = "localhost",
    [int]$Puerto = 5432,
    [string]$Usuario = "postgres",
    [string]$BaseDestino = "foodstore_restore_test",
    [string]$DirBackups = "$PSScriptRoot\backups",
    [string]$DirLogs = "$PSScriptRoot\logs"
)

# Nombre fijo y unico permitido como destino de la restauracion
$NombrePermitido = "foodstore_restore_test"

# Asegurar que la carpeta de logs exista
if (-not (Test-Path -LiteralPath $DirLogs)) {
    New-Item -ItemType Directory -Path $DirLogs -Force | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$rutaLog = Join-Path $DirLogs "restore_$timestamp.log"

# Funcion auxiliar para escribir en el log con codificacion ASCII
function Escribir-Log {
    param ([string]$Mensaje)
    $fechaHora = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $linea = "$fechaHora - $Mensaje"
    Add-Content -Path $rutaLog -Value $linea -Encoding ASCII
}

# Funcion auxiliar para ejecutar una consulta escalar con psql y devolver el valor
function Consultar-Psql {
    param (
        [string]$Etiqueta,
        [string]$Consulta,
        [string]$BaseDatos
    )
    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $resultado = & $Psql -w -h $Servidor -p $Puerto -U $Usuario -d $BaseDatos -t -A -c $Consulta 2>&1
        $codigo = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $oldPreference
    }
    if ($codigo -ne 0) {
        Escribir-Log "ERROR - psql fallo al consultar ${Etiqueta} (codigo $codigo)."
        foreach ($lin in $resultado) {
            Escribir-Log "PSQL: $lin"
        }
        return $null
    }
    return ([string]$resultado).Trim()
}

Escribir-Log "INICIO - Iniciando simulacro de restauracion."

# Regla de seguridad: solo se restaura en foodstore_restore_test
if ($BaseDestino -ne $NombrePermitido) {
    Escribir-Log "ERROR - Base destino no permitida: '$BaseDestino'. Solo se permite '$NombrePermitido'."
    Write-Host "RESULTADO: ERROR - Base destino no permitida ('$BaseDestino')"
    exit 1
}

# Validar que los ejecutables existan
if (-not (Test-Path -LiteralPath $Createdb)) {
    Escribir-Log "ERROR - No se encontro el ejecutable createdb en la ruta: $Createdb"
    Write-Host "RESULTADO: ERROR - No se encontro el ejecutable createdb"
    exit 1
}
if (-not (Test-Path -LiteralPath $Dropdb)) {
    Escribir-Log "ERROR - No se encontro el ejecutable dropdb en la ruta: $Dropdb"
    Write-Host "RESULTADO: ERROR - No se encontro el ejecutable dropdb"
    exit 1
}
if (-not (Test-Path -LiteralPath $PgRestore)) {
    Escribir-Log "ERROR - No se encontro el ejecutable pg_restore en la ruta: $PgRestore"
    Write-Host "RESULTADO: ERROR - No se encontro el ejecutable pg_restore"
    exit 1
}
if (-not (Test-Path -LiteralPath $Psql)) {
    Escribir-Log "ERROR - No se encontro el ejecutable psql en la ruta: $Psql"
    Write-Host "RESULTADO: ERROR - No se encontro el ejecutable psql"
    exit 1
}

# Buscar el ultimo respaldo .dump por fecha (se ignoran los .parcial)
if (-not (Test-Path -LiteralPath $DirBackups)) {
    Escribir-Log "ERROR - No existe la carpeta de respaldos: $DirBackups"
    Write-Host "RESULTADO: ERROR - No existe la carpeta de respaldos"
    exit 1
}

$archivosDump = @(Get-ChildItem -LiteralPath $DirBackups -File |
    Where-Object { $_.Name -like "*.dump" -and $_.Name -notlike "*.parcial" } |
    Sort-Object Name -Descending)

if ($archivosDump.Count -eq 0) {
    Escribir-Log "ERROR - No se encontro ningun respaldo .dump en $DirBackups"
    Write-Host "RESULTADO: ERROR - No hay respaldos disponibles"
    exit 1
}

$archivoRestore = $archivosDump[0].FullName
Escribir-Log "INFO - Respaldo seleccionado: $archivoRestore"

# Extraer la fecha de creacion del respaldo desde el nombre AAAAMMDD_HHMMSS
$nombreSinExt = [System.IO.Path]::GetFileNameWithoutExtension($archivoRestore)
if ($nombreSinExt -match "^foodstore_(\d{8}_\d{6})$") {
    $horaDump = [datetime]::ParseExact($Matches[1], "yyyyMMdd_HHmmss", [System.Globalization.CultureInfo]::InvariantCulture)
}
else {
    Escribir-Log "ERROR - El nombre del respaldo no contiene una fecha valida: $nombreSinExt"
    Write-Host "RESULTADO: ERROR - Nombre de respaldo sin fecha valida"
    exit 1
}

# Verificar si la base destino ya existe (ANTES de arrancar el cronometro)
Escribir-Log "INFO - Verificando si existe la base destino '$BaseDestino'."

$oldPreference = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
try {
    $resultadoExiste = & $Psql -w -h $Servidor -p $Puerto -U $Usuario -d postgres -t -A -c "SELECT 1 FROM pg_database WHERE datname = '$BaseDestino';" 2>&1
    $codigoExiste = $LASTEXITCODE
}
finally {
    $ErrorActionPreference = $oldPreference
}

if ($codigoExiste -ne 0) {
    Escribir-Log "ERROR - No se pudo verificar la existencia de la base destino (codigo $codigoExiste)."
    foreach ($lin in $resultadoExiste) {
        Escribir-Log "PSQL: $lin"
    }
    Write-Host "RESULTADO: ERROR - No se pudo verificar la base destino"
    exit 1
}

$existeBase = ("$resultadoExiste".Trim() -eq "1")

if ($existeBase) {
    Escribir-Log "INFO - La base destino ya existe. Eliminando '$BaseDestino' con dropdb (fuera del cronometro)."

    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $salidaDrop = & $Dropdb -w -h $Servidor -p $Puerto -U $Usuario $BaseDestino 2>&1
        $codigoDrop = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $oldPreference
    }

    if ($codigoDrop -ne 0) {
        Escribir-Log "ERROR - dropdb fallo con codigo $codigoDrop."
        foreach ($lin in $salidaDrop) {
            Escribir-Log "DROP_DB: $lin"
        }
        Write-Host "RESULTADO: ERROR - No se pudo eliminar la base destino previa"
        exit 1
    }
    Escribir-Log "OK - Base destino previa eliminada."
}
else {
    Escribir-Log "INFO - La base destino no existe. Se creara desde cero."
}

# Arranque del cronometro: inmediatamente antes de crear la base
$horaInicioSimulacro = Get-Date
$cronometro = [System.Diagnostics.Stopwatch]::StartNew()
Escribir-Log "INFO - Hora de inicio del simulacro: $($horaInicioSimulacro.ToString('yyyy-MM-dd HH:mm:ss'))"

# Crear la base destino
Escribir-Log "INFO - Creando base destino '$BaseDestino'."

$oldPreference = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
try {
    $salidaCreatedb = & $Createdb -w -h $Servidor -p $Puerto -U $Usuario $BaseDestino 2>&1
    $codigoCreatedb = $LASTEXITCODE
}
finally {
    $ErrorActionPreference = $oldPreference
}

if ($codigoCreatedb -ne 0) {
    $cronometro.Stop()
    Escribir-Log "ERROR - createdb fallo con codigo $codigoCreatedb."
    foreach ($lin in $salidaCreatedb) {
        Escribir-Log "CREATEDB: $lin"
    }
    Write-Host "RESULTADO: ERROR - createdb fallo con codigo $codigoCreatedb"
    exit 1
}

Escribir-Log "OK - Base destino creada. Restaurando respaldo."

# Restaurar el respaldo con pg_restore
$oldPreference = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
try {
    $salidaRestore = & $PgRestore -w -h $Servidor -p $Puerto -U $Usuario -d $BaseDestino --no-owner --no-privileges $archivoRestore 2>&1
    $codigoRestore = $LASTEXITCODE
}
finally {
    $ErrorActionPreference = $oldPreference
}

if ($codigoRestore -ne 0) {
    $cronometro.Stop()
    Escribir-Log "ERROR - pg_restore fallo con codigo $codigoRestore."
    foreach ($lin in $salidaRestore) {
        Escribir-Log "PG_RESTORE: $lin"
    }
    Write-Host "RESULTADO: ERROR - pg_restore fallo con codigo $codigoRestore"
    exit 1
}

Escribir-Log "OK - pg_restore finalizo correctamente. Iniciando validaciones."

# Validacion: conteos de las tablas principales
$consultasConteo = [ordered]@{
    'categoria'      = 'SELECT count(*) FROM categoria;'
    'usuario'        = 'SELECT count(*) FROM usuario;'
    'producto'       = 'SELECT count(*) FROM producto;'
    'pedido'         = 'SELECT count(*) FROM pedido;'
    'detalle_pedido' = 'SELECT count(*) FROM detalle_pedido;'
}

$conteos = [ordered]@{}
$fallo = $false

foreach ($clave in $consultasConteo.Keys) {
    $valor = Consultar-Psql -Etiqueta $clave -Consulta $consultasConteo[$clave] -BaseDatos $BaseDestino
    if ($null -eq $valor) {
        $fallo = $true
        break
    }
    $conteos[$clave] = $valor
}

# Validacion: controles de registros invalidos (deben dar cero)
if (-not $fallo) {
    $productosInvalidos = Consultar-Psql -Etiqueta 'productos_invalidos' -Consulta 'SELECT count(*) FROM producto WHERE precio < 0 OR stock < 0;' -BaseDatos $BaseDestino
    if ($null -eq $productosInvalidos) {
        $fallo = $true
    }
}
if (-not $fallo) {
    $detallesInvalidos = Consultar-Psql -Etiqueta 'detalles_invalidos' -Consulta 'SELECT count(*) FROM detalle_pedido WHERE cantidad <= 0 OR precio_unitario < 0;' -BaseDatos $BaseDestino
    if ($null -eq $detallesInvalidos) {
        $fallo = $true
    }
}

# Detencion del cronometro: al terminar las validaciones
$cronometro.Stop()
$horaFinSimulacro = Get-Date
$rto = $cronometro.Elapsed
$rpo = $horaInicioSimulacro - $horaDump

if ($fallo) {
    Escribir-Log "ERROR - Fallaron las validaciones. No se pudieron confirmar los conteos."
    Write-Host "RESULTADO: ERROR - Fallaron las validaciones"
    exit 1
}

# Resumen de resultados
Escribir-Log "RESULTADO - Archivo usado: $archivoRestore"
Escribir-Log "RESULTADO - Hora de creacion del respaldo: $($horaDump.ToString('yyyy-MM-dd HH:mm:ss'))"
Escribir-Log "RESULTADO - Hora de inicio del simulacro: $($horaInicioSimulacro.ToString('yyyy-MM-dd HH:mm:ss'))"
Escribir-Log "RESULTADO - Hora de fin del simulacro: $($horaFinSimulacro.ToString('yyyy-MM-dd HH:mm:ss'))"
Escribir-Log "RESULTADO - RTO observado: $($rto.TotalSeconds.ToString('F2')) segundos ($rto)"
Escribir-Log "RESULTADO - RPO observado: $($rpo.TotalHours.ToString('F2')) horas ($rpo)"
foreach ($clave in $conteos.Keys) {
    Escribir-Log "RESULTADO - Conteo ${clave}: $($conteos[$clave])"
}
Escribir-Log "RESULTADO - productos_invalidos: $productosInvalidos"
Escribir-Log "RESULTADO - detalles_invalidos: $detallesInvalidos"

Write-Host "Archivo usado: $archivoRestore"
Write-Host "RTO observado: $($rto.TotalSeconds.ToString('F2')) segundos"
Write-Host "RPO observado: $($rpo.TotalHours.ToString('F2')) horas"
foreach ($clave in $conteos.Keys) {
    Write-Host "Conteo ${clave}: $($conteos[$clave])"
}
Write-Host "productos_invalidos: $productosInvalidos"
Write-Host "detalles_invalidos: $detallesInvalidos"

# Los controles de invalidos deben dar cero
if (($productosInvalidos -ne "0") -or ($detallesInvalidos -ne "0")) {
    Escribir-Log "ERROR - Los controles de invalidos no dieron cero (productos_invalidos=$productosInvalidos, detalles_invalidos=$detallesInvalidos)."
    Write-Host "RESULTADO: ERROR - Controles de invalidos distintos de cero"
    exit 1
}

Escribir-Log "OK - Restauracion de prueba completada satisfactoriamente. RTO: $($rto.TotalSeconds.ToString('F2')) s | RPO: $($rpo.TotalHours.ToString('F2')) h"
Write-Host "RESULTADO: OK - Restauracion en $BaseDestino"
exit 0
