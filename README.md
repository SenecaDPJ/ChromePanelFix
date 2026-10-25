# ChromePanelFix 9.0 — GUI OPERATIVO

[Español](README.md) · [English](README.en.md)

**Gestiona las alertas de Google Update en Administrador del Servidor sin desactivar las actualizaciones de Chrome.**

Utilidad con interfaz gráfica en PowerShell para administradores de Windows Server. Ajusta las exclusiones del recuento de servicios de Google Update en los paneles «Servidor local» y «Todos los servidores». Incluye diagnóstico, aplicación directa, vigilancia programada y reversión de sus propios ajustes.

**Edición 9.0 para GitHub**, clon funcional de la 8.0 validada por el usuario. La 8.0 permanece congelada localmente.

## El problema que resuelve

Google Update puede aparecer como servicio automático detenido y generar avisos en «Servidor local» y «Todos los servidores». ChromePanelFix ajusta esos filtros de forma autónoma para que esos servicios dejen de contarse como alertas, conservando los componentes de actualización de Chrome.

## Descargar

[Descargar ChromePanelFix 9.0 — GUI OPERATIVO](https://github.com/SenecaDPJ/ChromePanelFix/raw/refs/heads/main/downloads/ChromePanelFix_9.0_GUI-OPERATIVO.zip) · [SHA-256 del ZIP](https://github.com/SenecaDPJ/ChromePanelFix/blob/main/downloads/ChromePanelFix_9.0_GUI-OPERATIVO.zip.sha256)

![Interfaz de ChromePanelFix 9.0](Vista-previa.png)
## Qué hace

Actúa sobre el filtro de servicios del perfil del administrador. Un servicio detenido no demuestra por sí solo un fallo de Chrome. La herramienta no repara errores de actualización, no elimina eventos y no comprueba que Chrome haya actualizado correctamente.

No elimina ni deshabilita servicios, tareas o archivos de Google. La tarea propia vuelve a comprobar y aplicar las exclusiones, también cuando cambian los nombres de los servicios por una actualización.

## Requisitos y compatibilidad

- Windows PowerShell 5.1, .NET Framework y Windows Forms; usar Windows PowerShell, no PowerShell 7.
- Administrador del Servidor y Programador de tareas instalados; escritorio interactivo.
- Usar la cuenta cuyo panel se desea ajustar; las preferencias son por perfil.
- Las operaciones que lo necesitan solicitan privilegios de administrador de esa misma cuenta.
- Esquema de configuración validado con diagnóstico de Windows Server 2019 (17763).
- Windows Server 2016: compatibilidad pendiente de prueba. Se rechazan esquemas desconocidos.
- La política de ejecución de la organización debe permitir los scripts. No se modifica ni elude.

## Inicio rápido

1. Extraer todos los archivos del ZIP en una carpeta local.
2. Abrir **Abrir-ChromePanelFix.cmd** con doble clic. También se puede usar «Ejecutar con PowerShell» sobre **ChromePanelFix_9.0_GUI-OPERATIVO.ps1**.
3. Elegir **3** para aplicar el flujo completo. No necesita ejecutar antes 1 ni 2.
4. Comprobar los paneles «Servidor local» y «Todos los servidores» y verificar manualmente las actualizaciones de Chrome desde su página de información.

El doble clic en un archivo .ps1 puede abrir un editor; para ese modo de arranque use el .cmd. Mantenga juntos interfaz y motor.

## Menú

| Opción | Acción |
|---|---|
| 1 | Diagnóstico de servicios y filtros, solo lectura. Botón A para abrir Administrador del Servidor. |
| 2 | Guardar referencias, crear o actualizar la tarea propia y comprobar la instalación; abrir Biblioteca del Programador. |
| 3 | Aplicar exclusiones, guardar referencias, instalar y comprobar vigilancia; abrir Administrador del Servidor y Biblioteca del Programador. |
| 4 | Retirar exclusiones añadidas por la herramienta, eliminar tarea y referencias propias; comprobar la retirada y abrir Biblioteca del Programador. |
| 5 | Salir. |

La aplicación puede cerrar ordenadamente Administrador del Servidor antes de cambiar su configuración para evitar que sobrescriba el ajuste. Si otra instancia impide la operación, informa del problema.

## Vigilancia

La tarea **GoogleUpdateAlertMonitor-<SID>** se programa diariamente a las **09:00** y al iniciar sesión. Se ejecuta con la cuenta instaladora y requiere que esa cuenta tenga sesión iniciada; admite sesión bloqueada. Usa privilegios elevados y no abre ventanas de administración.

La instalación y configuración se comprueban, pero **la eficacia de las ejecuciones automáticas sigue pendiente de validación**. Crear la tarea no demuestra que haya ejecutado correctamente en un inicio de sesión o a las 09:00.

## Datos y reversión

Datos locales: `%LOCALAPPDATA%\GoogleUpdateAlertMonitor`.

- `baseline.json`: inventario de referencia.
- `direct-state.json`: adiciones propias para la reversión selectiva.
- `latest.json`: resultado de la última vigilancia.
- `user.config.recovery`: copia de recuperación.
- `Gestionar-AlertasGoogleUpdate.ps1`: copia del motor utilizada por la tarea.
- `ui-*.jsonl`: registros de la interfaz.

La opción 4 conserva ajustes ajenos. Elimina los cuatro archivos de referencia indicados y la tarea propia; los registros de interfaz y la copia del motor pueden permanecer. No es una desinstalación de Google Chrome.

No se transmiten datos ni hay telemetría. Los registros pueden contener nombres de equipos, cuentas, servicios y rutas; revíselos antes de compartirlos.

## Estado comprobado y límites conocidos

- Usuario: reparación y flujo completo de 3 comprobados; 2, 3 y 4 abren correctamente Biblioteca del Programador.
- Pruebas locales: análisis sintáctico, flujo simulado y reparación/reversión sobre copia del diagnóstico.
- Tarea automática y Windows Server 2016: pendientes de verificación.
- **Al cerrar Programador de tareas puede preguntar si desea guardar la consola en taskschd.msc. Seleccione «No».** El aviso afecta a la vista de MMC, no cancela las operaciones ya realizadas. Se conserva este comportamiento conocido para no alterar la entrega validada.
- `Probar-Biblioteca.ps1` permite probar solo la apertura de la Biblioteca, sin reparar filtros ni crear o borrar tareas.

## Archivos y documentación

Interfaz: `ChromePanelFix_9.0_GUI-OPERATIVO.ps1`. Motor: `ChromePanelFix.Core.ps1`. Lanzador: `Abrir-ChromePanelFix.cmd`.

[Notas de versión](RELEASE_NOTES.md) · [Historial](CHANGELOG.md) · [Congelación](VERSIONES.md) · [Preparación de publicación](PUBLICACION.md) · [Contribuciones](CONTRIBUTING.md) · [Seguridad](SECURITY.md).

`SHA256SUMS.txt` corresponde al contenido del paquete 9.0 original: compruébelo dentro del ZIP extraído. La documentación de la rama principal puede evolucionar sin modificar ese paquete. La huella del ZIP se distribuye en un archivo independiente.

## Autoría y licencia

Mantenedor: **SenecaDPJ**. Licencia **MIT**, incluida íntegramente en [LICENSE](LICENSE); identificador SPDX: MIT.

Proyecto independiente, sin afiliación con Google ni Microsoft. Chrome, Google Update y Windows son marcas de sus respectivos titulares.

