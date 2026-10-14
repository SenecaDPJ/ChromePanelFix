# Cambio masivo de UPN manteniendo SMTP principal anterior

## Descargar Eliminar-GoogleUpdate

El archivo independiente [`Eliminar-GoogleUpdate.ps1`](./Eliminar-GoogleUpdate.ps1)
elimina los servicios, las tareas programadas y las carpetas de Google Update
sin desinstalar Google Chrome ni borrar sus perfiles. Antes de aplicarlo puede
revisar las acciones mediante:

```powershell
.\Eliminar-GoogleUpdate.ps1 -WhatIf
```

Después, abra PowerShell como administrador y ejecute:

```powershell
.\Eliminar-GoogleUpdate.ps1
```

> **Advertencia:** al eliminar Google Update se desactivan las actualizaciones
> automáticas y las correcciones de seguridad de las aplicaciones de Google.
> Hágalo únicamente si el dispositivo se actualiza mediante otro mecanismo.

Este repositorio incluye un script de PowerShell para escenarios cloud-only (Entra ID + Intune + Exchange Online) donde:

1. Cambias el **UPN** del usuario (por ejemplo, de `@principal.com` a `@secundario.com`).
2. Exchange Online cambia automáticamente el **SMTP principal** al nuevo UPN.
3. El script revierte el **SMTP principal** al valor anterior deseado.

## Script

- `bulk-upn-primary-smtp-swap.ps1`

## Requisitos

- Módulo `Microsoft.Graph.Users`
- Módulo `ExchangeOnlineManagement`
- Permisos adecuados:
  - Graph: `User.ReadWrite.All`
  - Exchange Online: permisos para `Get-Mailbox` y `Set-Mailbox`

## Formato CSV

Archivo CSV con estas columnas obligatorias:

- `CurrentUPN`: UPN actual del usuario.
- `TargetUPN`: nuevo UPN a aplicar.
- `PrimarySmtpToKeep`: SMTP principal que debe quedar al final.

Ejemplo:

```csv
CurrentUPN,TargetUPN,PrimarySmtpToKeep
user@principal.com,user@secundario.com,user@principal.com
```

## Ejecución

```powershell
./bulk-upn-primary-smtp-swap.ps1 -CsvPath ./usuarios.csv
```

Prueba sin aplicar cambios:

```powershell
./bulk-upn-primary-smtp-swap.ps1 -CsvPath ./usuarios.csv -WhatIf
```

## Flujo aplicado por cada usuario

1. Busca el usuario por `CurrentUPN` en Entra ID.
2. Cambia `UserPrincipalName` a `TargetUPN`.
3. Recupera el buzón en Exchange Online por `TargetUPN`.
4. Fuerza que el SMTP principal final sea `PrimarySmtpToKeep`.
5. Mantiene `TargetUPN` como alias secundario (`smtp:`) cuando sea diferente.

## Nota

Si hay políticas, direcciones reservadas o sincronizaciones externas que bloqueen cambios de alias/SMTP, Exchange devolverá error y el script detendrá el proceso para ese lote.
