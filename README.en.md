# ChromePanelFix 9.5 — GUI OPERATIVO

[Español](README.md) · [English](README.en.md)

**Clear Google Update stopped-service alerts from Windows Server Manager while preserving Chrome update components.**

A PowerShell graphical utility for Windows Server administrators. It adjusts service filters in the Local Server and All Servers dashboards for the current administrator profile.

Version 9.5 adds a manual solution path that does not create a scheduled task. Its submenu lets you open Server Manager when the operation finishes or leave it closed. Option 4 keeps the complete workflow with scheduled monitoring.

## Download

[Download ChromePanelFix 9.5](https://github.com/SenecaDPJ/ChromePanelFix/releases/tag/v9.5) · [Repository](https://github.com/SenecaDPJ/ChromePanelFix)

![ChromePanelFix 9.5 menu preview](Vista-previa.png)

![Manual solution submenu](Vista-previa-submenu.png)

![ChromePanelFix icon](assets/ChromePanelFix-256.png)

## Quick start

1. Download the 9.5 release ZIP and extract all files together, keeping the assets folder.
2. Open Abrir-ChromePanelFix.cmd.
3. If Windows marks scripts as downloaded from the Internet, the launcher asks whether you trust them. Press S to remove Zone.Identifier only from marked .ps1 files in this folder and continue, or N to exit without changing them.
4. Choose 2 to apply the solution manually, or 4 for the complete workflow with monitoring.

The confirmation appears when opening the launcher because standard Windows extraction does not allow this project to add a custom prompt. The operation does not change or bypass PowerShell's execution policy. If your organization's policy requires signed scripts, contact your administrator.

## Options

| Option | Action |
|---|---|
| 1 | Read-only service and filter diagnosis; can open Server Manager. |
| 2 | Apply the solution manually and save the data needed for UNDO. Does not create or update a task. The submenu lets you open Server Manager on completion or leave it closed. |
| 3 | Save references, create and verify the tool's task; open Task Scheduler Library. |
| 4 | Apply exclusions, save references, install and verify monitoring; open Server Manager and Task Scheduler Library. |
| 5 | Undo tool-owned exclusions, remove its task if present, and remove references; verify and open Task Scheduler Library. |
| 6 | Exit. |

Option 2 preserves any existing monitoring task and warns before continuing. It does not run while the tool's task is active. UNDO still removes the tool's own exclusions and its task if present.

The tool adjusts dashboard filters. It does not delete or disable Google services, tasks or files; it does not delete events or certify Chrome updates. Actual update failures must be diagnosed separately.

## Requirements and limits

- Windows PowerShell 5.1, .NET Framework, Windows Forms, Server Manager and Task Scheduler.
- Run under the administrator account whose dashboard preferences you want to adjust. Settings are per profile; required operations request elevation.
- Scheduled-task effectiveness and Windows Server 2016 compatibility remain unverified.

## Process recovery

If a run remains open and prevents closing the folder, use Detener-Procesos-ChromePanelFix.cmd. It lists processes identified as ChromePanelFix and asks for exact PIDs before stopping them. It does not stop Server Manager, MMC or unrelated PowerShell processes.

## License

Copyright © 2026 David De Prado (Seneca DPJ). MIT License. Independent project, not affiliated with Google or Microsoft.
