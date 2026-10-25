@echo off
start "" "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -STA -WindowStyle Hidden -File "%~dp0ChromePanelFix_9.0_GUI-OPERATIVO.ps1"
exit /b
