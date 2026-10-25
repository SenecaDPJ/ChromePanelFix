@echo off
setlocal
set "APP=%~dp0ChromePanelFix_9.1_GUI-OPERATIVO.ps1"
if not exist "%APP%" (
  echo ERROR: No se encuentra ChromePanelFix_9.1_GUI-OPERATIVO.ps1.
  echo Extraiga todos los archivos del ZIP en una misma carpeta.
  pause
  exit /b 2
)
set "CHROMEPANELFIX_SCRIPT=%APP%"
start "" "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -STA -WindowStyle Hidden -Command "try { & $env:CHROMEPANELFIX_SCRIPT } catch { Add-Type -AssemblyName System.Windows.Forms; [void][System.Windows.Forms.MessageBox]::Show(('No se pudo iniciar ChromePanelFix 9.1.' + [Environment]::NewLine + [Environment]::NewLine + [string]$_.Exception.Message + [Environment]::NewLine + [Environment]::NewLine + 'Si los archivos proceden de una descarga, desbloquee el ZIP en Propiedades antes de extraerlo. Respete la politica de ejecucion de su organizacion.'), 'ChromePanelFix 9.1', [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error); exit 1 }"
exit /b