# Validación y estado de 9.5

## ChromePanelFix 9.5 — preparación local

La implementación añade la solución manual como acción distinta de `Prepare` y `Apply`. La ruta manual reutiliza la escritura segura y el registro reversible de `Invoke-DirectSolution`; no llama a `Prepare-Watch`, no registra una tarea y no cambia una tarea existente. Se comprueba la tarea propia antes de actuar y se rechaza la ejecución si está activa.

Comprobaciones locales realizadas el 30-10-2026:

- El analizador de Windows PowerShell 5.1 acepta todos los archivos `.ps1` del paquete.
- La revisión de flujo confirma que la solución manual reutiliza `Invoke-DirectSolution` y no llama a `Prepare-Watch`, `Register-ScheduledTask`, `Unregister-ScheduledTask` ni `Open-WatchTaskScheduler`.
- Se verificaron estáticamente las dos opciones del submenú, el paso de `-SkipManager` y los atajos hasta la opción 6.
- Las vistas previas ilustran el menú y el submenú; son composiciones de diseño, no capturas de una ejecución real.
- El ZIP contiene la misma distribución que la carpeta; el manifiesto incluye 21 archivos y el sidecar coincide con la huella SHA-256 del ZIP.

No se ejecutó el motor de cambios: la política de ejecución local bloquea los archivos `.ps1`. La prueba funcional de aplicación y DESHACER sigue pendiente en Windows Server. También siguen pendientes la eficacia de las ejecuciones automáticas y la compatibilidad con Windows Server 2016.

## ChromePanelFix 9.4

La persona usuaria verificó que el icono de ChromePanelFix aparece correctamente en la ventana de la aplicación. También confirmó el funcionamiento de la edición presentada antes de esta integración del icono.

La eficacia de las ejecuciones automáticas de la tarea sigue pendiente de verificación. La compatibilidad con Windows Server 2016 no se ha comprobado.

## Base 9.3

La persona mantenedora confirmó que la distribución de cabecera evita que el título quede tapado. La vista previa muestra el título, la firma, el botón GitHub y el menú actualizado. El botón solicita confirmación antes de abrir el perfil.

El lanzador conserva la comprobación condicional de Zone.Identifier y no cambia ni elude la política de ejecución de PowerShell.

## Base 9.2: validación anterior

La persona mantenedora verificó en el Windows Server de destino que la corrección de confianza permite iniciar ChromePanelFix desde el paquete descargado: el lanzador solicita consentimiento para quitar Zone.Identifier y continúa al aceptarlo. La opción 3 había sido verificada como flujo completo de reparación y preparación de vigilancia; el panel de Biblioteca del Programador se muestra en las opciones 2, 3 y 4.

Pendiente de verificación en el servidor: eficacia real de las ejecuciones automáticas de la tarea. La compatibilidad con Windows Server 2016 no se ha comprobado. La validación sintáctica y de empaquetado no sustituye las pruebas en esos entornos.
