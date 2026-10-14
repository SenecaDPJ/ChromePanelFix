#requires -Version 5.1

<#
.SYNOPSIS
    Elimina los componentes de actualización automática de Google en Windows.

.DESCRIPTION
    Detiene y elimina los servicios y tareas programadas de Google Update y,
    opcionalmente, sus carpetas de instalación. No desinstala Google Chrome ni
    elimina perfiles o datos de usuario.

    Desactivar Google Update impide recibir correcciones automáticas de
    seguridad. Utilice este script únicamente si las actualizaciones se
    administran por otro mecanismo.

.PARAMETER KeepFiles
    Conserva las carpetas del actualizador después de eliminar servicios y
    tareas programadas.

.EXAMPLE
    .\Eliminar-GoogleUpdate.ps1 -WhatIf

    Muestra las acciones sin modificar el equipo.

.EXAMPLE
    .\Eliminar-GoogleUpdate.ps1

    Solicita confirmación y elimina los componentes de Google Update.

.EXAMPLE
    .\Eliminar-GoogleUpdate.ps1 -Confirm:$false

    Ejecuta todas las acciones sin solicitar confirmación individual.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [switch]$KeepFiles
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-GoogleUpdateServices {
    $servicePatterns = @(
        'gupdate',
        'gupdatem',
        'GoogleUpdaterInternalService*',
        'GoogleUpdaterService*'
    )

    return Get-Service -ErrorAction SilentlyContinue | Where-Object {
        $serviceName = $_.Name
        @($servicePatterns | Where-Object { $serviceName -like $_ }).Count -gt 0
    }
}

function Get-GoogleUpdateTasks {
    if (-not (Get-Command -Name Get-ScheduledTask -ErrorAction SilentlyContinue)) {
        return @()
    }

    $taskPatterns = @(
        'GoogleUpdateTaskMachine*',
        'GoogleUpdaterTask*'
    )

    return Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object {
        $taskName = $_.TaskName
        @($taskPatterns | Where-Object { $taskName -like $_ }).Count -gt 0
    }
}

if ($PSVersionTable.PSVersion.Major -ge 6 -and -not $IsWindows) {
    throw 'Este script solo se puede ejecutar en Windows.'
}

if (-not (Test-IsAdministrator) -and -not $WhatIfPreference) {
    throw 'Abra PowerShell como administrador y vuelva a ejecutar el script.'
}

Write-Host 'Buscando componentes de Google Update...' -ForegroundColor Cyan

$services = @(Get-GoogleUpdateServices)
foreach ($service in $services) {
    if ($PSCmdlet.ShouldProcess($service.Name, 'Detener y eliminar servicio')) {
        if ($service.Status -ne 'Stopped') {
            Stop-Service -Name $service.Name -Force -ErrorAction SilentlyContinue
        }

        $scOutput = & "$env:SystemRoot\System32\sc.exe" delete $service.Name 2>&1
        if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne 1060) {
            throw "No se pudo eliminar el servicio '$($service.Name)': $scOutput"
        }

        Write-Host "Servicio eliminado: $($service.Name)" -ForegroundColor Green
    }
}

$tasks = @(Get-GoogleUpdateTasks)
foreach ($task in $tasks) {
    $taskDisplayName = "$($task.TaskPath)$($task.TaskName)"
    if ($PSCmdlet.ShouldProcess($taskDisplayName, 'Eliminar tarea programada')) {
        Unregister-ScheduledTask `
            -TaskName $task.TaskName `
            -TaskPath $task.TaskPath `
            -Confirm:$false `
            -ErrorAction Stop
        Write-Host "Tarea eliminada: $taskDisplayName" -ForegroundColor Green
    }
}

if (-not $KeepFiles) {
    $candidatePaths = @(
        (Join-Path $env:ProgramFiles 'Google\GoogleUpdater'),
        (Join-Path $env:ProgramFiles 'Google\Update'),
        (Join-Path ${env:ProgramFiles(x86)} 'Google\GoogleUpdater'),
        (Join-Path ${env:ProgramFiles(x86)} 'Google\Update'),
        (Join-Path $env:ProgramData 'Google\GoogleUpdater'),
        (Join-Path $env:ProgramData 'Google\Update')
    ) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique

    foreach ($path in $candidatePaths) {
        if ((Test-Path -LiteralPath $path) -and
            $PSCmdlet.ShouldProcess($path, 'Eliminar carpeta de Google Update')) {
            Remove-Item -LiteralPath $path -Recurse -Force -ErrorAction Stop
            Write-Host "Carpeta eliminada: $path" -ForegroundColor Green
        }
    }
}

if ($services.Count -eq 0 -and $tasks.Count -eq 0) {
    Write-Host 'No se encontraron servicios ni tareas de Google Update.' -ForegroundColor Yellow
}
else {
    Write-Host 'Proceso finalizado. Reinicie Windows para completar la limpieza.' -ForegroundColor Cyan
}
