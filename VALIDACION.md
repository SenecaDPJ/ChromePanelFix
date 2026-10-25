# Validación de 9.1

Cambio acotado al lanzador, textos de diagnóstico de inicio y documentación:

- El CMD no contiene BOM y usa CRLF para su reconocimiento por cmd.exe.
- El proceso PowerShell sigue respetando la política configurada. Los fallos de carga del script se capturan y muestran en un aviso.
- No se cambió el motor de reparación ni los datos incluidos del paquete 9.0.

Pendiente de prueba en el Windows Server de destino: inicio desde ZIP descargado y ejecución programada. La compatibilidad con Server 2016 no está verificada.