# Changelog

## [1.1.0] - 2026-11-19
### Añadido
- Lista de cuentas de usuario activas (local / cuenta Microsoft) con selección por número o por nombre.
- Mensaje de confirmación «Clave guardada» al terminar correctamente.

### Corregido
- La función que pide la contraseña se llamaba `rd`, que en PowerShell es un alias de `Remove-Item`; no se pedía la contraseña.
- El script ya no continúa si hay un error al leer la contraseña, y rechaza contraseñas vacías.

## [1.0.0] - 2026-11-17
- Versión inicial: menú para activar, desactivar o salir; elevación automática a administrador; soporte para cuentas Microsoft; desactivación de «solo Windows Hello»; opción de contraseña al salir de suspensión.
