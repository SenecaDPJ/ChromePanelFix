# ChromePanelFix 9.1 — GUI OPERATIVO

[Español](README.md) · [English](README.en.md)

**Limpia las alertas de servicios detenidos de Google Update en el Administrador del Servidor y conserva los componentes de actualización de Chrome.**

Utilidad gráfica en PowerShell para administradores de Windows Server. Ajusta los filtros de servicios de los paneles «Servidor local» y «Todos los servidores» en el perfil del administrador actual.

## Corrección 9.1

La versión 9.0 incluía un lanzador CMD codificado con BOM UTF‑8, que impedía que cmd.exe interpretara correctamente su primera línea. Además, ocultaba errores de inicio de PowerShell. Esta versión corrige el lanzador y muestra un aviso legible si Windows bloquea el script.

## Descargar

[Descargar ChromePanelFix 9.1](https://github.com/SenecaDPJ/ChromePanelFix/releases/tag/v9.1) · [Repositorio](https://github.com/SenecaDPJ/ChromePanelFix)

![Vista de ChromePanelFix](Vista-previa.png)

## Inicio rápido

1. Descargue el ZIP de la Release 9.1 y extraiga todos sus archivos juntos.
2. Si Windows muestra la opción **Desbloquear**: antes de extraer, haga clic derecho en el ZIP, abra **Propiedades**, marque **Desbloquear** y pulse **Aplicar**. Hágalo solo si confía en que el archivo procede de la Release oficial enlazada arriba.
3. Abra **Abrir-ChromePanelFix.cmd** con doble clic.
4. Elija **3** para ejecutar el flujo completo. No necesita ejecutar antes 1 ni 2.

La política de ejecución de PowerShell de la organización sigue aplicándose. El lanzador no la omite; si esa política bloquea el script, mostrará el error y deberá consultarse al administrador.

## Funciones

| Opción | Acción |
|---|---|
| 1 | Diagnóstico de servicios y filtros, solo lectura; permite abrir Administrador del Servidor. |
| 2 | Guardar referencias, crear y comprobar la tarea propia; abrir Biblioteca del Programador. |
| 3 | Aplicar exclusiones, guardar referencias, instalar y comprobar vigilancia; abrir Administrador del Servidor y Biblioteca del Programador. |
| 4 | Revertir exclusiones propias, retirar la tarea y referencias; comprobar y abrir Biblioteca del Programador. |
| 5 | Salir. |

La herramienta ajusta filtros del panel. No elimina ni deshabilita los servicios, tareas o archivos de Google, no borra eventos y no certifica que Chrome se haya actualizado. Los fallos reales de actualización deben diagnosticarse por separado.

## Requisitos y límites

- Windows PowerShell 5.1, .NET Framework, Windows Forms, Administrador del Servidor y Programador de tareas.
- Ejecutar con la cuenta administradora cuyo panel se quiere ajustar. La configuración es por perfil; se solicita elevación para las operaciones que la necesitan.
- Configuración comprobada con datos de Windows Server 2019 (build 17763). La compatibilidad con Server 2016 sigue pendiente de prueba.
- La tarea se programa a diario a las 09:00 y al iniciar sesión. La eficacia de sus ejecuciones automáticas aún está pendiente de validar.
- Al cerrar el Programador de tareas puede aparecer la pregunta para guardar taskschd.msc; responder **No**.

## Licencia y versiones

Mantenido por **SenecaDPJ** bajo licencia **MIT**. Proyecto independiente, sin afiliación con Google ni Microsoft.

La Release 9.1 corrige el lanzador y el diagnóstico de inicio. No cambia el motor de reparación. La versión 9.0 sigue disponible en el historial de Releases.