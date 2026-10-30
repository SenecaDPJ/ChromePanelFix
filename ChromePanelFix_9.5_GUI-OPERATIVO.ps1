#requires -Version 5.1
[CmdletBinding()]
param([string]$PreviewPath,[ValidateSet('Menu','ApplyManual','ApplyManualQuiet','Apply','Undo','Exit')][string]$PreviewMode='Menu')
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[Windows.Forms.Application]::EnableVisualStyles()
$script:NL=[Environment]::NewLine
$script:Palette=@{
 Green=[Drawing.ColorTranslator]::FromHtml('#4ADE80')
 Info=[Drawing.ColorTranslator]::FromHtml('#60A5FA')
 Banner=[Drawing.ColorTranslator]::FromHtml('#F59E0B')
 Menu=[Drawing.ColorTranslator]::FromHtml('#38BDF8')
 Exec=[Drawing.ColorTranslator]::FromHtml('#FB923C')
 Gold=[Drawing.ColorTranslator]::FromHtml('#D4AF37')
}
$script:Fonts=@{}
foreach($pair in @(@('General',1),@('Info',2),@('Banner',2),@('Menu',1),@('Exec',3),@('Exit',5))){
 $script:Fonts[$pair[0]]=New-Object Drawing.Font('Consolas',[single](11+$pair[1]),[Drawing.FontStyle]::Regular,[Drawing.GraphicsUnit]::Point)
}
$script:Fonts.Signature=New-Object Drawing.Font('Segoe UI',[single]9,[Drawing.FontStyle]::Italic,[Drawing.GraphicsUnit]::Point)
$script:Fonts.GitHub=New-Object Drawing.Font('Segoe UI',[single]8,[Drawing.FontStyle]::Bold,[Drawing.GraphicsUnit]::Point)
$script:Fonts.Exit.Dispose()
$script:Fonts.Exit=New-Object Drawing.Font('Segoe UI Emoji',17,[Drawing.FontStyle]::Regular,[Drawing.GraphicsUnit]::Point)
$script:Core=Join-Path $PSScriptRoot 'ChromePanelFix.Core.ps1'
$script:Root=Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'GoogleUpdateAlertMonitor'
$script:Engine=$null;$script:EngineId='';$script:ReadLines=0
$script:CurrentAction='';$script:Stage=0;$script:Frame=0
$script:CompletionSeen=$false;$script:LastError=''
$script:Exiting=$false;$script:ExitFrame=0
function New-Label {
 param([string]$Text,[string]$Style='General')
 $label=New-Object Windows.Forms.Label
 $label.Text=$Text;$label.BackColor=[Drawing.Color]::Black
 $label.ForeColor=$script:Palette.Green;$label.Font=$script:Fonts[$Style]
 $label.AutoSize=$false;$label.Dock='Fill';$label.TextAlign='MiddleLeft'
 $label
}
$script:Form=New-Object Windows.Forms.Form
$script:Form.Text='ChromePanelFix 9.5 | GUI OPERATIVO'
$script:Form.ShowIcon=$true
$script:Form.ShowInTaskbar=$true
$script:IconPath=Join-Path $PSScriptRoot 'assets\ChromePanelFix.ico'
$script:AppIcon=$null
if(Test-Path -LiteralPath $script:IconPath -PathType Leaf){
 $script:AppIcon=New-Object Drawing.Icon($script:IconPath)
 $script:Form.Icon=$script:AppIcon
}
$script:Form.BackColor=[Drawing.Color]::Black;$script:Form.ForeColor=$script:Palette.Green
$script:Form.Font=$script:Fonts.General
$workArea=[Windows.Forms.Screen]::PrimaryScreen.WorkingArea
$initialWidth=[int][Math]::Min(1280,[Math]::Max(840,$workArea.Width-64))
$initialHeight=[int][Math]::Min(920,[Math]::Max(640,$workArea.Height-64))
$initialWidth=[int][Math]::Min($initialWidth,$workArea.Width)
$initialHeight=[int][Math]::Min($initialHeight,$workArea.Height)
$script:Form.Size=New-Object Drawing.Size($initialWidth,$initialHeight)
$script:Form.MinimumSize=New-Object Drawing.Size([Math]::Min(1040,$initialWidth),[Math]::Min(760,$initialHeight))
$script:Form.StartPosition='CenterScreen';$script:Form.AutoScaleMode='Dpi';$script:Form.KeyPreview=$true
$layout=New-Object Windows.Forms.TableLayoutPanel
$layout.Dock='Fill';$layout.Padding=New-Object Windows.Forms.Padding(26)
$layout.BackColor=[Drawing.Color]::Black;$layout.ColumnCount=1;$layout.RowCount=5
foreach($height in @(60,64,44)){[void]$layout.RowStyles.Add((New-Object Windows.Forms.RowStyle([Windows.Forms.SizeType]::Absolute,$height)))}
[void]$layout.RowStyles.Add((New-Object Windows.Forms.RowStyle([Windows.Forms.SizeType]::Percent,100)))
[void]$layout.RowStyles.Add((New-Object Windows.Forms.RowStyle([Windows.Forms.SizeType]::Absolute,42)))
$script:Form.Controls.Add($layout)
$header=New-Object Windows.Forms.Panel
$header.Dock='Fill';$header.BackColor=[Drawing.Color]::Black
$layout.Controls.Add($header,0,0)
$brand=New-Object Windows.Forms.FlowLayoutPanel
$brand.Dock='Right';$brand.Width=[int][Math]::Min(320,[Math]::Max(190,$initialWidth*0.30));$brand.BackColor=[Drawing.Color]::Black
$brand.WrapContents=$false;$brand.FlowDirection='LeftToRight';$brand.Padding=New-Object Windows.Forms.Padding(0,14,14,0)
$signature=New-Label '© 2026 David De Prado (Seneca DPJ)' 'Signature'
$signature.Width=[int][Math]::Max(110,$brand.Width-94);$signature.Height=28;$signature.ForeColor=$script:Palette.Gold
$signature.TextAlign='MiddleRight';$signature.Margin=New-Object Windows.Forms.Padding(0,0,6,0)
if($brand.Width -lt 220){$signature.Visible=$false}
$brand.Controls.Add($signature)
$script:GitHubButton=New-Object Windows.Forms.Button
$script:GitHubButton.Text='GitHub';$script:GitHubButton.AccessibleName='Abrir perfil de GitHub de SenecaDPJ'
$script:GitHubButton.Size=New-Object Drawing.Size(60,24);$script:GitHubButton.Font=$script:Fonts.GitHub;$script:GitHubButton.FlatStyle='Flat';$script:GitHubButton.FlatAppearance.BorderSize=1
$script:GitHubButton.FlatAppearance.BorderColor=$script:Palette.Gold;$script:GitHubButton.FlatAppearance.MouseOverBackColor=$script:Palette.Gold
$script:GitHubButton.BackColor=[Drawing.Color]::Black;$script:GitHubButton.ForeColor=$script:Palette.Gold
$script:GitHubButton.Margin=New-Object Windows.Forms.Padding(0);$script:GitHubButton.Cursor=[Windows.Forms.Cursors]::Hand
$script:GitHubButton.Add_MouseEnter({$script:GitHubButton.BackColor=$script:Palette.Gold;$script:GitHubButton.ForeColor=[Drawing.Color]::Black})
$script:GitHubButton.Add_MouseLeave({$script:GitHubButton.BackColor=[Drawing.Color]::Black;$script:GitHubButton.ForeColor=$script:Palette.Gold})
$script:GitHubButton.Add_Click({$answer=[Windows.Forms.MessageBox]::Show(('¿Desea abrir el perfil de GitHub de David De Prado (Seneca DPJ)?'+$script:NL+'https://github.com/SenecaDPJ'),'Abrir perfil de GitHub',[Windows.Forms.MessageBoxButtons]::YesNo,[Windows.Forms.MessageBoxIcon]::Question);if($answer -eq [Windows.Forms.DialogResult]::Yes){try{Start-Process 'https://github.com/SenecaDPJ' -ErrorAction Stop | Out-Null}catch{Add-VisualLine $_.Exception.Message 'Exec'}}})
$brand.Controls.Add($script:GitHubButton);$header.Controls.Add($brand)
$title=New-Label 'CHROMEPANELFIX  /  9.5' 'Banner'
$title.Dock='Left';$title.Width=[int][Math]::Max(240,[Math]::Min(520,$initialWidth-$brand.Width-40));$title.Margin=New-Object Windows.Forms.Padding(0)
$title.ForeColor=$script:Palette.Banner;$title.AutoEllipsis=$false
$header.Controls.Add($title);$title.BringToFront()
$intro=New-Label ('Control de alertas de Google Chrome'+$script:NL+'La opcion 2 aplica la solucion manual; la 4 incluye vigilancia programada.') 'Info'
$intro.ForeColor=$script:Palette.Info;$layout.Controls.Add($intro,0,1)
$pending=New-Label 'PENDIENTE: verificar la eficacia automatica de la tarea programada.' 'Banner'
$pending.ForeColor=$script:Palette.Banner;$layout.Controls.Add($pending,0,2)
$body=New-Object Windows.Forms.TableLayoutPanel
$body.Dock='Fill';$body.BackColor=[Drawing.Color]::Black;$body.ColumnCount=2;$body.RowCount=1
$navWidth=[int][Math]::Min(400,[Math]::Max(280,$initialWidth*0.31))
[void]$body.ColumnStyles.Add((New-Object Windows.Forms.ColumnStyle([Windows.Forms.SizeType]::Absolute,$navWidth)))
[void]$body.ColumnStyles.Add((New-Object Windows.Forms.ColumnStyle([Windows.Forms.SizeType]::Percent,100)))
$layout.Controls.Add($body,0,3)
$nav=New-Object Windows.Forms.TableLayoutPanel
$nav.Dock='Fill';$nav.ColumnCount=1;$nav.RowCount=8;$nav.BackColor=[Drawing.Color]::Black
[void]$nav.RowStyles.Add((New-Object Windows.Forms.RowStyle([Windows.Forms.SizeType]::Absolute,38)))
for($j=0;$j -lt 6;$j++){[void]$nav.RowStyles.Add((New-Object Windows.Forms.RowStyle([Windows.Forms.SizeType]::Percent,13)))}
[void]$nav.RowStyles.Add((New-Object Windows.Forms.RowStyle([Windows.Forms.SizeType]::Absolute,48)))
$body.Controls.Add($nav,0,0)
$navTitle=New-Label 'SELECCIONA UNA ACCION' 'General';$nav.Controls.Add($navTitle,0,0)
$script:Buttons=New-Object Collections.Generic.List[Windows.Forms.Button]
function New-ActionMenu {
 param([string[]]$OptionPairs)
 $menu=New-Object Windows.Forms.ContextMenuStrip
 $menu.BackColor=[Drawing.Color]::Black;$menu.ForeColor=$script:Palette.Menu
 $menu.Font=$script:Fonts.Menu;$menu.ShowImageMargin=$false
 for($j=0;$j -lt $OptionPairs.Count;$j+=2){
  $item=$menu.Items.Add($OptionPairs[$j]);$item.Tag=$OptionPairs[$j+1]
  $item.Add_Click({param($sender,$eventArgs) Invoke-VisualAction ([string]$sender.Tag)})
  $item.BackColor=[Drawing.Color]::Black;$item.ForeColor=$script:Palette.Menu
  $item.Padding=New-Object Windows.Forms.Padding(10,5,10,5)
 }
 $menu
}
$script:ActionMenus=@{
 ManualMenu=(New-ActionMenu -OptionPairs @('Aplicar y abrir Administrador del Servidor','ApplyManual','Aplicar sin abrir Administrador del Servidor','ApplyManualQuiet'))
 PrepareMenu=(New-ActionMenu -OptionPairs @('Guardar referencias y abrir Programador de tareas','PrepareOpenTask','Guardar referencias sin abrir Programador','PrepareQuiet'))
 ApplyMenu=(New-ActionMenu -OptionPairs @('Proceso completo y abrir ambos paneles','ApplyBoth','Proceso completo y abrir Administrador','ApplyManagerOnly','Proceso completo y abrir Programador','ApplyTaskOnly','Proceso completo sin abrir paneles','ApplyQuiet'))
 UndoMenu=(New-ActionMenu -OptionPairs @('DESHACER y abrir ambos paneles','UndoBoth','DESHACER y abrir Administrador','UndoManagerOnly','DESHACER y abrir Programador','UndoTaskOnly','DESHACER sin abrir paneles','UndoQuiet'))
}
$actions=@(
 @('1','Diagnosticar servicios','Solo lectura','Diagnose'),
 @('2','Aplicar solucion manual','Sin crear tarea programada','ManualMenu'),
 @('3','Guardar referencias','Opciones de vigilancia','PrepareMenu'),
 @('4','Ejecutar solucion','Opciones de paneles','ApplyMenu'),
 @('5','DESHACER','Restaurar y abrir paneles','UndoMenu'),
 @('6','Salir','Hasta la proxima','Exit')
)
for($i=0;$i -lt $actions.Count;$i++){
 $entry=$actions[$i]
 $row=New-Object Windows.Forms.TableLayoutPanel
 $row.Dock='Fill';$row.ColumnCount=2;$row.RowCount=1;$row.Margin=New-Object Windows.Forms.Padding(0,5,16,5)
 [void]$row.ColumnStyles.Add((New-Object Windows.Forms.ColumnStyle([Windows.Forms.SizeType]::Absolute,46)))
 [void]$row.ColumnStyles.Add((New-Object Windows.Forms.ColumnStyle([Windows.Forms.SizeType]::Percent,100)))
 $number=New-Label ($entry[0]+'.') 'General';$number.ForeColor=$script:Palette.Green;$row.Controls.Add($number,0,0)
 $button=New-Object Windows.Forms.Button
 $button.Text=$entry[1]+$script:NL+$entry[2];$button.Tag=$entry[3]
 $button.Dock='Fill';$button.FlatStyle='Flat'
 $button.FlatAppearance.BorderColor=[Drawing.ColorTranslator]::FromHtml('#183529')
 $button.FlatAppearance.MouseOverBackColor=[Drawing.ColorTranslator]::FromHtml('#07150E')
 $button.FlatAppearance.MouseDownBackColor=[Drawing.ColorTranslator]::FromHtml('#102820')
 $button.BackColor=[Drawing.Color]::Black;$button.ForeColor=$script:Palette.Menu
 $button.Font=$script:Fonts.Menu;$button.TextAlign='MiddleLeft'
 $button.Padding=New-Object Windows.Forms.Padding(12,0,0,0);$button.Cursor=[Windows.Forms.Cursors]::Hand
 $button.Add_Click({
  param($sender,$eventArgs)
  Invoke-VisualAction ([string]$sender.Tag)
 })
 $script:Buttons.Add($button);$row.Controls.Add($button,1,0);$nav.Controls.Add($row,0,$i+1)
}
$script:ShowManager=New-Object Windows.Forms.Button
$script:ShowManager.Text='A. Mostrar Administrador del Servidor'
$script:ShowManager.Font=$script:Fonts.Menu;$script:ShowManager.FlatStyle='Flat'
$script:ShowManager.ForeColor=$script:Palette.Menu;$script:ShowManager.BackColor=[Drawing.Color]::Black
$script:ShowManager.Dock='Fill';$script:ShowManager.Visible=$false
$script:ShowManager.Add_Click({
 try{Start-Process -FilePath (Join-Path $env:SystemRoot 'System32\ServerManager.exe') -WindowStyle Normal | Out-Null}
 catch{Add-VisualLine $_.Exception.Message 'Exec'}
})
$nav.Controls.Add($script:ShowManager,0,7)
$right=New-Object Windows.Forms.TableLayoutPanel
$right.Dock='Fill';$right.BackColor=[Drawing.Color]::Black;$right.ColumnCount=1;$right.RowCount=4
foreach($height in @(44,140,90)){[void]$right.RowStyles.Add((New-Object Windows.Forms.RowStyle([Windows.Forms.SizeType]::Absolute,$height)))}
[void]$right.RowStyles.Add((New-Object Windows.Forms.RowStyle([Windows.Forms.SizeType]::Percent,100)))
$body.Controls.Add($right,1,0)
$activityTitle=New-Label 'ACTIVIDAD' 'General';$right.Controls.Add($activityTitle,0,0)
$script:Figure=New-Label '[ LISTO ]' 'Exec'
$script:Figure.ForeColor=$script:Palette.Exec;$script:Figure.TextAlign='MiddleCenter'
$right.Controls.Add($script:Figure,0,1)
$script:Step=New-Label 'Listo. Puedes aplicar la solucion manual desde 2.' 'Info'
$script:Step.ForeColor=$script:Palette.Info;$right.Controls.Add($script:Step,0,2)
$script:Log=New-Object Windows.Forms.RichTextBox
$script:Log.Dock='Fill';$script:Log.ReadOnly=$true;$script:Log.BorderStyle='None'
$script:Log.BackColor=[Drawing.Color]::Black;$script:Log.ForeColor=$script:Palette.Green
$script:Log.Font=$script:Fonts.General;$script:Log.DetectUrls=$false;$script:Log.WordWrap=$true;$script:Log.ScrollBars='Vertical'
$right.Controls.Add($script:Log,0,3)
$footer=New-Label 'Chrome conserva sus actualizaciones.  |  9.5 GUI OPERATIVO' 'General'
$layout.Controls.Add($footer,0,4)
function Add-VisualLine {
 param([string]$Text,[string]$Style='Info')
 $script:Log.SelectionStart=$script:Log.TextLength;$script:Log.SelectionLength=0
 $script:Log.SelectionFont=$script:Fonts[$Style]
 $color=$script:Palette.Info
 if($Style -eq 'Exec'){$color=$script:Palette.Exec}
 elseif($Style -eq 'Exit' -or $Style -eq 'General'){$color=$script:Palette.Green}
 elseif($Style -eq 'Banner'){$color=$script:Palette.Banner}
 $script:Log.SelectionColor=$color
 $script:Log.AppendText($Text+$script:NL+$script:NL)
 $script:Log.SelectionStart=$script:Log.TextLength;$script:Log.ScrollToCaret()
}
function Set-ButtonsEnabled {
 param([bool]$Enabled)
 foreach($button in $script:Buttons){
  $button.Enabled=$Enabled;$button.TabStop=$Enabled
  if($Enabled){$button.Cursor=[Windows.Forms.Cursors]::Hand}else{$button.Cursor=[Windows.Forms.Cursors]::WaitCursor}
 }
 $script:ShowManager.Enabled=$Enabled
}
function Invoke-VisualAction {
 param([string]$Selected)
 if($script:Exiting -or $null -ne $script:Engine){return}
 if($script:ActionMenus.ContainsKey($Selected)){
  $anchor=@($script:Buttons | Where-Object {[string]$_.Tag -eq $Selected}) | Select-Object -First 1
  if($null -ne $anchor){$script:ActionMenus[$Selected].Show($anchor,0,$anchor.Height)}
  return
 }
 if($Selected -eq 'Exit'){
  $script:Exiting=$true;$script:ExitFrame=0;Set-ButtonsEnabled $false;$script:Log.Clear()
  $script:Figure.Font=$script:Fonts.Exit;$script:Figure.ForeColor=$script:Palette.Green
  $script:Step.Font=$script:Fonts.Exit;$script:Step.ForeColor=$script:Palette.Green
  $script:Step.Text='¡Gracias por utilizar ChromePanelFix!'+$script:NL+'Hasta otra, ¡buen día! 😜'

  return
 }
 if(-not (Test-Path -LiteralPath $script:Core)){Add-VisualLine 'Falta ChromePanelFix.Core.ps1. Extrae todos los archivos juntos.' 'Exec';return}
 try{
  $script:EngineId=[guid]::NewGuid().ToString('N')
  $script:ReadLines=0;$script:Stage=0;$script:Frame=0;$script:CompletionSeen=$false;$script:LastError=''
  $engineAction=$Selected;$skipManager=$false;$skipTaskScheduler=$false
  switch($Selected){
   ApplyManualQuiet{$engineAction='ApplyManual';$skipManager=$true}
   PrepareOpenTask{$engineAction='Prepare'}
   PrepareQuiet{$engineAction='Prepare';$skipTaskScheduler=$true}
   ApplyBoth{$engineAction='Apply'}
   ApplyManagerOnly{$engineAction='Apply';$skipTaskScheduler=$true}
   ApplyTaskOnly{$engineAction='Apply';$skipManager=$true}
   ApplyQuiet{$engineAction='Apply';$skipManager=$true;$skipTaskScheduler=$true}
   UndoBoth{$engineAction='Undo'}
   UndoManagerOnly{$engineAction='Undo';$skipTaskScheduler=$true}
   UndoTaskOnly{$engineAction='Undo';$skipManager=$true}
   UndoQuiet{$engineAction='Undo';$skipManager=$true;$skipTaskScheduler=$true}
  }
  $script:CurrentAction=$engineAction
  $script:ShowManager.Visible=($engineAction -eq 'Diagnose' -or ($engineAction -eq 'ApplyManual' -and -not $skipManager))
  $script:Log.Clear();$script:Step.Font=$script:Fonts.Exec;$script:Step.ForeColor=$script:Palette.Exec
  if($engineAction -in @('Apply','ApplyManual','Undo')){
   $script:Figure.Font=$script:Fonts.Exec;$script:Figure.ForeColor=$script:Palette.Exec
  }else{
   $script:Step.Font=$script:Fonts.Info;$script:Step.ForeColor=$script:Palette.Info
   $script:Figure.Font=$script:Fonts.General;$script:Figure.ForeColor=$script:Palette.Green
  }
  $script:Step.Text='Preparando la operacion...';Add-VisualLine ('Accion: '+$Selected) 'General'
  $exe=Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
  $sid=[Security.Principal.WindowsIdentity]::GetCurrent().User.Value
  $arguments='-NoProfile -NonInteractive -WindowStyle Hidden -File "'+$script:Core+'" -Action '+$engineAction+' -ExpectedSid "'+$sid+'" -UiSession '+$script:EngineId
  if($skipManager){$arguments+=' -SkipManager'}
  if($skipTaskScheduler){$arguments+=' -SkipTaskScheduler'}
  $psi=New-Object Diagnostics.ProcessStartInfo
  $psi.FileName=$exe;$psi.Arguments=$arguments;$psi.WindowStyle='Hidden'
  $principal=New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
  $needElevation=$engineAction -in @('Prepare','Apply','ApplyManual','Undo') -and -not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
  $psi.UseShellExecute=$needElevation
  if($needElevation){$psi.Verb='runas';Add-VisualLine 'Windows solicitara los privilegios necesarios.' 'Info'}
  else{$psi.CreateNoWindow=$true}
  $script:Engine=[Diagnostics.Process]::Start($psi);Set-ButtonsEnabled $false
 }catch{
  $script:Engine=$null;$script:Figure.Text='[ ! ]';$script:Step.Text='Operacion no iniciada.'
  Add-VisualLine $_.Exception.Message 'Exec';Set-ButtonsEnabled $true
 }
}
function Read-VisualEvents {
 if([string]::IsNullOrEmpty($script:EngineId)){return}
 $file=Join-Path $script:Root ('ui-'+$script:EngineId+'.jsonl')
 if(-not (Test-Path -LiteralPath $file)){return}
 try{$lines=@(Get-Content -LiteralPath $file -Encoding UTF8)}catch{return}
 for($i=$script:ReadLines;$i -lt $lines.Count;$i++){
  try{$entry=$lines[$i] | ConvertFrom-Json}catch{break}
  $script:ReadLines=$i+1
  if($entry.Kind -eq 'Completed'){$script:CompletionSeen=$true;continue}
  if($entry.Kind -eq 'Error'){$script:LastError=$entry.Text;Add-VisualLine $entry.Text 'Exec';continue}
  if($entry.Text -match '^\[(\d)/[23]\]\s*(.+)$'){
   $script:Stage=[int]$Matches[1];$script:Step.Text=$Matches[2];Add-VisualLine $entry.Text 'Exec'
  }else{Add-VisualLine $entry.Text 'Info'}
 }
}
$script:Timer=New-Object Windows.Forms.Timer
$script:Timer.Interval=160
$script:Timer.Add_Tick({
 if($script:Exiting){
  $frames=@('\o/','_o/','\o_','\o/')
  $script:Figure.Text=$frames[$script:ExitFrame % $frames.Count];$script:ExitFrame++
  if($script:ExitFrame -ge 12){$script:Timer.Stop();$script:Form.Close()}
  return
 }
 if($null -eq $script:Engine){return}
 Read-VisualEvents;$script:Frame++
 $spinner=@('|','/','-','\')[$script:Frame % 4]
 if($script:CurrentAction -in @('Apply','ApplyManual','ApplyManualQuiet','Undo')){
  $figures=@(('[ '+$spinner+' ]'),('[ ≡ ]  '+$spinner),('( ◷ )  '+$spinner),('[ ▣ ]  '+$spinner))
  if($script:CurrentAction -eq 'Undo'){$figures=@(('[ '+$spinner+' ]'),('[ ↶ ]  '+$spinner),('[ − ]  '+$spinner),('[ ⌫ ]  '+$spinner))}
  $script:Figure.Text=$figures[[Math]::Min(3,$script:Stage)]
 }else{$script:Figure.Text='[ '+$spinner+' ]'}
 if($script:Engine.HasExited){
  Read-VisualEvents;$exitCode=$script:Engine.ExitCode
  if($exitCode -eq 0 -and $script:CompletionSeen){
   $script:Figure.Text='[ ✓ ]';$script:Step.Text='Operacion completada.'
   Add-VisualLine 'Proceso finalizado correctamente.' 'Exec'
  }else{
   $script:Figure.Text='[ ! ]';$script:Step.Text='Proceso incompleto. Revisa el detalle.'
   if([string]::IsNullOrEmpty($script:LastError)){Add-VisualLine ('No se confirma la finalizacion. Codigo '+$exitCode+'. Revisa politica de ejecucion, cuenta y permisos.') 'Exec'}
  }
  $script:Engine.Dispose();$script:Engine=$null;Set-ButtonsEnabled $true
 }
})
$script:Form.Add_FormClosing({
 param($sender,$eventArgs)
 if($null -ne $script:Engine){$eventArgs.Cancel=$true;Add-VisualLine 'Espera a que termine la operacion para cerrar.' 'Info';return}
 if(-not $script:Exiting -and -not $PreviewPath){$eventArgs.Cancel=$true;Invoke-VisualAction 'Exit'}
})
$script:Form.Add_KeyDown({
 param($sender,$eventArgs)
 if($null -ne $script:Engine){return}
 $map=@{'D1'='Diagnose';'D2'='ManualMenu';'D3'='PrepareMenu';'D4'='ApplyMenu';'D5'='UndoMenu';'D6'='Exit';'NumPad1'='Diagnose';'NumPad2'='ManualMenu';'NumPad3'='PrepareMenu';'NumPad4'='ApplyMenu';'NumPad5'='UndoMenu';'NumPad6'='Exit'}
 if($map.ContainsKey($eventArgs.KeyCode.ToString())){Invoke-VisualAction $map[$eventArgs.KeyCode.ToString()];$eventArgs.Handled=$true}
})
Add-VisualLine 'Listo. Elige una accion o pulsa su numero.' 'General'
Add-VisualLine 'La opcion 2 aplica la solucion manual. La opcion 4 realiza el proceso completo con vigilancia.' 'Info'
if($null -eq $script:AppIcon){Add-VisualLine 'No se encontro assets\ChromePanelFix.ico; se usara el icono predeterminado de Windows.' 'Info'}
if($PreviewPath){
 if($PreviewMode -in @('ApplyManual','ApplyManualQuiet','Apply','Undo')){
  $script:Step.Font=$script:Fonts.Exec;$script:Step.ForeColor=$script:Palette.Exec
  $script:Figure.Text='( ◷ )  /'
  $script:Step.Text='Guardar referencias y programar vigilancia...'
  if($PreviewMode -in @('ApplyManual','ApplyManualQuiet')){$script:Figure.Text='[ + ]  /';$script:Step.Text='Aplicar solucion manual sin programar vigilancia...'}
  if($PreviewMode -eq 'Undo'){$script:Figure.Text='[ − ]  /';$script:Step.Text='Retirar la tarea propia de vigilancia...'}
  $script:Log.Clear()
  if($PreviewMode -in @('ApplyManual','ApplyManualQuiet')){
   Add-VisualLine '[1/2] Filtros de Google Update procesados.' 'Exec'
   Add-VisualLine '[2/2] Apertura del panel...' 'Exec'
  }else{
   Add-VisualLine '[1/3] Filtros de Google Update procesados.' 'Exec'
   Add-VisualLine '[2/3] Operacion en curso...' 'Exec'
  }
 }elseif($PreviewMode -eq 'Exit'){
  Invoke-VisualAction 'Exit';$script:Figure.Text='\o/'
 }
 $script:ShowManager.Visible=($PreviewMode -in @('Menu','ApplyManual','ApplyManualQuiet'))
 $script:Form.StartPosition='Manual';$script:Form.Location=New-Object Drawing.Point(-3000,-3000)
 $script:Form.Show();[Windows.Forms.Application]::DoEvents()
 $bitmap=New-Object Drawing.Bitmap($script:Form.Width,$script:Form.Height)
 $script:Form.DrawToBitmap($bitmap,$script:Form.ClientRectangle)
 $bitmap.Save($PreviewPath,[Drawing.Imaging.ImageFormat]::Png);$bitmap.Dispose()
 $script:Exiting=$true;$script:Form.Close()
}else{
 $script:Timer.Start();[Windows.Forms.Application]::Run($script:Form)
}
$script:Timer.Dispose();$script:Form.Dispose()
foreach($menu in $script:ActionMenus.Values){$menu.Dispose()}
if($null -ne $script:AppIcon){$script:AppIcon.Dispose()}
foreach($font in $script:Fonts.Values){$font.Dispose()}
