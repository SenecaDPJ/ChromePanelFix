# Validación y estado de 9.5

## ChromePanelFix 9.5 — revisión de submenús y reversión

La implementación añade la solución manual como acción distinta de `Prepare` y `Apply`. La ruta manual reutiliza la escritura segura y el registro reversible de `Invoke-DirectSolution`; no llama a `Prepare-Watch`, no registra una tarea y no cambia una tarea existente. Se comprueba la tarea propia antes de actuar y se rechaza la ejecución si está activa. El usuario confirmó que la opción 2 funciona en su Windows Server.

El usuario confirmó también que la funcionalidad y los nuevos submenús son correctos. En esta revisión se restauran en la interfaz los rótulos originales de las opciones 3, 4 y 5; únicamente se añadió la solución manual en la opción 2. Las vistas previas se actualizaron para reflejar los nombres restaurados.

Comprobaciones locales realizadas el 30-10-2026:

- El analizador de Windows PowerShell 5.1 acepta todos los archivos `.ps1` del paquete.
- La revisión de flujo confirma que la solución manual reutiliza `Invoke-DirectSolution` y no llama a `Prepare-Watch`, `Register-ScheduledTask`, `Unregister-ScheduledTask` ni `Open-WatchTaskScheduler`.
- Se verifican estáticamente los menús de las opciones 2–5, las rutas de apertura de ambos paneles en DESHACER, la elevación de privilegios y los atajos hasta la opción 6.
- El tamaño inicial se calcula con el área útil de pantalla y la tabla vertical de acciones se mantiene dentro del panel.
- Las vistas previas SVG ilustran la interfaz ajustada y los submenús 2–5; son composiciones de diseño, no capturas de una ejecución real.
- El ZIP contiene la misma distribución que la carpeta; el manifiesto incluye 23 archivos y el sidecar coincide con la huella SHA-256 del ZIP.

No se ejecutó el motor de cambios en este equipo: la política de ejecución local bloquea los archivos `.ps1`. La funcionalidad de DESHACER, los nuevos submenús y el ajuste visual ya fueron confirmados por el usuario en Windows Server. Siguen pendientes la eficacia de las ejecuciones automáticas y la compatibilidad con Windows Server 2016.

## ChromePanelFix 9.4

La persona usuaria verificó que el icono de ChromePanelFix aparece correctamente en la ventana de la aplicación. También confirmó el funcionamiento de la edición presentada antes de esta integración del icono.

La eficacia de las ejecuciones automáticas de la tarea sigue pendiente de verificación. La compatibilidad con Windows Server 2016 no se ha comprobado.

## Base 9.3

La persona mantenedora confirmó que la distribución de cabecera evita que el título quede tapado. La vista previa muestra el título, la firma, el botón GitHub y el menú actualizado. El botón solicita confirmación antes de abrir el perfil.

El lanzador conserva la comprobación condicional de Zone.Identifier y no cambia ni elude la política de ejecución de PowerShell.

## Base 9.2: validación anterior

La persona mantenedora verificó en el Windows Server de destino que la corrección de confianza permite iniciar ChromePanelFix desde el paquete descargado: el lanzador solicita consentimiento para quitar Zone.Identifier y continúa al aceptarlo. La opción 3 había sido verificada como flujo completo de reparación y preparación de vigilancia; el panel de Biblioteca del Programador se muestra en las opciones 2, 3 y 4.

Pendiente de verificación en el servidor: eficacia real de las ejecuciones automáticas de la tarea. La compatibilidad con Windows Server 2016 no se ha comprobado. La validación sintáctica y de empaquetado no sustituye las pruebas en esos entornos.
