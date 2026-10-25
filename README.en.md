# ChromePanelFix 9.1 — GUI OPERATIVO

[Español](README.md) · [English](README.en.md)

**Clear Google Update stopped-service alerts from Windows Server Manager while preserving Chrome update components.**

A PowerShell graphical utility for Windows Server administrators. It adjusts service filters in the Local Server and All Servers dashboards for the current administrator profile.

## 9.1 fix

Version 9.0 shipped a .cmd launcher encoded with a UTF-8 BOM, which prevented cmd.exe from parsing its first line correctly. It also hid PowerShell startup errors. This version fixes the launcher and displays a readable error if Windows blocks the script.

## Download

[Download ChromePanelFix 9.1](https://github.com/SenecaDPJ/ChromePanelFix/releases/tag/v9.1) · [Repository](https://github.com/SenecaDPJ/ChromePanelFix)

![ChromePanelFix interface](Vista-previa.png)

## Quick start

1. Download the 9.1 release ZIP and extract all files together.
2. If Windows offers an **Unblock** option, before extracting right-click the ZIP, choose **Properties**, check **Unblock**, then click **Apply**. Only do this when you trust that the archive came from the official release linked above.
3. Double-click **Abrir-ChromePanelFix.cmd**.
4. Choose **3** for the complete workflow. Options 1 and 2 are not prerequisites.

Your organization's PowerShell execution policy still applies. The launcher does not bypass it. If the policy blocks the script, the launcher will show the error; contact your administrator.

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
- Run under the administrator account whose dashboard you want to adjust. Settings are per profile; required operations request elevation.
- Configuration was checked against Windows Server 2019 diagnostic data (build 17763). Windows Server 2016 compatibility is still unverified.
- The task is scheduled daily at 09:00 and at logon. The effectiveness of automatic runs is still awaiting validation.
- When closing Task Scheduler, MMC may ask to save taskschd.msc; choose **No**.

## License and versions

Maintained by **SenecaDPJ** under the **MIT License**. Independent project, not affiliated with Google or Microsoft.

Release 9.1 fixes the launcher and startup diagnostics. It does not change the repair engine. Version 9.0 remains available in the Releases history.