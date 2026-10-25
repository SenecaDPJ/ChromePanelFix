# Validación de 9.0

La 9.0 es un clon de la entrega 8.0_GUI-OPERATIVO validada de nuevo por el usuario.

- Motor comparado exactamente contra 8.0: solo cambian los textos de versión en la cabecera y el menú de consola.
- Scripts analizados sintácticamente con Windows PowerShell 5.1.
- Interfaz 9.0 renderizada para actualizar la captura.
- Código fuente sin datos de diagnóstico, registros privados ni referencias a un servidor concreto.
- El empaquetado incluye manifiesto SHA-256 y huella independiente del ZIP.

La validación funcional del usuario corresponde a la base 8.0. No se ha aplicado una reparación nueva a un servidor durante la publicación.
Las pruebas sobre copia del diagnóstico y flujos simulados se ejecutaron durante el desarrollo de la base.
La eficacia de la vigilancia automática y la compatibilidad con Server 2016 no están verificadas. Se conserva el aviso de guardar la consola al cerrar MMC.
