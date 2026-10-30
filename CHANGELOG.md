# Historial

## 9.5 — Solución manual y submenús de paneles
- Añade en la opción 2 la reparación manual sin crear ni actualizar tareas programadas.
- Ofrece en un submenú abrir Administrador del Servidor al finalizar o mantenerlo cerrado.
- Añade submenús a las opciones 3, 4 y 5 para escoger qué paneles abrir.
- DESHACER abre Administrador del Servidor y Programador de tareas por defecto, incluso si la reversión informa de un error; taskschd.msc sirve de alternativa si MMC no confirma la Biblioteca.
- Ajusta tamaño y mínimo de ventana al área disponible, compacta la tipografía y corrige la distribución vertical para que las acciones no queden apretadas.
- Conserva la vigilancia separada en 3, el proceso completo con vigilancia en 4 y DESHACER en 5.
- Mantiene las tareas existentes y bloquea la opción manual si la vigilancia propia está en ejecución.
- Mantiene la reversión de exclusiones propias y actualiza atajos, textos y vista previa.
- Conserva los rótulos originales de las opciones existentes; solo añade la nueva solución manual como opción 2.
- La eficacia automática de la tarea y la compatibilidad con Windows Server 2016 siguen pendientes de verificación.

## 9.4 — Icono de ventana
- Incorpora el icono multirresolución de ChromePanelFix en la ventana.
- Incluye los recursos del icono necesarios para ejecutar y documentar la aplicación.
- Conserva el flujo funcional y las opciones verificadas de 9.3.
- La eficacia automática de la tarea y la compatibilidad con Windows Server 2016 siguen pendientes de verificación.

## 9.3
- Sustituye la vista previa por la captura del menú 9.3 proporcionada por la persona mantenedora.
- Añade la firma Copyright © 2026 David De Prado (Seneca DPJ) en la cabecera y LICENSE.
- Añade un botón GitHub amarillo sobre negro con confirmación previa antes de abrir el perfil del autor.
- Aísla el título en un panel izquierdo de ancho propio para evitar recortes; el bloque de firma y GitHub se acopla a la derecha.

## 9.2
- El lanzador pregunta si se confía en los scripts extraídos con Zone.Identifier y, solo con respuesta afirmativa, lo retira de los .ps1 marcados de la carpeta.
- No modifica ni elude la política de ejecución de PowerShell.
- Integra la liberación de referencias MMC y la utilidad de cierre controlado de procesos identificados por PID.
- Conserva el motor de reparación y los límites de uso de la 9.1.

## 9.1
Corrige la codificación BOM del lanzador CMD y hace visibles los errores de inicio de PowerShell.

## 9.0
Primera edición de ChromePanelFix publicada en GitHub, basada en la versión operativa local 8.0.
