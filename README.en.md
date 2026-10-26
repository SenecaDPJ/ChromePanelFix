# ChromePanelFix 9.4 — GUI OPERATIVO

[Español](README.md) · [English](README.en.md)

**Clear Google Update stopped-service alerts from Windows Server Manager while preserving Chrome update components.**

A PowerShell graphical utility for Windows Server administrators. It adjusts service filters in the Local Server and All Servers dashboards for the current administrator profile.

Version 9.4 adds the ChromePanelFix icon to the application window and keeps the verified 9.3 workflow.

## Download

[Download ChromePanelFix 9.4](https://github.com/SenecaDPJ/ChromePanelFix/releases/tag/v9.4) · [Repository](https://github.com/SenecaDPJ/ChromePanelFix)

![ChromePanelFix 9.3 menu preview; its workflow is preserved in 9.4](Vista-previa.png)

![ChromePanelFix icon](assets/ChromePanelFix-256.png)

## Quick start

1. Download the 9.4 release ZIP and extract all files together, keeping the assets folder.
2. Open Abrir-ChromePanelFix.cmd.
3. If Windows marks scripts as downloaded from the Internet, the launcher asks whether you trust them. Press S to remove Zone.Identifier only from marked .ps1 files in this folder and continue, or N to exit without changing them.
4. Choose 3 for the complete workflow; options 1 and 2 are not prerequisites.

The confirmation appears when opening the launcher because standard Windows extraction does not allow this project to add a custom prompt. The operation does not change or bypass PowerShell's execution policy. If your organization's policy requires signed scripts, contact your administrator.

## Options

| Option | Action |
|---|---|
| 1 | Read-only service and filter diagnosis; can open Server Manager. |
| 2 | Save references, create and verify the tool's task; open Task Scheduler Library. |
| 3 | Apply exclusions, save references, install and verify monitoring; open Server Manager and Task Scheduler Library. |
| 4 | Undo tool-owned exclusions, remove its task and references; verify and open Task Scheduler Library. |
| 5 | Exit. |

The tool adjusts dashboard filters. It does not delete or disable Google services, tasks or files; it does not delete events or certify Chrome updates. Actual update failures must be diagnosed separately.

## Requirements and limits

- Windows PowerShell 5.1, .NET Framework, Windows Forms, Server Manager and Task Scheduler.
- Run under the administrator account whose dashboard preferences you want to adjust. Settings are per profile; required operations request elevation.
- Scheduled-task effectiveness and Windows Server 2016 compatibility remain unverified.

## Process recovery

If a run remains open and prevents closing the folder, use Detener-Procesos-ChromePanelFix.cmd. It lists processes identified as ChromePanelFix and asks for exact PIDs before stopping them. It does not stop Server Manager, MMC or unrelated PowerShell processes.

## License

Copyright © 2026 David De Prado (Seneca DPJ). MIT License. Independent project, not affiliated with Google or Microsoft.