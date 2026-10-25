#requires -Version 5.1
# Prueba exclusivamente la apertura: no ejecuta ninguna opcion del motor.
$ErrorActionPreference='Stop'
try{
 $tokens=$null;$errors=$null
 $path=Join-Path $PSScriptRoot 'ChromePanelFix.Core.ps1'
 $ast=[Management.Automation.Language.Parser]::ParseFile($path,[ref]$tokens,[ref]$errors)
 if($errors.Count){throw 'El motor contiene errores de sintaxis.'}
 foreach($name in @('Find-SchedulerLibrary','Open-WatchTaskScheduler')){
  $function=$ast.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq $name},$false)
  if($function.Count -ne 1){throw ('Falta la funcion: '+$name)}
  Invoke-Expression $function[0].Extent.Text
 }
 Open-WatchTaskScheduler
}catch{Write-Host $_.Exception.Message -ForegroundColor Red}
[void](Read-Host 'Pulsa Entrar para cerrar esta prueba')
