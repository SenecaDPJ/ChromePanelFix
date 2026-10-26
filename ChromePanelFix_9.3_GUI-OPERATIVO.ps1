#requires -Version 5.1
[CmdletBinding()]
param([string]$PreviewPath,[ValidateSet('Menu','Apply','Undo','Exit')][string]$PreviewMode='Menu')
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
 $script:Fonts[$pair[0]]=New-Object Drawing.Font('Consolas',[single](12+$pair[1]),[Drawing.FontStyle]::Regular,[Drawing.GraphicsUnit]::Point)
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
$script:Form.Text='ChromePanelFix 9.3 | GUI OPERATIVO'
$script:Form.BackColor=[Drawing.Color]::Black;$script:Form.ForeColor=$script:Palette.Green
$script:Form.Font=$script:Fonts.General
$script:Form.Size=New-Object Drawing.Size(1280,940)
$script:Form.MinimumSize=New-Object Drawing.Size(1120,820)
$script:Form.StartPosition='CenterScreen';$script:Form.AutoScaleMode='Dpi';$script:Form.KeyPreview=$true
$layout=New-Object Windows.Forms.TableLayoutPanel
$layout.Dock='Fill';$layout.Padding=New-Object Windows.Forms.Padding(26)
$layout.BackColor=[Drawing.Color]::Black;$layout.ColumnCount=1;$layout.RowCount=5
foreach($height in @(60,64,44)){[void]$layout.RowStyles.Add((New-Object Windows.Forms.RowStyle([Windows.Forms.SizeType]::Absolute,$height)))}
[void]$layout.RowStyles.Add((New-Object Windows.Forms.RowStyle([Windows.Forms.SizeType]::Percent,100)))
[void]$layout.RowStyles.Add((New-Object Windows.Forms.RowStyle([Windows.Forms.SizeType]::Absolute,42)))
$script:Form.Controls.Add($layout)
$header=New-Object Windows.Forms.TableLayoutPanel
$header.Dock='Fill';$header.BackColor=[Drawing.Color]::Black;$header.ColumnCount=2
[void]$header.ColumnStyles.Add((New-Object Windows.Forms.ColumnStyle([Windows.Forms.SizeType]::Percent,68)))
[void]$header.ColumnStyles.Add((New-Object Windows.Forms.ColumnStyle([Windows.Forms.SizeType]::Percent,32)))
$layout.Controls.Add($header,0,0)
$title=New-Label 'CHROMEPANELFIX  /  9.3' 'Banner'
$title.ForeColor=$script:Palette.Banner;$header.Controls.Add($title,0,0)
$brand=New-Object Windows.Forms.FlowLayoutPanel
$brand.Dock='Fill';$brand.BackColor=[Drawing.Color]::Black;$brand.WrapContents=$false;$brand.FlowDirection='LeftToRight'
$brand.Padding=New-Object Windows.Forms.Padding(0,14,14,0)
$signature=New-Label '© 2026 David De Prado (Seneca DPJ)' 'Signature'
$signature.Width=220;$signature.Height=28;$signature.ForeColor=$script:Palette.Gold
$signature.TextAlign='MiddleRight';$signature.Margin=New-Object Windows.Forms.Padding(0,0,6,0)
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
$brand.Controls.Add($script:GitHubButton);$header.Controls.Add($brand,1,0)
$intro=New-Label ('Control de alertas de Google Chrome'+$script:NL+'La opcion 3 incluye reparacion, referencias, vigilancia y apertura del panel.') 'Info'
$intro.ForeColor=$script:Palette.Info;$layout.Controls.Add($intro,0,1)
$pending=New-Label 'PENDIENTE: verificar la eficacia automatica de la tarea programada.' 'Banner'
$pending.ForeColor=$script:Palette.Banner;$layout.Controls.Add($pending,0,2)
$body=New-Object Windows.Forms.TableLayoutPanel
$body.Dock='Fill';$body.BackColor=[Drawing.Color]::Black;$body.ColumnCount=2;$body.RowCount=1
[void]$body.ColumnStyles.Add((New-Object Windows.Forms.ColumnStyle([Windows.Forms.SizeType]::Absolute,400)))
[void]$body.ColumnStyles.Add((New-Object Windows.Forms.ColumnStyle([Windows.Forms.SizeType]::Percent,100)))
$layout.Controls.Add($body,0,3)
$nav=New-Object Windows.Forms.TableLayoutPanel
$nav.Dock='Fill';$nav.ColumnCount=1;$nav.RowCount=8;$nav.BackColor=[Drawing.Color]::Black
[void]$nav.RowStyles.Add((New-Object Windows.Forms.RowStyle([Windows.Forms.SizeType]::Absolute,42)))
for($j=0;$j -lt 5;$j++){[void]$nav.RowStyles.Add((New-Object Windows.Forms.RowStyle([Windows.Forms.SizeType]::Percent,18)))}
[void]$nav.RowStyles.Add((New-Object Windows.Forms.RowStyle([Windows.Forms.SizeType]::Absolute,64)))
[void]$nav.RowStyles.Add((New-Object Windows.Forms.RowStyle([Windows.Forms.SizeType]::Percent,10)))
$body.Controls.Add($nav,0,0)
$navTitle=New-Label 'SELECCIONA UNA ACCION' 'General';$nav.Controls.Add($navTitle,0,0)
$script:Buttons=New-Object Collections.Generic.List[Windows.Forms.Button]
$actions=@(
 @('1','Diagnosticar servicios','Solo lectura','Diagnose'),
 @('2','Guardar referencias','Crear vigilancia y mostrar tarea','Prepare'),
 @('3','Ejecutar solucion','Proceso completo','Apply'),
 @('4','DESHACER','Restaurar y mostrar biblioteca','Undo'),
 @('5','Salir','Hasta la proxima','Exit')
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
 $button.Add_Click({param($sender,$eventArgs) Invoke-VisualAction ([string]$sender.Tag)})
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
$nav.Controls.Add($script:ShowManager,0,6)
$right=New-Object Windows.Forms.TableLayoutPanel
$right.Dock='Fill';$right.BackColor=[Drawing.Color]::Black;$right.ColumnCount=1;$right.RowCount=4
foreach($height in @(44,140,90)){[void]$right.RowStyles.Add((New-Object Windows.Forms.RowStyle([Windows.Forms.SizeType]::Absolute,$height)))}
[void]$right.RowStyles.Add((New-Object Windows.Forms.RowStyle([Windows.Forms.SizeType]::Percent,100)))
$body.Controls.Add($right,1,0)
$activityTitle=New-Label 'ACTIVIDAD' 'General';$right.Controls.Add($activityTitle,0,0)
$script:Figure=New-Label '[ LISTO ]' 'Exec'
$script:Figure.ForeColor=$script:Palette.Exec;$script:Figure.TextAlign='MiddleCenter'
$right.Controls.Add($script:Figure,0,1)
$script:Step=New-Label 'Listo. Puedes ejecutar 3 directamente.' 'Info'
$script:Step.ForeColor=$script:Palette.Info;$right.Controls.Add($script:Step,0,2)
$script:Log=New-Object Windows.Forms.RichTextBox
$script:Log.Dock='Fill';$script:Log.ReadOnly=$true;$script:Log.BorderStyle='None'
$script:Log.BackColor=[Drawing.Color]::Black;$script:Log.ForeColor=$script:Palette.Green
$script:Log.Font=$script:Fonts.General;$script:Log.DetectUrls=$false;$script:Log.WordWrap=$true;$script:Log.ScrollBars='Vertical'
$right.Controls.Add($script:Log,0,3)
$footer=New-Label 'Chrome conserva sus actualizaciones.  |  9.3 GUI OPERATIVO' 'General'
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
  $button.Enabled=$true;$button.TabStop=$Enabled
  if($Enabled){$button.Cursor=[Windows.Forms.Cursors]::Hand}else{$button.Cursor=[Windows.Forms.Cursors]::WaitCursor}
 }
 $script:ShowManager.Enabled=$Enabled
}
function Invoke-VisualAction {
 param([string]$Selected)
 if($script:Exiting -or $null -ne $script:Engine){return}
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
  $script:CurrentAction=$Selected;$script:ShowManager.Visible=($Selected -eq 'Diagnose')
  $script:Log.Clear();$script:Step.Font=$script:Fonts.Exec;$script:Step.ForeColor=$script:Palette.Exec
  if($Selected -in @('Apply','Undo')){
   $script:Figure.Font=$script:Fonts.Exec;$script:Figure.ForeColor=$script:Palette.Exec
  }else{
   $script:Step.Font=$script:Fonts.Info;$script:Step.ForeColor=$script:Palette.Info
   $script:Figure.Font=$script:Fonts.General;$script:Figure.ForeColor=$script:Palette.Green
  }
  $script:Step.Text='Preparando la operacion...';Add-VisualLine ('Accion: '+$Selected) 'General'
  $exe=Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
  $sid=[Security.Principal.WindowsIdentity]::GetCurrent().User.Value
  $arguments='-NoProfile -NonInteractive -WindowStyle Hidden -File "'+$script:Core+'" -Action '+$Selected+' -ExpectedSid "'+$sid+'" -UiSession '+$script:EngineId
  $psi=New-Object Diagnostics.ProcessStartInfo
  $psi.FileName=$exe;$psi.Arguments=$arguments;$psi.WindowStyle='Hidden'
  $principal=New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
  $needElevation=$Selected -in @('Prepare','Apply','Undo') -and -not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
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
  if($entry.Text -match '^\[(\d)/3\]\s*(.+)$'){
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
 if($script:CurrentAction -in @('Apply','Undo')){
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
 $map=@{'D1'='Diagnose';'D2'='Prepare';'D3'='Apply';'D4'='Undo';'D5'='Exit';'NumPad1'='Diagnose';'NumPad2'='Prepare';'NumPad3'='Apply';'NumPad4'='Undo';'NumPad5'='Exit'}
 if($map.ContainsKey($eventArgs.KeyCode.ToString())){Invoke-VisualAction $map[$eventArgs.KeyCode.ToString()];$eventArgs.Handled=$true}
})
Add-VisualLine 'Listo. Elige una accion o pulsa su numero.' 'General'
Add-VisualLine 'La opcion 3 realiza el proceso completo. No requiere ejecutar antes 1 ni 2.' 'Info'
if($PreviewPath){
 if($PreviewMode -in @('Apply','Undo')){
  $script:Step.Font=$script:Fonts.Exec;$script:Step.ForeColor=$script:Palette.Exec
  $script:Figure.Text='( ◷ )  /'
  $script:Step.Text='Guardar referencias y programar vigilancia...'
  if($PreviewMode -eq 'Undo'){$script:Figure.Text='[ − ]  /';$script:Step.Text='Retirar la tarea propia de vigilancia...'}
  $script:Log.Clear()
  Add-VisualLine '[1/3] Filtros de Google Update procesados.' 'Exec'
  Add-VisualLine '[2/3] Operacion en curso...' 'Exec'
 }elseif($PreviewMode -eq 'Exit'){
  Invoke-VisualAction 'Exit';$script:Figure.Text='\o/'
 }
 $script:ShowManager.Visible=($PreviewMode -eq 'Menu')
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
foreach($font in $script:Fonts.Values){$font.Dispose()}





