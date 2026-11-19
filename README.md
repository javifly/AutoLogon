# AutoLogon para Windows 11

Script `.bat` con menú para **activar o desactivar el inicio de sesión automático** en Windows 11. Al arrancar, el equipo entra directamente en el escritorio del usuario elegido, sin tener que escribir la contraseña.

Probado en **Windows 11 26H2**.

```
==================================================
   INICIO DE SESIÓN AUTOMÁTICO - WINDOWS 11
==================================================
   Estado actual : DESACTIVADO

   1. Activar inicio de sesión automático
   2. Desactivar (volver a pedir contraseña)
   3. Salir sin hacer nada
```

## Características

- Menú con tres opciones: activar, desactivar o salir sin hacer nada.
- Muestra si el inicio automático está activado y para qué usuario.
- Lista las cuentas activas del equipo, indicando si son locales o cuentas Microsoft. Puedes elegir una por número o por nombre.
- Funciona con **cuentas locales** y con **cuentas Microsoft**.
- Pide la contraseña dos veces y no la muestra en pantalla mientras escribes.
- Desactiva automáticamente la opción *«Solo permitir el inicio de sesión con Windows Hello para cuentas Microsoft»*, que impide el inicio automático. Guarda el valor original para restaurarlo después.
- Opcionalmente, deja de pedir la contraseña al volver de suspensión.
- La opción 2 deshace todos los cambios y borra la contraseña guardada.
- Pide permisos de administrador por sí mismo.

## Uso

1. Descarga [`AutoLogon.bat`](AutoLogon.bat), o el archivo de la última versión en *Releases*.
2. Haz doble clic sobre él y acepta el aviso de permisos de administrador (UAC).
3. Elige una opción:
   - **1 – Activar**: elige el usuario. Si es una cuenta Microsoft, escribe su correo. Después escribe la contraseña.
   - **2 – Desactivar**: el equipo vuelve a pedir la contraseña al iniciar.
   - **3 – Salir**: cierra el script sin hacer cambios.
4. Reinicia el equipo para comprobar el resultado. El propio script te ofrece hacerlo.

> **Importante:** introduce la **contraseña de la cuenta**, no el PIN de Windows Hello. En las cuentas Microsoft, el usuario es el **correo completo** de la cuenta.

## Qué cambia en el sistema

| Clave / ajuste | Activar | Desactivar |
|---|---|---|
| `HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon` → `AutoAdminLogon` | `1` | `0` |
| … → `DefaultUserName` / `DefaultDomainName` | usuario y equipo (o `MicrosoftAccount`) | se mantienen |
| … → `DefaultPassword` | contraseña | **se borra** |
| `HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\PasswordLess\Device` → `DevicePasswordLessBuildVersion` | `0` | valor original |
| `powercfg` → `CONSOLELOCK` (contraseña al salir de suspensión) | `0` (opcional) | `1` |
| `HKLM\SOFTWARE\AutoLogonScript` (copia del valor original) | se crea | se borra |

## ⚠️ Seguridad

- La contraseña se guarda **en texto plano** en el registro (`DefaultPassword`). Cualquier usuario con permisos de administrador del equipo puede leerla. Si necesitas que se guarde cifrada, usa [Autologon de Sysinternals](https://learn.microsoft.com/sysinternals/downloads/autologon).
- Cualquiera que encienda el equipo tendrá acceso a la sesión. No se recomienda en portátiles ni en equipos compartidos.

## Problemas conocidos

- **Cambio de contraseña:** si cambias la contraseña de la cuenta, el inicio automático deja de funcionar sin avisar. Vuelve a ejecutar la opción 1.
- **Otro usuario inicia sesión:** si otra cuenta inicia sesión en el equipo, Windows cambia el usuario por defecto y el inicio automático puede fallar. Vuelve a ejecutar la opción 1.
- **Equipos en dominio o gestionados (Intune/GPO):** no están soportados. Las directivas del dominio o de la organización pueden anular estos ajustes.
- **SmartScreen:** al ser un archivo descargado de Internet, Windows puede mostrar un aviso. Pulsa *Más información → Ejecutar de todas formas*. También puedes ir a *Propiedades → Desbloquear* antes de ejecutarlo.

## Licencia

[MIT](LICENSE) © 2026 Javier Gutiérrez ([javifly](https://github.com/javifly))

---

### English summary

Menu-driven batch script to enable or disable **automatic sign-in on Windows 11**. Supports local and Microsoft accounts and lists local users to choose from. It also disables the Windows Hello–only sign-in option that blocks auto-logon, and can optionally skip the password prompt when waking from sleep. Option 2 reverts every change. The password is stored in plain text in the registry, as Windows' built-in `AutoAdminLogon` mechanism requires. Run it as administrator; the script elevates itself.
