# Validación y estado de 9.3

## 9.3

La persona mantenedora confirmó que la distribución de cabecera evita que el título quede tapado. La imagen Vista-previa.png se sustituyó por la captura del menú 9.3 proporcionada por la persona mantenedora; muestra el título, la firma, el botón GitHub y el menú actualizado. El botón solicita confirmación antes de abrir el perfil. El botón solicita confirmación antes de abrir el perfil.

El lanzador conserva la comprobación condicional de Zone.Identifier: si los .ps1 extraídos tienen esa marca, pregunta si se confía en ellos y, con respuesta S, la retira solo de esos archivos; con N, sale sin modificarlos. Si no detecta la marca, no pregunta. No cambia ni elude la política de ejecución de PowerShell.

La eficacia de las ejecuciones automáticas de la tarea sigue pendiente de verificación. La compatibilidad con Windows Server 2016 no se ha comprobado.

## Base 9.2: validación anterior

La persona mantenedora verificó en el Windows Server de destino que la corrección de confianza permite iniciar ChromePanelFix desde el paquete descargado: el lanzador solicita consentimiento para quitar Zone.Identifier y continúa al aceptarlo. La opción 3 había sido verificada como flujo completo de reparación y preparación de vigilancia; el panel de Biblioteca del Programador se muestra en las opciones 2, 3 y 4.

Comprobaciones de distribución realizadas para la edición 9.2:

- Los archivos PowerShell pasan el analizador de Windows PowerShell 5.1.
- La operación Unblock-File se comprobó con una marca Zone.Identifier de prueba.
- El lanzador CMD se mantiene ASCII/CRLF, sin BOM.
- El SHA-256 del ZIP se contrasta con el sidecar y se verifica que los archivos comprimidos coinciden con la carpeta de entrega.

Pendiente de verificación en el servidor: eficacia real de las ejecuciones automáticas de la tarea. La compatibilidad con Windows Server 2016 no se ha comprobado. La validación sintáctica y de empaquetado no sustituye las pruebas en esos entornos.