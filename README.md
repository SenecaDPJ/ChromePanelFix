# Eliminar Google Update

Script PowerShell para eliminar componentes de actualización automática de Google en Windows. Preparado para su revisión en el contexto de Windows Server 2016/2019; pendiente de validación funcional en esos sistemas.

## Alcance

- Detecta, detiene y elimina los servicios `gupdate`, `gupdatem`, `GoogleUpdaterInternalService*` y `GoogleUpdaterService*`.
- Elimina las tareas programadas cuyos nombres coinciden con `GoogleUpdateTaskMachine*` o `GoogleUpdaterTask*`.
- Por defecto, elimina las carpetas de Google Update y GoogleUpdater contempladas por el script en Program Files, Program Files (x86) y ProgramData.
- No incluye acciones para desinstalar Google Chrome ni borrar sus perfiles.

## Requisitos

- Windows y Windows PowerShell 5.1 o posterior.
- Privilegios de administrador para aplicar los cambios.
- Un mecanismo alternativo para mantener actualizadas las aplicaciones de Google.

> Eliminar Google Update desactiva las actualizaciones automáticas que dependen de esos componentes, incluidas las correcciones de seguridad.

## Revisar sin aplicar cambios

Desde la carpeta donde se encuentra el script:

```powershell
.\Eliminar-GoogleUpdate.ps1 -WhatIf
```

El modo de simulación muestra las acciones propuestas; no sustituye una prueba funcional en un equipo de ensayo.

## Ejecutar

Abra PowerShell como administrador y ejecute:

```powershell
.\Eliminar-GoogleUpdate.ps1
```

El script solicita confirmación para las acciones. Para conservar las carpetas del actualizador mientras elimina los servicios y las tareas:

```powershell
.\Eliminar-GoogleUpdate.ps1 -KeepFiles
```

Para omitir las confirmaciones individuales:

```powershell
.\Eliminar-GoogleUpdate.ps1 -Confirm:$false
```

## Estado de validación

Esta copia conserva el script recuperado de la PR #2. No se ha ejecutado sobre servicios, tareas ni carpetas del equipo, ni se ha validado funcionalmente en Windows Server 2016/2019. Eliminar los componentes no garantiza por sí solo resolver la causa de los errores originales.
