# ChromePanelFix 9.0 — GUI OPERATIVO

[Español](README.md) · [English](README.en.md)

**Clear Google Update stopped-service alerts in Windows Server Manager while preserving Chrome updates.**

ChromePanelFix is a PowerShell graphical utility for Windows Server administrators. It automatically adjusts Google Update service exclusions in the **Local Server** and **All Servers** dashboards for the current administrator profile. The application interface is in Spanish.

## Why use it?

Google Update services may appear as automatic but stopped services, generating dashboard alerts. ChromePanelFix changes the dashboard filters so these services no longer count toward those alerts. It does not delete or disable Google services, scheduled tasks or files.

It does not repair Chrome update failures, delete event logs, or certify that Chrome updates work. A stopped service alone does not establish an updater failure.

## Download

[Download ChromePanelFix 9.0](https://github.com/SenecaDPJ/ChromePanelFix/raw/refs/heads/main/downloads/ChromePanelFix_9.0_GUI-OPERATIVO.zip) · [ZIP SHA-256](https://github.com/SenecaDPJ/ChromePanelFix/blob/main/downloads/ChromePanelFix_9.0_GUI-OPERATIVO.zip.sha256) · [Releases](https://github.com/SenecaDPJ/ChromePanelFix/releases)

![ChromePanelFix graphical interface](Vista-previa.png)

## Quick start

1. Extract **all** ZIP files into a local folder.
2. Double-click **Abrir-ChromePanelFix.cmd**, or choose **Run with PowerShell** on **ChromePanelFix_9.0_GUI-OPERATIVO.ps1**.
3. Select **3** for the complete workflow. Options 1 and 2 are not prerequisites.
4. Check Local Server and All Servers in Server Manager. Check Chrome updates separately on its About page.

Keep the interface and core script together. Double-clicking a .ps1 file may open an editor; use the .cmd launcher instead.

## Requirements and compatibility

- **Windows PowerShell 5.1**, .NET Framework and Windows Forms; use Windows PowerShell, not PowerShell 7.
- Server Manager and Task Scheduler installed, with an interactive desktop.
- Run under the administrator account whose dashboard you want to adjust. Settings are per profile; elevation uses that same account.
- Configuration schema validated using Windows Server 2019 build 17763 diagnostic data.
- **Windows Server 2016 compatibility is not yet verified.** Unknown configuration schemas are rejected.
- Your organization's execution policy must permit these scripts. The tool does not change or bypass it.

## Menu

| Option | Action |
|---|---|
| 1 | Read-only service/filter diagnosis. A opens Server Manager. |
| 2 | Save references, install/update and verify the monitoring task, then open Task Scheduler Library. |
| 3 | Apply exclusions, save references, install/verify monitoring, then open Server Manager and Task Scheduler Library. |
| 4 | Undo exclusions added by the tool, remove its task and references, verify removal, then open Task Scheduler Library. |
| 5 | Exit. |

Server Manager may be closed gracefully before changing its configuration to prevent it from overwriting the changes. Conflicting instances are reported.

## Scheduled monitoring

The task `GoogleUpdateAlertMonitor-<SID>` runs daily at **09:00** and at logon. It uses the installing account with elevated privileges and requires that account to be logged on; a locked session is supported. The background action checks and reapplies exclusions, including service names changed by Google updates, without opening management windows.

**Automatic execution effectiveness is still awaiting validation.** Installation/configuration checks do not prove a successful scheduled run.

## Data and undo

Local files are stored in `%LOCALAPPDATA%\GoogleUpdateAlertMonitor`:

- `baseline.json`: reference inventory.
- `direct-state.json`: tool-owned additions for selective undo.
- `latest.json`: latest monitoring result.
- `user.config.recovery`: recovery copy.
- `Gestionar-AlertasGoogleUpdate.ps1`: installed core used by the task.
- `ui-*.jsonl`: interface logs.

Option 4 preserves unrelated settings and removes the four reference files and the tool's task. Interface logs and the installed core may remain. No telemetry or data transmission is included. Logs can contain computer/account names and paths; review them before sharing.

## Validation and known limitations

- The user confirmed the complete option 3 repair workflow and Task Scheduler Library opening from options 2, 3 and 4.
- Local checks covered syntax, mocked workflows, and repair/undo on a diagnostic copy.
- Automatic scheduled runs and Windows Server 2016 remain unverified.
- **When closing Task Scheduler, MMC may ask to save taskschd.msc. Choose No.** This concerns the console view, not the completed repair.
- `Probar-Biblioteca.ps1` tests Library opening only, without changing filters or tasks.

## Documentation and integrity

[Release notes](RELEASE_NOTES.md) · [Changelog](CHANGELOG.md) · [Validation](VALIDACION.md) · [Contributing](CONTRIBUTING.md) · [Security](SECURITY.md). Supporting documents are in Spanish.

Version 9.0 is a functional clone of the user-validated, locally frozen 8.0. The published ZIP remains unchanged. `SHA256SUMS.txt` describes files inside that original package; verify it after extracting the ZIP. Main-branch documentation may evolve independently.

## License

Maintained by **SenecaDPJ**. [MIT License](LICENSE), copyright 2026 SenecaDPJ.

Independent project, not affiliated with Google or Microsoft. Product names and trademarks belong to their respective owners.
