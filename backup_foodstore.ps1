<#
.SYNOPSIS
    Script de respaldo automatizado para la base de datos foodstore.
.DESCRIPTION
    Realiza un respaldo en formato custom (pg_dump -Fc) utilizando pgpass.conf para autenticacion,
    verifica el respaldo con pg_restore --list, calcula su hash SHA-256 y registra la ejecucion en un log ASCII.
#>

param (
    [string]$PgDump = "C:\Program Files\PostgreSQL\17\bin\pg_dump.exe",
    [string]$PgRestore = "C:\Program Files\PostgreSQL\17\bin\pg_restore.exe",
    [string]$Servidor = "localhost",
    [int]$Puerto = 5432,
    [string]$Usuario = "postgres",
    [string]$Base = "foodstore",
    [string]$DirBackups = "$PSScriptRoot\backups",
    [string]$DirLogs = "$PSScriptRoot\logs"
)

# Asegurar que las carpetas de backups y logs existan
if (-not (Test-Path -LiteralPath $DirBackups)) {
    New-Item -ItemType Directory -Path $DirBackups -Force | Out-Null
}
if (-not (Test-Path -LiteralPath $DirLogs)) {
    New-Item -ItemType Directory -Path $DirLogs -Force | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$nombreBase = "foodstore_$timestamp"
$rutaParcial = Join-Path $DirBackups "$nombreBase.dump.parcial"
$rutaDump = Join-Path $DirBackups "$nombreBase.dump"
$rutaSha256 = Join-Path $DirBackups "$nombreBase.dump.sha256"
$rutaLog = Join-Path $DirLogs "backup_$timestamp.log"

# Funcion auxiliar para escribir en el log con codificacion ASCII
function Escribir-Log {
    param ([string]$Mensaje)
    $fechaHora = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $linea = "$fechaHora - $Mensaje"
    Add-Content -Path $rutaLog -Value $linea -Encoding ASCII
}

Escribir-Log "INICIO - Iniciando proceso de respaldo para la base '$Base' en servidor '${Servidor}:${Puerto}'."

# Validar que los ejecutables existan
if (-not (Test-Path -LiteralPath $PgDump)) {
    Escribir-Log "ERROR - No se encontro el ejecutable pg_dump en la ruta: $PgDump"
    Write-Host "RESULTADO: ERROR - No se encontro el ejecutable pg_dump"
    exit 1
}
if (-not (Test-Path -LiteralPath $PgRestore)) {
    Escribir-Log "ERROR - No se encontro el ejecutable pg_restore en la ruta: $PgRestore"
    Write-Host "RESULTADO: ERROR - No se encontro el ejecutable pg_restore"
    exit 1
}

# Ejecucion de pg_dump escribiendo a archivo parcial
Escribir-Log "INFO - Ejecutando pg_dump hacia archivo parcial: $rutaParcial"

$oldPreference = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
try {
    $salidaPgDump = & $PgDump -h $Servidor -p $Puerto -U $Usuario -d $Base -Fc -w -v -f $rutaParcial 2>&1
    $exitCodePgDump = $LASTEXITCODE
    foreach ($lin in $salidaPgDump) {
        Escribir-Log "PG_DUMP: $lin"
    }
}
catch {
    $exitCodePgDump = 1
    Escribir-Log "ERROR - Excepcion durante la ejecucion de pg_dump: $_"
}
finally {
    $ErrorActionPreference = $oldPreference
}

# Verificar si pg_dump fallo
if ($exitCodePgDump -ne 0) {
    Escribir-Log "ERROR - pg_dump fallo con codigo de salida $exitCodePgDump."
    if (Test-Path -LiteralPath $rutaParcial) {
        Remove-Item -LiteralPath $rutaParcial -Force
        Escribir-Log "INFO - Archivo parcial eliminado."
    }
    Write-Host "RESULTADO: ERROR - pg_dump fallo con codigo $exitCodePgDump"
    exit 1
}

Escribir-Log "OK - pg_dump finalizo correctamente. Verificando archivo parcial con pg_restore --list."

# Verificacion del archivo parcial con pg_restore --list
$oldPreference = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
try {
    $salidaPgRestore = & $PgRestore --list $rutaParcial 2>&1
    $exitCodePgRestore = $LASTEXITCODE
    $numLineas = @($salidaPgRestore).Count
    Escribir-Log "INFO - pg_restore --list genero $numLineas lineas de salida."
    if ($exitCodePgRestore -ne 0) {
        foreach ($lin in $salidaPgRestore) {
            Escribir-Log "PG_RESTORE: $lin"
        }
    }
}
catch {
    $exitCodePgRestore = 1
    Escribir-Log "ERROR - Excepcion durante la verificacion con pg_restore: $_"
}
finally {
    $ErrorActionPreference = $oldPreference
}

# Verificar si la validacion con pg_restore fallo
if ($exitCodePgRestore -ne 0) {
    Escribir-Log "ERROR - pg_restore --list fallo en el archivo parcial con codigo $exitCodePgRestore."
    if (Test-Path -LiteralPath $rutaParcial) {
        Remove-Item -LiteralPath $rutaParcial -Force
        Escribir-Log "INFO - Archivo parcial eliminado tras fallo de verificacion."
    }
    Write-Host "RESULTADO: ERROR - pg_restore --list fallo con codigo $exitCodePgRestore"
    exit 1
}

Escribir-Log "OK - Verificacion del respaldo exitosa. Renombrando archivo parcial a definitivo."

# Renombrar .parcial a .dump
try {
    Move-Item -LiteralPath $rutaParcial -Destination $rutaDump -Force
}
catch {
    Escribir-Log "ERROR - No se pudo renombrar el archivo parcial a definitivo: $_"
    Write-Host "RESULTADO: ERROR - No se pudo renombrar el archivo parcial"
    exit 1
}

# Obtener tamano en bytes y verificar si es 0 o menor
$tamanoBytes = (Get-Item -LiteralPath $rutaDump).Length
if ($tamanoBytes -le 0) {
    Escribir-Log "ERROR - El archivo de respaldo resultante tiene un tamano de $tamanoBytes bytes."
    Write-Host "RESULTADO: ERROR - Tamano de respaldo invalido ($tamanoBytes bytes)"
    exit 1
}

# Calcular hash SHA-256
try {
    $hashObj = Get-FileHash -LiteralPath $rutaDump -Algorithm SHA256
    $hashSha256 = $hashObj.Hash
    $nombreArchivoDump = Split-Path -Leaf $rutaDump
    $contenidoSha256 = "$hashSha256  $nombreArchivoDump"
    Set-Content -Path $rutaSha256 -Value $contenidoSha256 -Encoding ASCII
    Escribir-Log "INFO - Hash SHA-256 generado y guardado en $rutaSha256."
}
catch {
    Escribir-Log "ERROR - No se pudo calcular o guardar el hash SHA-256: $_"
    Write-Host "RESULTADO: ERROR - Fallo al calcular o guardar hash SHA-256"
    exit 1
}

Escribir-Log "OK - Respaldo completado satisfactoriamente. Ruta: $rutaDump | Tamano: $tamanoBytes bytes | SHA256: $hashSha256"
Write-Host "RESULTADO: OK - $rutaDump"
exit 0
