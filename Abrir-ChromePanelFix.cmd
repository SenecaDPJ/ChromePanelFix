@echo off
setlocal
set "APP=%~dp0ChromePanelFix_9.3_GUI-OPERATIVO.ps1"
set "APPDIR=%~dp0"
set "CHROMEPANELFIX_SCRIPT=%APP%"
set "CHROMEPANELFIX_DIR=%APPDIR%"
set "PS51=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"

if not exist "%APP%" (
  echo ERROR: No se encuentra ChromePanelFix_9.3_GUI-OPERATIVO.ps1.
  echo Extraiga todos los archivos del ZIP en una misma carpeta.
  pause
  exit /b 2
)

"%PS51%" -NoProfile -NonInteractive -Command "$scripts=@(Get-ChildItem -LiteralPath $env:CHROMEPANELFIX_DIR -Filter '*.ps1' -File); $blocked=@($scripts | Where-Object { Get-Item -LiteralPath $_.FullName -Stream Zone.Identifier -ErrorAction SilentlyContinue }); if($blocked.Count -gt 0){ exit 10 }"
set "PREFLIGHT=%ERRORLEVEL%"

if "%PREFLIGHT%"=="10" (
  echo.
  echo Windows ha marcado como descargados los scripts de esta carpeta.
  echo Si confirma que confia en el ZIP, el lanzador quitara la marca
  echo Zone.Identifier de los archivos .ps1 de ChromePanelFix y continuara.
  echo Solo se actuara sobre los scripts de esta carpeta.
  echo La politica de ejecucion de PowerShell no se modificara.
  echo.
  choice /C SN /N /M "Confia en estos archivos y desea continuar? [S/N] "
  if errorlevel 2 (
    echo No se ha cambiado ningun archivo. ChromePanelFix no se ha iniciado.
    pause
    exit /b 3
  )
  "%PS51%" -NoProfile -NonInteractive -Command "$ErrorActionPreference='Stop'; $scripts=@(Get-ChildItem -LiteralPath $env:CHROMEPANELFIX_DIR -Filter '*.ps1' -File); $blocked=@($scripts | Where-Object { Get-Item -LiteralPath $_.FullName -Stream Zone.Identifier -ErrorAction SilentlyContinue }); foreach($script in $blocked){ Unblock-File -LiteralPath $script.FullName -ErrorAction Stop }; $remaining=@($scripts | Where-Object { Get-Item -LiteralPath $_.FullName -Stream Zone.Identifier -ErrorAction SilentlyContinue }); if($remaining.Count -gt 0){ exit 11 }"
  if errorlevel 1 (
    echo.
    echo ERROR: Windows no pudo quitar la marca de uno o mas archivos.
    echo No se ha iniciado ChromePanelFix. Consulte al administrador.
    pause
    exit /b 4
  )
  echo Marcas retiradas de los scripts .ps1 de esta carpeta.
  echo Continuando con ChromePanelFix...
)

if not "%PREFLIGHT%"=="0" if not "%PREFLIGHT%"=="10" (
  echo.
  echo ERROR: No se pudo comprobar el estado de los scripts.
  echo No se ha iniciado ChromePanelFix. Consulte al administrador.
  pause
  exit /b 5
)

start "" "%PS51%" -NoProfile -STA -WindowStyle Hidden -Command "try { & $env:CHROMEPANELFIX_SCRIPT } catch { Add-Type -AssemblyName System.Windows.Forms; [void][System.Windows.Forms.MessageBox]::Show(('No se pudo iniciar ChromePanelFix 9.3.' + [Environment]::NewLine + [Environment]::NewLine + [string]$_.Exception.Message + [Environment]::NewLine + [Environment]::NewLine + 'Respete la politica de ejecucion de su organizacion. Si requiere scripts firmados, consulte al administrador.'), 'ChromePanelFix 9.3', [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error); exit 1 } # ChromePanelFix-9.3-GUI-OPERATIVO"
exit /b