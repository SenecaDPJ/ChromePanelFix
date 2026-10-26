# Validación y estado de 9.3 (previa local)

## 9.3

El cambio de interfaz y la firma están implementados en esta copia local. No se ha ejecutado en el servidor ni se ha probado el botón de GitHub. La generación de una captura real quedó bloqueada por la política de ejecución de Windows PowerShell en este entorno; no se modificó ni se eludió esa política. La eficacia de la tarea automática y la compatibilidad con Windows Server 2016 siguen pendientes.

## Base 9.2: validación anterior

La persona mantenedora verificó en el Windows Server de destino que la corrección de confianza permite iniciar ChromePanelFix desde el paquete descargado: el lanzador solicita consentimiento para quitar Zone.Identifier y continúa al aceptarlo. La opción 3 había sido verificada como flujo completo de reparación y preparación de vigilancia; el panel de Biblioteca del Programador se muestra en las opciones 2, 3 y 4.

Comprobaciones de distribución realizadas para la edición 9.2:

- Los archivos PowerShell pasan el analizador de Windows PowerShell 5.1.
- La operación Unblock-File se comprobó con una marca Zone.Identifier de prueba.
- El lanzador CMD se mantiene ASCII/CRLF, sin BOM.
- El SHA-256 del ZIP se contrasta con el sidecar y se verifica que los archivos comprimidos coinciden con la carpeta de entrega.

Pendiente de verificación en el servidor: eficacia real de las ejecuciones automáticas de la tarea. La compatibilidad con Windows Server 2016 no se ha comprobado. La validación sintáctica y de empaquetado no sustituye las pruebas en esos entornos.