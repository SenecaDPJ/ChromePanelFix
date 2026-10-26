# ChromePanelFix 9.3 — previa local de interfaz

Se añade la firma © 2026 David De Prado (Seneca DPJ) y un botón GitHub con confirmación antes de abrir el perfil del autor. El resto del comportamiento se basa en la 9.2. Esta previa aún no se ha publicado ni validado en el servidor. La eficacia de las ejecuciones automáticas y la compatibilidad con Windows Server 2016 siguen pendientes.

﻿# ChromePanelFix 9.2 — GUI OPERATIVO

## Español

La 9.2 integra la corrección de descarga probada: si Windows marca scripts extraídos con Zone.Identifier, Abrir-ChromePanelFix.cmd pregunta si el usuario confía en ellos. Con S, retira la marca solo de los .ps1 afectados en la carpeta y continúa; con N, sale sin modificarlos. No cambia ni omite la política de ejecución.

También incluye la liberación ordenada de referencias MMC y una herramienta de recuperación que lista procesos de ChromePanelFix y exige seleccionar sus PID antes de cerrarlos.

Se conserva el comportamiento funcional de la 9.1. La eficacia de la tarea automática y la compatibilidad con Windows Server 2016 siguen pendientes de validar.

## English

Version 9.2 includes the tested download fix: if Windows marks extracted scripts with Zone.Identifier, Abrir-ChromePanelFix.cmd asks whether the user trusts them. Pressing S removes the mark only from affected .ps1 files in the folder and continues; N exits without changing them. It does not change or bypass execution policy.

It also includes orderly MMC reference cleanup and a recovery utility that lists ChromePanelFix processes and requires selecting their PIDs before stopping them.

The 9.1 functional behavior is preserved. Scheduled-task effectiveness and Windows Server 2016 compatibility remain unverified.