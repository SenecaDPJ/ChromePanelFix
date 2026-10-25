@echo off
setlocal
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -NoExit -File "%~dp0Detener-Procesos-ChromePanelFix.ps1"
exit /b
