# ChromePanelFix 9.1 — GUI OPERATIVO

Corrección de distribución para Windows:

- El lanzador CMD se guarda en ASCII/CRLF, sin BOM UTF-8.
- Los errores de inicio de PowerShell se muestran en un aviso legible.
- Se explica cómo quitar Mark of the Web del ZIP desde Propiedades cuando Windows lo bloquea.
- Se mantiene la política de ejecución de la organización; el lanzador no usa -ExecutionPolicy Bypass.
- No cambia el motor de reparación ni la funcionalidad de 9.0.

Pendiente de validación: eficacia automática de la tarea y compatibilidad con Windows Server 2016.