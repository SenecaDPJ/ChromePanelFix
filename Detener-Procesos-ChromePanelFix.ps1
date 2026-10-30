#requires -Version 5.1
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param()

$ErrorActionPreference = 'Stop'
$processes = @(Get-CimInstance -ClassName Win32_Process -Filter "Name = 'powershell.exe'")
$windows = @{}
foreach ($item in @(Get-Process -Name powershell -ErrorAction SilentlyContinue)) {
    if ($item.MainWindowTitle -match '(?i)ChromePanelFix') {
        $windows[[int]$item.Id] = [string]$item.MainWindowTitle
    }
}

$candidateById = @{}
foreach ($item in $processes) {
    $commandLine = [string]$item.CommandLine
    $role = $null
    $action = ''
    if ($commandLine -match '(?i)ChromePanelFix-9\.[0-9]+-GUI-OPERATIVO') {
        $role = 'Interfaz ChromePanelFix'
    } elseif ($commandLine -match '(?i)ChromePanelFix\.Core\.ps1') {
        $role = 'Proceso de accion ChromePanelFix'
    } elseif ($commandLine -match '(?i)GoogleUpdateAlertMonitor.*Gestionar-AlertasGoogleUpdate\.ps1.*-Action\s+(Prepare|Apply|Watch|Undo)') {
        $role = 'Tarea de vigilancia'
    } elseif ($windows.ContainsKey([int]$item.ProcessId)) {
        $role = 'Interfaz ChromePanelFix'
    }
    if ($commandLine -match '(?i)-Action\s+(Diagnose|Prepare|ApplyManual|Apply|Watch|Undo)') {
        $action = $Matches[1]
        if ($action -eq 'Watch') { $role = 'Tarea de vigilancia' }
    }
    if ($role) {
        $title = ''
        if ($windows.ContainsKey([int]$item.ProcessId)) { $title = $windows[[int]$item.ProcessId] }
        $candidateById[[int]$item.ProcessId] = [pscustomobject]@{
            ProcessId = [int]$item.ProcessId
            ParentProcessId = [int]$item.ParentProcessId
            Tipo = $role
            Accion = $action
            Ventana = $title
        }
    }
}
foreach ($processId in $windows.Keys) {
    if (-not $candidateById.ContainsKey([int]$processId)) {
        $candidateById[[int]$processId] = [pscustomobject]@{
            ProcessId = [int]$processId
            ParentProcessId = $null
            Tipo = 'Interfaz ChromePanelFix'
            Accion = ''
            Ventana = $windows[[int]$processId]
        }
    }
}
$candidates = @($candidateById.Values | Sort-Object @{Expression={if ($_.Tipo -eq 'Proceso de accion ChromePanelFix') {0} elseif ($_.Tipo -eq 'Tarea de vigilancia') {1} else {2}}}, ProcessId)

Write-Host ''
Write-Host 'CIERRE CONTROLADO DE PROCESOS CHROMEPANELFIX' -ForegroundColor Cyan
Write-Host 'No se cerraran Server Manager, MMC ni otros procesos PowerShell.'
if ($candidates.Count -eq 0) {
    Write-Host 'No se detectaron procesos ChromePanelFix en ejecucion.'
    Write-Host 'Si la carpeta sigue en uso, compruebe si hay otra ventana de PowerShell/ISE o el Explorador abierto en ella.'
    return
}
Write-Host ''
$candidates | Format-Table ProcessId, ParentProcessId, Tipo, Accion, Ventana -AutoSize -Wrap | Out-Host
Write-Host 'Al cerrar un proceso que sigue aplicando cambios, la operacion puede quedar incompleta.' -ForegroundColor Yellow
$answer = Read-Host 'Escriba el PID exacto, varios PID separados por coma, o TODOS; Entrar cancela'
if ([string]::IsNullOrWhiteSpace($answer)) {
    Write-Host 'Cancelado. No se cerro ningun proceso.'
    return
}
if ($answer.Trim().ToUpperInvariant() -eq 'TODOS') {
    $selected = $candidates
} else {
    $requestedIds = @()
    foreach ($part in ($answer -split ',')) {
        $number = 0
        if (-not [int]::TryParse($part.Trim(), [ref]$number)) {
            throw ('PID no valido: ' + $part)
        }
        $requestedIds += $number
    }
    $selected = @()
    foreach ($number in ($requestedIds | Select-Object -Unique)) {
        $item = $candidateById[[int]$number]
        if ($null -eq $item) { throw ('El PID ' + $number + ' no esta en la lista detectada; no se ha detenido ningun proceso.') }
        $selected += $item
    }
    $selected = @($selected | Sort-Object @{Expression={if ($_.Tipo -eq 'Proceso de accion ChromePanelFix') {0} elseif ($_.Tipo -eq 'Tarea de vigilancia') {1} else {2}}}, ProcessId)
}
foreach ($item in $selected) {
    $target = 'PID ' + $item.ProcessId + ' (' + $item.Tipo + $(if ($item.Accion) { ', accion ' + $item.Accion } else { '' }) + ')'
    if ($PSCmdlet.ShouldProcess($target, 'Forzar cierre del proceso identificado de ChromePanelFix')) {
        try {
            Stop-Process -Id $item.ProcessId -Force -ErrorAction Stop
            Write-Host ('Cerrado: ' + $target) -ForegroundColor Green
        } catch {
            Write-Warning ('No se pudo cerrar ' + $target + '. Pruebe desde PowerShell como administrador. ' + $_.Exception.Message)
        }
    }
}
