[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory = $true)]
    [string]$CsvPath,

    [Parameter(Mandatory = $false)]
    [switch]$SkipConnect
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-Module {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    if (-not (Get-Module -ListAvailable -Name $Name)) {
        throw "El módulo '$Name' no está instalado. Instálalo antes de continuar."
    }
}

function Connect-Services {
    Write-Host "Conectando con Microsoft Graph y Exchange Online..." -ForegroundColor Cyan
    Connect-MgGraph -Scopes "User.ReadWrite.All"
    Connect-ExchangeOnline -ShowBanner:$false
}

function Validate-CsvRow {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Row
    )

    $requiredFields = @(
        'CurrentUPN',
        'TargetUPN',
        'PrimarySmtpToKeep'
    )

    foreach ($field in $requiredFields) {
        if (-not $Row.PSObject.Properties.Name.Contains($field) -or [string]::IsNullOrWhiteSpace($Row.$field)) {
            throw "Fila inválida en CSV. Falta el campo obligatorio '$field'."
        }
    }

    if ($Row.CurrentUPN -eq $Row.TargetUPN) {
        throw "La fila con CurrentUPN '$($Row.CurrentUPN)' tiene el mismo TargetUPN."
    }
}

function Invoke-UpnAndSmtpChange {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Row
    )

    $currentUpn = $Row.CurrentUPN.Trim().ToLowerInvariant()
    $targetUpn = $Row.TargetUPN.Trim().ToLowerInvariant()
    $smtpToKeep = $Row.PrimarySmtpToKeep.Trim().ToLowerInvariant()

    Write-Host "\nProcesando usuario: $currentUpn" -ForegroundColor Yellow
    Write-Host " - Nuevo UPN: $targetUpn"
    Write-Host " - SMTP principal final deseado: $smtpToKeep"

    $user = Get-MgUser -Filter "userPrincipalName eq '$currentUpn'"
    if (-not $user) {
        throw "No se encontró usuario con UPN '$currentUpn'."
    }

    if ($PSCmdlet.ShouldProcess($currentUpn, "Actualizar UPN a '$targetUpn'")) {
        Update-MgUser -UserId $user.Id -UserPrincipalName $targetUpn
        Write-Host "   UPN actualizado en Entra ID." -ForegroundColor Green
    }

    Start-Sleep -Seconds 2

    $mailbox = Get-Mailbox -Identity $targetUpn -ErrorAction Stop

    $aliases = @()
    foreach ($address in $mailbox.EmailAddresses) {
        $aliases += $address.ToString()
    }

    $desiredPrimary = "SMTP:$smtpToKeep"
    $smtpProxy = "smtp:$targetUpn"

    $newAddresses = New-Object System.Collections.Generic.List[string]

    if (-not ($aliases -contains $smtpProxy) -and -not ($aliases -contains $desiredPrimary) -and -not ($aliases -contains "smtp:$smtpToKeep")) {
        $newAddresses.Add($smtpProxy)
    }

    foreach ($entry in $aliases) {
        $clean = $entry.Trim()
        $address = $clean.Substring(5).ToLowerInvariant()

        if ($address -eq $smtpToKeep) {
            continue
        }

        if ($clean.StartsWith('SMTP:')) {
            $newAddresses.Add("smtp:$address")
        }
        else {
            $newAddresses.Add($clean.ToLowerInvariant())
        }
    }

    if (-not ($newAddresses -contains $smtpProxy) -and $targetUpn -ne $smtpToKeep) {
        $newAddresses.Add($smtpProxy)
    }

    $newAddresses.Add($desiredPrimary)

    if ($PSCmdlet.ShouldProcess($targetUpn, "Definir SMTP principal en '$smtpToKeep'")) {
        Set-Mailbox -Identity $targetUpn -EmailAddresses $newAddresses
        Write-Host "   SMTP principal actualizado en Exchange Online." -ForegroundColor Green
    }
}

try {
    Assert-Module -Name Microsoft.Graph.Users
    Assert-Module -Name ExchangeOnlineManagement

    if (-not $SkipConnect) {
        Connect-Services
    }

    if (-not (Test-Path -Path $CsvPath -PathType Leaf)) {
        throw "No existe el archivo CSV: $CsvPath"
    }

    $rows = Import-Csv -Path $CsvPath
    if (-not $rows -or $rows.Count -eq 0) {
        throw 'El CSV está vacío.'
    }

    foreach ($row in $rows) {
        Validate-CsvRow -Row $row
        Invoke-UpnAndSmtpChange -Row $row
    }

    Write-Host "\nProceso finalizado correctamente." -ForegroundColor Cyan
}
catch {
    Write-Error "Error: $($_.Exception.Message)"
    throw
}
finally {
    if (-not $SkipConnect) {
        Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue
        Disconnect-MgGraph -ErrorAction SilentlyContinue
    }
}
