#requires -Version 5.1
<#
.SYNOPSIS
    Excluye Google Update del recuento de Servicios de Server Manager.
.DESCRIPTION
    Version 9.0 GUI OPERATIVO. Modifica directamente ServicesDashboardSettings del perfil.
    Esquema validado con diagnostico Windows Server 2019 10.0.17763.
    Server 2016 pendiente de validacion: rechaza esquemas no reconocidos.
    No cambia servicios ni componentes de Google. La consola se cierra
    ordenadamente si esta abierta para evitar escrituras sobre el filtro.
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
 [ValidateSet('Menu','Diagnose','Prepare','Apply','Watch','Undo')][string]$Action='Menu',
 [string]$ExpectedSid,
 [ValidatePattern('^[a-fA-F0-9]{32}$')][string]$UiSession
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$script:Sid=[Security.Principal.WindowsIdentity]::GetCurrent().User.Value
if($ExpectedSid -and $ExpectedSid -ne $script:Sid){throw 'La elevacion ha cambiado de cuenta. Use la cuenta propietaria del panel.'}
$script:Root=Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'GoogleUpdateAlertMonitor'
$script:State=Join-Path $script:Root 'direct-state.json'
$script:Reference=Join-Path $script:Root 'baseline.json'
$script:Report=Join-Path $script:Root 'latest.json'
$script:Installed=Join-Path $script:Root 'Gestionar-AlertasGoogleUpdate.ps1'
$script:Source=$PSCommandPath
$script:Task='GoogleUpdateAlertMonitor-'+$script:Sid
$script:Description='GoogleUpdateAlertMonitor: filtros directos v0.5'
$script:Session=(Get-Process -Id $PID).SessionId
function Write-VisualEvent {
 param([string]$Kind='Info',[string]$Text)
 if([string]::IsNullOrEmpty($UiSession)){return}
 $folder=Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'GoogleUpdateAlertMonitor'
 New-Item -ItemType Directory -Path $folder -Force | Out-Null
 $file=Join-Path $folder ('ui-'+$UiSession+'.jsonl')
 $entry=[ordered]@{Kind=$Kind;Text=$Text;At=(Get-Date).ToString('o')}
 $entry | ConvertTo-Json -Compress | Add-Content -LiteralPath $file -Encoding UTF8
}
function Write-Host {
 [CmdletBinding()]
 param([Parameter(Position=0,ValueFromRemainingArguments=$true)][object[]]$Object,
  [ConsoleColor]$ForegroundColor,[ConsoleColor]$BackgroundColor,[switch]$NoNewline,[object]$Separator=' ')
 $text=($Object | ForEach-Object {[string]$_}) -join [string]$Separator
 Write-VisualEvent -Kind Info -Text $text
 Microsoft.PowerShell.Utility\Write-Host @PSBoundParameters
}
function Test-Admin {
 $p=New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
 $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}
function Invoke-Elevated {
 param([string]$Requested)
 if($Action -eq 'Watch'){throw 'La tarea no puede solicitar UAC. Instalela con la opcion 2.'}
 $exe=Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
 $arguments='-NoProfile -File "'+$script:Source+'" -Action '+$Requested+' -ExpectedSid "'+$script:Sid+'"'
 if($script:locked){$script:mutex.ReleaseMutex();$script:locked=$false}
 try{
  $process=Start-Process -FilePath $exe -Verb RunAs -ArgumentList $arguments -Wait -PassThru
  if($process.ExitCode -ne 0){throw ('La operacion elevada no termino correctamente: '+$process.ExitCode)}
  Write-Host 'Operacion elevada completada.'
 }finally{
  try{$script:locked=$script:mutex.WaitOne(0)}catch [Threading.AbandonedMutexException]{$script:locked=$true}
  if(-not $script:locked){throw 'Otra ejecucion ha adquirido el control; cierre esta instancia.'}
 }
}
function Save-Json {
 param([string]$Path,[object]$Value)
 New-Item -ItemType Directory -Path $script:Root -Force | Out-Null
 $temp=$Path+'.tmp'
 $Value | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $temp -Encoding UTF8
 Move-Item -LiteralPath $temp -Destination $Path -Force
}
function Get-GoogleServices {
 @(Get-CimInstance Win32_Service | Where-Object {
  $_.Name -match '^(gupdate|gupdatem|GoogleUpdaterInternalService.*|GoogleUpdaterService.*)$'
 } | Sort-Object Name | Select-Object Name,DisplayName,State,StartMode,PathName)
}
function Read-XmlSafe {
 param([string]$Text)
 $settings=New-Object System.Xml.XmlReaderSettings
 $settings.DtdProcessing=[System.Xml.DtdProcessing]::Prohibit
 $settings.XmlResolver=$null
 $sr=New-Object IO.StringReader($Text)
 $reader=[Xml.XmlReader]::Create($sr,$settings)
 try{$xml=New-Object Xml.XmlDocument;$xml.XmlResolver=$null;$xml.Load($reader);return ,$xml}
 finally{$reader.Dispose();$sr.Dispose()}
}
function Get-ConfigPath {
 $root=Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'Microsoft_Corporation'
 $candidates=@()
 if(Test-Path -LiteralPath $root){
  foreach($dir in @(Get-ChildItem -LiteralPath $root -Directory -Filter 'ServerManager.exe_StrongName_*')){
   $path=Join-Path $dir.FullName '10.0.0.0\user.config'
   if(Test-Path -LiteralPath $path){$candidates+=$path}
  }
 }
 if($candidates.Count -ne 1){throw 'No se encuentra un user.config activo unico de Server Manager 10.0 en esta cuenta.'}
 $candidates[0]
}
function Read-Config {
 param([string]$Path)
 $bytes=[IO.File]::ReadAllBytes($Path)
 $bom=$bytes.Length -ge 3 -and $bytes[0] -eq 239 -and $bytes[1] -eq 187 -and $bytes[2] -eq 191
 $encoding=New-Object Text.UTF8Encoding($false,$true)
 $offset=0;if($bom){$offset=3}
 $text=$encoding.GetString($bytes,$offset,$bytes.Length-$offset)
 $xml=Read-XmlSafe $text
 $nodes=@($xml.SelectNodes('//setting[@name="ServicesDashboardSettings"]'))
 if($nodes.Count -ne 1 -or $nodes[0].GetAttribute('serializeAs') -ne 'Binary'){throw 'ServicesDashboardSettings no reconocido. No se modifica el perfil.'}
 $value=$nodes[0].SelectSingleNode('value')
 if($null -eq $value){throw 'Falta value en ServicesDashboardSettings.'}
 [pscustomobject]@{
  Path=$Path;Bytes=$bytes;Bom=$bom;Text=$text;Data=[Convert]::FromBase64String($value.InnerText)
 }
}
function Read-State {
 param([string]$ConfigPath)
 if(Test-Path -LiteralPath $script:State){
  $state=Get-Content -LiteralPath $script:State -Raw | ConvertFrom-Json
  if($state.Computer -ne $env:COMPUTERNAME -or $state.Sid -ne $script:Sid -or $state.ConfigPath -ne $ConfigPath){
   throw 'Referencias de otro perfil o equipo. No se modifican.'
  }
  return $state
 }
 [pscustomobject]@{Computer=$env:COMPUTERNAME;Sid=$script:Sid;ConfigPath=$ConfigPath;Added=@()}
}
function Get-OwnedManagerProcesses {
 $list=@(Get-CimInstance Win32_Process -Filter "Name='ServerManager.exe'")
 foreach($process in $list){
  $owner=Invoke-CimMethod -InputObject $process -MethodName GetOwnerSid
  if($owner.ReturnValue -ne 0){throw 'No se puede verificar el propietario de Server Manager.'}
  if($owner.Sid -eq $script:Sid){
   if($process.SessionId -ne $script:Session){throw 'Existe otra consola de esta cuenta en otra sesion. No se modifica un perfil con otra consola abierta.'}
   Get-Process -Id $process.ProcessId -ErrorAction Stop
  }
 }
}
function Close-Manager {
 $processes=@(Get-OwnedManagerProcesses)
 if($processes.Count -gt 0 -and -not (Test-Admin)){throw [UnauthorizedAccessException]::new('Se necesitan privilegios para cerrar la consola del mismo administrador.')}
 foreach($process in $processes){
  Write-Host 'Cerrando ordenadamente Administrador del Servidor para guardar y recargar sus filtros...'
  if(-not $process.CloseMainWindow()){throw 'La consola no admite cierre ordenado; cierre sus asistentes y reintente. No se fuerza el cierre.'}
  if(-not $process.WaitForExit(10000)){throw 'La consola no se ha cerrado. No se cambia el archivo ni se fuerza el cierre.'}
 }
}
function Write-ConfigData {
 param($Config,[byte[]]$NewData)
 $base64=[Convert]::ToBase64String($NewData)
 $pattern='(?s)(<setting\b(?=[^>]*\bname\s*=\s*"ServicesDashboardSettings")[^>]*>\s*<value(?:\s[^>]*)?>)(.*?)(</value>\s*</setting>)'
 $regex=New-Object Text.RegularExpressions.Regex($pattern)
 $matches=$regex.Matches($Config.Text)
 if($matches.Count -ne 1){throw 'No se identifica un unico bloque de escritura. No se modifica el XML.'}
 $match=$matches[0]
 $start=$match.Groups[2].Index
 $text=$Config.Text.Substring(0,$start)+$base64+$Config.Text.Substring($start+$match.Groups[2].Length)
 $xml=Read-XmlSafe $text
 if($xml.SelectSingleNode('//setting[@name="ServicesDashboardSettings"]/value').InnerText -ne $base64){throw 'Fallo al validar el XML generado.'}
 $encoding=New-Object Text.UTF8Encoding($Config.Bom,$true)
 $newBytes=@($encoding.GetPreamble())+@($encoding.GetBytes($text))
 # Rechazar una escritura concurrente; copia completa de recuperacion antes de escribir.
 $live=[IO.File]::ReadAllBytes($Config.Path)
 if([Convert]::ToBase64String($live) -ne [Convert]::ToBase64String($Config.Bytes)){throw 'Otro proceso ha cambiado la configuracion. Reintente.'}
 New-Item -ItemType Directory -Path $script:Root -Force | Out-Null
 [IO.File]::WriteAllBytes((Join-Path $script:Root 'user.config.recovery'),$Config.Bytes)
 $temp=$Config.Path+'.googlealert-'+[guid]::NewGuid().ToString('N')+'.tmp'
 try{
  [IO.File]::WriteAllBytes($temp,[byte[]]$newBytes)
  [IO.File]::Replace($temp,$Config.Path,[NullString]::Value)
 }finally{if(Test-Path -LiteralPath $temp){Remove-Item -LiteralPath $temp -Force}}
 $verify=Read-Config $Config.Path
 if([Convert]::ToBase64String($verify.Data) -ne $base64){throw 'No se confirma la escritura del filtro. Se conserva la copia de recuperacion.'}
}
function Invoke-DirectSolution {
 param([switch]$Undo,[switch]$Approved)
 $path=Get-ConfigPath
 $services=@(Get-GoogleServices)
 if($services.Count -eq 0 -and -not $Undo){throw 'No hay servicios Google Update detectados.'}
 $state=Read-State $path
 $config=Read-Config $path
 $document=[ChromeAlertData.Document]::new($config.Data)
 if($Undo){$changes=@($document.RemoveExceptions([string[]]@($state.Added)))}
 else{$changes=@($document.AddExceptions([string[]]@($services.DisplayName)))}
 if($changes.Count -eq 0){Write-Host $(if($Undo){'No hay adiciones propias pendientes de retirar.'}else{'Los servicios Google Update actuales ya constan en ambos filtros.'});return}
 if(-not $Approved -and -not $PSCmdlet.ShouldProcess($path,$(if($Undo){'Retirar solo las excepciones anadidas por esta herramienta'}else{'Actualizar directamente las excepciones de Google Update en ambos recuadros'}))){return}
 Close-Manager
 # La consola puede haber guardado cambios al cerrarse: releer y recalcular.
 $config=Read-Config $path
 $document=[ChromeAlertData.Document]::new($config.Data)
 if($Undo){$changes=@($document.RemoveExceptions([string[]]@($state.Added)))}
 else{$changes=@($document.AddExceptions([string[]]@($services.DisplayName)))}
 if($changes.Count -eq 0){return}
 if(-not $Undo){
  $state.Added=@(@($state.Added)+$changes | Select-Object -Unique)
  # Referencias persistidas antes de modificar para recuperar una aplicacion interrumpida.
  Save-Json $script:State $state
 }
 $output=$document.Bytes()
 $check=[ChromeAlertData.Document]::new($output)
 [void]$check.Filters()
 Write-ConfigData $config $output
 if($Undo){
  $state.Added=@($state.Added | Where-Object {$_ -notin $changes})
  Save-Json $script:State $state
 }
 Write-Host $(if($Undo){'Excepciones propias retiradas. Se conservan las demas selecciones.'}else{'Filtros de Google Update actualizados y releidos correctamente. No se ha modificado Chrome.'}) -ForegroundColor Green
}
function Get-OwnTask {
 @(Get-ScheduledTask | Where-Object {$_.TaskName -eq $script:Task -and $_.TaskPath -eq '\'})
}
function Assert-OwnTask {
 param($Task)
 $allowed=@($script:Description,
  'GoogleUpdateAlertMonitor: exclusion Google mediante UI Automation v0.4',
  'GoogleUpdateAlertMonitor: vigilancia de inventario; no corrige alertas.',
  'Vigila el inventario Google Update; no modifica exclusiones ni servicios.')
 $actions=@($Task.Actions)
 $user=[string]$Task.Principal.UserId
 if($user -ne $script:Sid){
  $user=(New-Object Security.Principal.NTAccount($user)).Translate([Security.Principal.SecurityIdentifier]).Value
 }
 if($Task.Description -notin $allowed -or $user -ne $script:Sid -or $actions.Count -ne 1 -or
  -not ([string]$actions[0].Arguments).Contains('"'+$script:Installed+'"')){
  throw 'La tarea existente no coincide con la propia. No se modifica.'
 }
}
function Prepare-Watch {
 $script:PrepareCompleted=$false
 if($WhatIfPreference){[void]$PSCmdlet.ShouldProcess($script:Task,'Guardar referencias y programar vigilancia');return}
 if(-not (Test-Admin)){Invoke-Elevated 'Prepare';return}
 $services=@(Get-GoogleServices)
 if($services.Count -eq 0){throw 'No hay servicios Google Update detectados.'}
 $path=Get-ConfigPath
 $config=Read-Config $path
 [void]([ChromeAlertData.Document]::new($config.Data)).Filters()
 $tasks=@(Get-OwnTask)
 if($tasks.Count -gt 0){Assert-OwnTask $tasks[0];if($tasks[0].State -eq 'Running'){throw 'Espere a que termine la tarea.'}}
 if(-not $PSCmdlet.ShouldProcess($script:Task,'Guardar referencias e instalar/actualizar tarea con privilegios')){return}
 Save-Json $script:Reference ([ordered]@{Computer=$env:COMPUTERNAME;Sid=$script:Sid;ConfigPath=$path;SavedAt=(Get-Date).ToString('o');Services=$services})
 if([IO.Path]::GetFullPath($script:Source) -ne [IO.Path]::GetFullPath($script:Installed)){Copy-Item -LiteralPath $script:Source -Destination $script:Installed -Force}
 $exe=Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
 $arguments='-NoProfile -NonInteractive -WindowStyle Hidden -File "'+$script:Installed+'" -Action Watch -ExpectedSid "'+$script:Sid+'"'
 $act=New-ScheduledTaskAction -Execute $exe -Argument $arguments
 $triggers=@((New-ScheduledTaskTrigger -Daily -At '09:00'),(New-ScheduledTaskTrigger -AtLogOn -User $script:Sid))
 $principal=New-ScheduledTaskPrincipal -UserId $script:Sid -LogonType Interactive -RunLevel Highest
 $settings=New-ScheduledTaskSettingsSet -StartWhenAvailable -MultipleInstances IgnoreNew -ExecutionTimeLimit (New-TimeSpan -Minutes 5)
 Register-ScheduledTask -TaskName $script:Task -TaskPath '\' -Action $act -Trigger $triggers -Principal $principal -Settings $settings -Description $script:Description -Force | Out-Null
 $script:PrepareCompleted=$true
 Write-Host 'Referencias guardadas. Vigilancia: 09:00 y al iniciar sesion; comprobara y reaplicara el filtro sin abrir ventanas.'
 Write-Host 'La tarea usa esta cuenta y requiere sesion iniciada; tambien puede trabajar con la sesion bloqueada.'
}
function Invoke-Watch {
 if($WhatIfPreference){[void]$PSCmdlet.ShouldProcess('Filtro de Google Update','Comprobar y aplicar');return}
 $ok=$false;$result=''
 try{Invoke-DirectSolution;$ok=$true;$result='Filtro de Google Update comprobado y actualizado si era necesario.'}
 catch{$result='Fallo: '+$_.Exception.Message}
 Save-Json $script:Report ([ordered]@{CheckedAt=(Get-Date).ToString('o');Success=$ok;Result=$result})
 if(-not $ok){Write-Error $result -ErrorAction Continue;exit 2}
}
function Undo-All {
 $script:UndoCompleted=$false
 $tasks=@(Get-OwnTask)
 if($tasks.Count -gt 0){Assert-OwnTask $tasks[0];if($tasks[0].State -eq 'Running'){throw 'Espere a que termine la vigilancia.'}}
 if($WhatIfPreference){[void]$PSCmdlet.ShouldProcess($script:Root,'Deshacer ajustes y retirar referencias y tarea');return}
 if($tasks.Count -gt 0 -and -not (Test-Admin)){Invoke-Elevated 'Undo';return}
 if(-not $PSCmdlet.ShouldProcess($script:Root,'Deshacer las exclusiones propias y retirar referencias y tarea')){return}
 Write-Host '[1/3] Restaurar las referencias de monitorizacion...'
 if(Test-Path -LiteralPath $script:State){Invoke-DirectSolution -Undo -Approved}
 Write-Host '[2/3] Retirar la tarea propia de vigilancia...'
 if($tasks.Count -gt 0){Unregister-ScheduledTask -TaskName $script:Task -TaskPath '\' -Confirm:$false}
 Write-Host '[3/3] Eliminar referencias propias...'
 foreach($name in @('direct-state.json','baseline.json','latest.json','user.config.recovery')){
  $file=Join-Path $script:Root $name;if(Test-Path -LiteralPath $file){Remove-Item -LiteralPath $file -Force}
 }
 $script:UndoCompleted=$true
 Write-Host 'DESHACER completado. Se mantienen los filtros ajenos y las actualizaciones de Chrome.'
}
function Show-Diagnosis {
 $services=@(Get-GoogleServices)
 $path=Get-ConfigPath
 $document=[ChromeAlertData.Document]::new((Read-Config $path).Data)
 $filters=@($document.Filters() | Where-Object {$_.Scope -eq 'ServerGroupBasedSettings' -and $_.Key -in @(0,1)})
 @($services | ForEach-Object {
  $service=$_
  $count=@($filters | Where-Object {$service.DisplayName -in $_.Names}).Count
  [pscustomobject]@{Servicio=$service.Name;Estado=$service.State;Inicio=$service.StartMode;FiltrosConReferencia=($count.ToString()+'/2')}
 }) | Format-Table -Wrap -AutoSize | Out-Host
 if($UiSession){
  foreach($item in $services){
   $count=@($filters | Where-Object {$item.DisplayName -in $_.Names}).Count
   Write-VisualEvent -Kind Info -Text ($item.Name+"`n  Estado: "+$item.State+' | Inicio: '+$item.StartMode+' | Filtros: '+$count+'/2')
  }
 }
 Write-Host 'Lectura del filtro guardado del perfil. La consola puede tener cambios sin guardar.'
 if(Test-Path -LiteralPath $script:Report){
  $report=Get-Content -LiteralPath $script:Report -Raw | ConvertFrom-Json
  if($report.PSObject.Properties.Name -contains 'Result'){Write-Host ($report.CheckedAt+' | '+$report.Result)}
 }
}



function Find-SchedulerLibrary {
 param($Namespace,$Node,[int]$Depth=0)
 if($null -eq $Node -or $Depth -gt 2){return $null}
 if([string]$Node.Name -match '^(Biblioteca del Programador(?: de tareas)?|Task Scheduler Library)$'){return $Node}
 # Solo raiz de la consola y nodo local; no recorrer carpetas de tareas.
 if($Depth -eq 2){return $null}
 $Namespace.Expand($Node)
 $child=$Namespace.GetChild($Node)
 $count=0
 while($null -ne $child -and $count -lt 16){
  $found=Find-SchedulerLibrary $Namespace $child ($Depth+1)
  if($null -ne $found){return $found}
  $child=$Namespace.GetNext($child);$count++
 }
 return $null
}
function Open-WatchTaskScheduler {
 $console=Join-Path $env:SystemRoot 'System32\taskschd.msc'
 $log=Join-Path $env:TEMP 'ChromePanelFix-Biblioteca.log'
 $mmc=$null
 try{
  if(-not (Test-Path -LiteralPath $console)){throw 'No se encuentra taskschd.msc.'}
  Write-Host 'Abriendo Biblioteca del Programador...'
  $mmc=New-Object -ComObject MMC20.Application
  $mmc.Load($console)
  $mmc.UserControl=1
  $mmc.Show()
  $namespace=$mmc.Document.ScopeNamespace
  $library=Find-SchedulerLibrary $namespace ($namespace.GetRoot())
  if($null -eq $library){throw 'MMC no ha expuesto el nodo Biblioteca.'}
  $view=$mmc.Document.ActiveView
  $view.ScopeTreeVisible=$true
  # API COM de MMC: no es el metodo SelectScopeNode de la API .NET de snap-ins.
  $view.ActiveScopeNode=$library
  $actual=[string]$mmc.Document.ActiveView.ActiveScopeNode.Name
  if($actual -ne [string]$library.Name){throw ('MMC mantiene otro nodo activo: '+$actual)}
  $result='Biblioteca seleccionada y confirmada por MMC: '+$actual
  Write-Host $result
  try{$result | Set-Content -LiteralPath $log -Encoding UTF8}catch{}
 }catch{
  $message=$_.Exception.Message
  try{('Fecha: '+(Get-Date).ToString('o')+[Environment]::NewLine+$_) | Set-Content -LiteralPath $log -Encoding UTF8}catch{}
  Write-Host ('Operacion realizada; apertura de Biblioteca NO confirmada: '+$message)
  Write-Host ('Registro: '+$log)
 }finally{
  # La consola queda bajo control del usuario, incluso al terminar este proceso.
  if($null -ne $mmc -and [Runtime.InteropServices.Marshal]::IsComObject($mmc)){
   [void][Runtime.InteropServices.Marshal]::ReleaseComObject($mmc)
  }
 }
}
function Confirm-WatchInstallation {
 $tasks=@(Get-OwnTask)
 if($tasks.Count -ne 1){throw 'No se confirma una unica tarea de vigilancia.'}
 Assert-OwnTask $tasks[0]
 if($tasks[0].Description -ne $script:Description -or
    [string]$tasks[0].Principal.RunLevel -notin @('Highest','1') -or
    ([string]$tasks[0].Actions[0].Arguments) -notmatch '-Action Watch' -or
    -not $tasks[0].Settings.Enabled){
  throw 'La tarea no tiene la configuracion esperada o esta deshabilitada.'
 }
 if(-not (Test-Path -LiteralPath $script:Installed)){throw 'Falta la copia instalada del script.'}
 if((Get-FileHash -LiteralPath $script:Source -Algorithm SHA256).Hash -ne
    (Get-FileHash -LiteralPath $script:Installed -Algorithm SHA256).Hash){
  throw 'La copia instalada no coincide con el script que se esta ejecutando.'
 }
}
function Invoke-CompleteSolution {
 if($WhatIfPreference){
  [void]$PSCmdlet.ShouldProcess('Filtros, vigilancia y Administrador del Servidor','Aplicar la solucion completa')
  return
 }
 if(-not (Test-Admin)){Invoke-Elevated 'Apply';return}
 $manager=Join-Path $env:SystemRoot 'System32\ServerManager.exe'
 if(-not (Test-Path -LiteralPath $manager)){throw 'Administrador del Servidor no esta instalado.'}
 $tasks=@(Get-OwnTask)
 if($tasks.Count -gt 0){
  Assert-OwnTask $tasks[0]
  if($tasks[0].State -eq 'Running'){throw 'La vigilancia se esta ejecutando. Espere y vuelva a elegir 3.'}
 }
 if(-not $PSCmdlet.ShouldProcess('Filtros, vigilancia y Administrador del Servidor','Aplicar la solucion completa')){return}
 try{
  Write-Host '[1/3] Aplicar o comprobar la reparacion de los filtros de Google Update...'
  Invoke-DirectSolution
  Write-Host '[2/3] Guardar referencias y crear o actualizar la vigilancia...'
  Prepare-Watch
  Confirm-WatchInstallation
  Write-Host '[3/3] Abrir Administrador del Servidor para comprobar el resultado...'
  Start-Process -FilePath $manager -WindowStyle Normal | Out-Null
  Open-WatchTaskScheduler
  Write-Host 'Proceso completo: filtros procesados, vigilancia instalada y comprobada, apertura del panel solicitada.' -ForegroundColor Green
  Write-Host 'Compruebe los recuadros Servidor local y Todos los servidores.'
 }catch{
  throw ('Proceso incompleto: '+$_.Exception.Message+' Los pasos ya aplicados se conservan; puede volver a ejecutar 3.')
 }
}

function Confirm-Action24 {
 param([ValidateSet('Prepare','Undo')][string]$Selected)
 if($Selected -eq 'Prepare'){
  Confirm-WatchInstallation
  if(-not (Test-Path -LiteralPath $script:Reference)){throw 'Faltan las referencias.'}
  $reference=Get-Content -LiteralPath $script:Reference -Raw | ConvertFrom-Json
  if($reference.Sid -ne $script:Sid){throw 'Las referencias no pertenecen a esta cuenta.'}
 }else{
  if(@(Get-OwnTask).Count -ne 0){throw 'La tarea sigue registrada.'}
  foreach($name in @('direct-state.json','baseline.json','latest.json','user.config.recovery')){
   if(Test-Path -LiteralPath (Join-Path $script:Root $name)){throw ('Queda pendiente de retirar: '+$name)}
  }
 }
 Write-Host 'Operacion terminada y verificada.'
}
function Run-Action {
 param([string]$Selected)
 if($Selected -in @('Prepare','Undo') -and -not $WhatIfPreference -and -not (Test-Admin)){Invoke-Elevated $Selected;return}
 try{
  switch($Selected){
   Diagnose{Show-Diagnosis}
   Prepare{
    Prepare-Watch
    if(-not $WhatIfPreference -and $script:PrepareCompleted){Confirm-Action24 'Prepare';Open-WatchTaskScheduler}
   }
   Apply{
    Write-Host 'EJECUCION DIRECTA: no necesita ejecutar antes las opciones 1 ni 2.' -ForegroundColor Cyan
    Write-Host 'Incluye reparacion, referencias, tarea de vigilancia y apertura del Administrador del Servidor.'
    Invoke-CompleteSolution
   }
   Watch{Invoke-Watch}
   Undo{Undo-All;if(-not $WhatIfPreference -and $script:UndoCompleted){Confirm-Action24 'Undo';Open-WatchTaskScheduler}}
  }
 }catch [UnauthorizedAccessException]{
  if(Test-Admin){throw}
  Invoke-Elevated $Selected
 }
}
# Lectura/escritura NRBF sin BinaryFormatter ni instanciacion de tipos del archivo.
if(-not ('ChromeAlertData.Document' -as [type])) {
Add-Type -TypeDefinition @'
using System;
using System.IO;
using System.Text;
using System.Linq;
using System.Collections.Generic;
namespace ChromeAlertData {
public class Node {
 public int Kind,Id,Count=1; public string TypeName;
 public byte[] Raw;
 public List<Node> Children=new List<Node>();
 public Dictionary<string,Node> Fields=new Dictionary<string,Node>();
 public object Value; public int LengthOffset=-1; public int ArrayLength; public bool Changed;
}
class Meta {public string Name; public string[] Names; public byte[] Types;public object[] Info;}
public class Filter {
 public string Scope; public int Key; public string[] Names;
 internal Node Set,Elements;
}
public class Document {
 byte[] data; BinaryReader r;
 Dictionary<int,Node> ids=new Dictionary<int,Node>();
 Dictionary<int,Meta> meta=new Dictionary<int,Meta>();
 List<Node> records=new List<Node>();
 int maxId=0,steps=0;
 public Document(byte[] bytes) {
  if(bytes==null||bytes.Length>10000000)throw new InvalidDataException("Tamano no admitido");
  data=bytes;r=new BinaryReader(new MemoryStream(bytes),Encoding.UTF8);
  while(r.BaseStream.Position<r.BaseStream.Length){Node n=ReadRecord();records.Add(n);if(n.Kind==11)break;}
  if(r.BaseStream.Position!=r.BaseStream.Length||records.Count==0||records.Last().Kind!=11)throw new InvalidDataException("Fin NRBF invalido");
 }
 byte[] Slice(long a,long b){return data.Skip((int)a).Take((int)(b-a)).ToArray();}
 int I(){return r.ReadInt32();}
 int Limit(int n){if(n<0||n>100000)throw new InvalidDataException("Limite NRBF");return n;}
 string S(){string s=r.ReadString();if(s.Length>1000000)throw new InvalidDataException("Cadena demasiado larga");return s;}
 Node Register(Node n,int id){n.Id=id;ids.Add(id,n);if(id>maxId)maxId=id;return n;}
 object Additional(byte t){switch(t){case 0:case 7:return r.ReadByte();case 3:return S();case 4:return new object[]{S(),I()};case 1:case 2:case 5:case 6:return null;default:throw new InvalidDataException("Tipo binario no admitido");}}
 Node Primitive(byte t){
  long start=r.BaseStream.Position;object v;
  switch(t){
   case 1:v=r.ReadBoolean();break;case 2:v=r.ReadByte();break;case 3:v=r.ReadChar();break;
   case 5:v=S();break;case 6:v=r.ReadDouble();break;case 7:v=r.ReadInt16();break;case 8:v=I();break;
   case 9:v=r.ReadInt64();break;case 10:v=r.ReadSByte();break;case 11:v=r.ReadSingle();break;
   case 12:case 13:v=r.ReadInt64();break;case 14:v=r.ReadUInt16();break;case 15:v=r.ReadUInt32();break;
   case 16:v=r.ReadUInt64();break;default:throw new InvalidDataException("Primitivo no admitido "+t);
  }return new Node{Kind=-1,Value=v,Raw=Slice(start,r.BaseStream.Position)};
 }
 Node ReadValue(){Node n=ReadRecord();if(n.Kind==12){Node w=new Node{Kind=-2,Raw=new byte[0]};w.Children.Add(n);w.Children.Add(ReadValue());return w;}return n;}
 void Members(Node n,Meta m,long start){
  n.TypeName=m.Name;n.Raw=Slice(start,r.BaseStream.Position);
  for(int j=0;j<m.Names.Length;j++){
   Node child=m.Types[j]==0?Primitive((byte)m.Info[j]):ReadValue();
   n.Children.Add(child);n.Fields.Add(m.Names[j],child);
  }
 }
 Node ReadRecord(){
  if(++steps>100000)throw new InvalidDataException("Demasiados registros");
  long start=r.BaseStream.Position;int kind=r.ReadByte();Node n=new Node{Kind=kind};
  switch(kind){
   case 0: {int root=I();I();int major=I(),minor=I();if(root!=1||major!=1||minor!=0)throw new InvalidDataException("Cabecera no compatible");break;}
   case 12:I();S();break;
   case 11:case 10:break;
   case 13:n.Count=r.ReadByte();break;case 14:n.Count=Limit(I());break;
   case 9:n.Value=I();break;
   case 6:Register(n,I());n.Value=S();break;
   case 8:{byte t=r.ReadByte();n.Raw=Slice(start,r.BaseStream.Position);n.Children.Add(Primitive(t));return n;}
   case 1:{
    Register(n,I());int mid=I();Meta m;if(!meta.TryGetValue(mid,out m))throw new InvalidDataException("Metadatos no encontrados");
    Members(n,m,start);return n;
   }
   case 4:case 5:{
    Register(n,I());string name=S();int count=Limit(I());string[] names=new string[count];
    for(int i=0;i<count;i++)names[i]=S();
    byte[] types=r.ReadBytes(count);if(types.Length!=count)throw new EndOfStreamException();
    object[] info=new object[count];for(int i=0;i<count;i++)info[i]=Additional(types[i]);
    if(kind==5)I();
    Meta m=new Meta{Name=name,Names=names,Types=types,Info=info};meta.Add(n.Id,m);
    Members(n,m,start);return n;
   }
   case 7:{
    Register(n,I());byte shape=r.ReadByte();int rank=Limit(I());if(rank!=1||shape!=0)throw new InvalidDataException("Solo matrices simples");
    n.LengthOffset=(int)(r.BaseStream.Position-start);n.ArrayLength=Limit(I());byte t=r.ReadByte();object info=Additional(t);
    n.Raw=Slice(start,r.BaseStream.Position);
    ArrayMembers(n,t,info);return n;
   }
   case 15:case 16:case 17:{
    Register(n,I());n.LengthOffset=(int)(r.BaseStream.Position-start);n.ArrayLength=Limit(I());
    byte t=kind==15?(byte)0:(byte)2;object info=kind==15?(object)r.ReadByte():null;
    n.Raw=Slice(start,r.BaseStream.Position);ArrayMembers(n,t,info);return n;
   }
   default:throw new InvalidDataException("Registro NRBF no admitido: "+kind);
  }
  n.Raw=Slice(start,r.BaseStream.Position);return n;
 }
 void ArrayMembers(Node n,byte type,object info){
  for(int count=0;count<n.ArrayLength;){
   Node v=type==0?Primitive((byte)info):ReadValue();n.Children.Add(v);count+=v.Count;
   if(count>n.ArrayLength)throw new InvalidDataException("Longitud de matriz invalida");
  }
 }
 Node Resolve(Node n){
  int depth=0;
  while(true){
   if(++depth>50)throw new InvalidDataException("Referencias ciclicas");
   if(n.Kind==-2){n=n.Children.Last();continue;}
   if(n.Kind==9){Node target;if(!ids.TryGetValue((int)n.Value,out target))throw new InvalidDataException("Referencia inexistente");n=target;continue;}
   return n;
  }
 }
 Node Field(Node n,string suffix){
  n=Resolve(n);
  var matches=n.Fields.Where(x=>x.Key==suffix||x.Key.Contains("<"+suffix+">")).ToArray();
  if(matches.Length!=1)throw new InvalidDataException("Campo no compatible "+suffix);
  return Resolve(matches[0].Value);
 }
 public Filter[] Filters(){
  Node root;if(!ids.TryGetValue(1,out root)||root.TypeName!="Microsoft.Windows.ServerManager.Common.Data.ServicesDashboardSettings")
   throw new InvalidDataException("Raiz ServicesDashboardSettings no reconocida");
  List<Filter> output=new List<Filter>();
  foreach(string scope in new[]{"RoleBasedSettings","ServerGroupBasedSettings"}){
   Node dict=Field(root,scope);
   if(!dict.Fields.ContainsKey("KeyValuePairs"))continue;
   Node pairs=Resolve(dict.Fields["KeyValuePairs"]);
   foreach(Node pair in pairs.Children){
    Node value=Field(pair,"value");Node key=Field(pair,"key");Node set=Field(value,"ServicesList");
    if(set.TypeName==null||!set.TypeName.StartsWith("System.Collections.Generic.HashSet"))throw new InvalidDataException("No es HashSet");
    Node elements=set.Fields.ContainsKey("Elements")?Field(set,"Elements"):null;
    string[] names=elements==null?new string[0]:elements.Children.Select(x=>(string)Resolve(x).Value).ToArray();
    output.Add(new Filter{Scope=scope,Key=Convert.ToInt32(key.Value),Names=names,Set=set,Elements=elements});
   }
  }return output.ToArray();
 }
 void WriteNode(BinaryWriter w,Node n){w.Write(n.Raw);foreach(Node child in n.Children)WriteNode(w,child);}
 public byte[] Bytes(){using(var m=new MemoryStream()){using(var w=new BinaryWriter(m,Encoding.UTF8,true)){foreach(var n in records)WriteNode(w,n);}return m.ToArray();}}
 public string[] AddExceptions(string[] displayNames){
  var targets=Filters().Where(f=>f.Scope=="ServerGroupBasedSettings"&&(f.Key==0||f.Key==1)).ToArray();
  if(targets.Length!=2||targets.Select(f=>f.Key).Distinct().Count()!=2)throw new InvalidDataException("Se requieren los grupos 0 y 1 existentes");
  List<string> changes=new List<string>();
  foreach(Filter f in targets){
   if(f.Elements==null||!f.Names.Contains("Todo"))throw new InvalidDataException("No se reconoce el modo Todo del filtro "+f.Key);
   int beforeCount=changes.Count;
   foreach(string name in displayNames){
    if(f.Names.Contains(name))continue;
    Node value=new Node{Kind=6,Id=++maxId,Value=name};
    using(var m=new MemoryStream()){using(var w=new BinaryWriter(m,Encoding.UTF8,true)){w.Write((byte)6);w.Write(value.Id);w.Write(name);}value.Raw=m.ToArray();}
    f.Elements.Children.Add(value);f.Elements.ArrayLength++;ids.Add(value.Id,value);
    changes.Add(f.Key+":"+name);
   }
   if(changes.Count==beforeCount)continue;
   byte[] raw=(byte[])f.Elements.Raw.Clone();
   Array.Copy(BitConverter.GetBytes(f.Elements.ArrayLength),0,raw,f.Elements.LengthOffset,4);f.Elements.Raw=raw;
   Node capacity=Field(f.Set,"Capacity");int cap=Convert.ToInt32(capacity.Value);
   if(cap<f.Elements.ArrayLength){capacity.Value=f.Elements.ArrayLength;capacity.Raw=BitConverter.GetBytes(f.Elements.ArrayLength);}
   Node version=Field(f.Set,"Version");version.Value=Convert.ToInt32(version.Value)+1;version.Raw=BitConverter.GetBytes((int)version.Value);
  }
  return changes.ToArray();
 }

 public string[] RemoveExceptions(string[] changes){
  var filters=Filters();List<string> removed=new List<string>();
  foreach(Filter f in filters.Where(x=>x.Scope=="ServerGroupBasedSettings"&&(x.Key==0||x.Key==1))){
   var wanted=new HashSet<string>(StringComparer.Ordinal);
   foreach(string entry in changes){
    int colon=entry.IndexOf(':');if(colon<1)throw new InvalidDataException("Referencia de reversion invalida");
    if(entry.Substring(0,colon)==f.Key.ToString())wanted.Add(entry.Substring(colon+1));
   }
   if(wanted.Count==0)continue;
   if(f.Elements==null||!f.Names.Contains("Todo"))throw new InvalidDataException("Modo del filtro no compatible");
   int count=0;
   for(int i=f.Elements.Children.Count-1;i>=0;i--){
    Node child=f.Elements.Children[i];string text=(string)Resolve(child).Value;
    if(!wanted.Contains(text))continue;
    if(child.Kind!=6&&child.Kind!=9)throw new InvalidDataException("Cadena de reversion no compatible");
    // Conservar definiciones de cadenas por si otro filtro las referencia.
    if(child.Kind==6)records.Insert(records.Count-1,child);
    f.Elements.Children.RemoveAt(i);f.Elements.ArrayLength--;count++;
    removed.Add(f.Key+":"+text);
   }
   if(count==0)continue;
   byte[] raw=(byte[])f.Elements.Raw.Clone();
   Array.Copy(BitConverter.GetBytes(f.Elements.ArrayLength),0,raw,f.Elements.LengthOffset,4);f.Elements.Raw=raw;
   Node version=Field(f.Set,"Version");version.Value=Convert.ToInt32(version.Value)+1;version.Raw=BitConverter.GetBytes((int)version.Value);
  }return removed.ToArray();
 }
}}

'@
}
if($env:OS -ne 'Windows_NT'){throw 'Solo para Windows.'}
$mutex=New-Object Threading.Mutex($false,('Global\GoogleUpdateAlertMonitor-'+$script:Sid))
$locked=$false
try{
 try{$locked=$mutex.WaitOne(0)}catch [Threading.AbandonedMutexException]{$locked=$true}
 if(-not $locked){throw 'Otra ejecucion de esta herramienta esta activa en esta sesion.'}
 if($Action -ne 'Menu'){
  try{Run-Action $Action;Write-VisualEvent -Kind Completed -Text 'Operacion completada.'}
  catch{Write-VisualEvent -Kind Error -Text $_.Exception.Message;throw}
  return
 }
 do{
  Write-Host @'

 CHROMEPANELFIX | 9.0 GUI OPERATIVO - ALERTAS DE GOOGLE CHROME
 ---------------------------------------------------------------
 PUEDE EJECUTAR 3 DIRECTAMENTE: no requiere ejecutar 1 ni 2.
 1 solo diagnostica. 2 permite programar la vigilancia por separado.
 3 repara, guarda referencias, programa vigilancia y abre el panel.
 ---------------------------------------------------------------
 1. Diagnosticar estado servicios Google Chrome en Administrador del Servidor (solo lectura)
 2. Guardar referencias y crear tarea de vigilancia (09:00 y al iniciar sesion)
 3. Ejecutar solucion completa (reparacion + vigilancia + abrir panel)
 4. DESHACER: Eliminar referencias y tarea programada
 5. Salir
'@
  $choice=Read-Host 'Opcion'
  try{
   switch($choice){
    '1'{
     Show-Diagnosis
     do{
      $letter=Read-Host 'A-Mostrar Administrador del Servidor | V-Volver'
      if($letter -eq 'A'){Start-Process -FilePath (Join-Path $env:SystemRoot 'System32\ServerManager.exe') -WindowStyle Normal | Out-Null}
     }while($letter -ne 'V')
    }
    '2'{Run-Action 'Prepare'}
    '3'{Run-Action 'Apply'}
    '4'{Run-Action 'Undo'}
    '5'{}
    default{Write-Warning 'Elija del 1 al 5.'}
   }
  }catch{Write-Warning $_.Exception.Message}
  if($choice -ne '5'){[void](Read-Host 'Pulse Entrar para continuar')}
 }while($choice -ne '5')
}finally{if($locked){$mutex.ReleaseMutex()};$mutex.Dispose()}









