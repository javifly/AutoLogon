@echo off
chcp 65001 >nul
setlocal EnableExtensions DisableDelayedExpansion
title Inicio de sesion automatico - Windows 11

:: ============================================================
::  AutoLogon.bat  v1.1.0
::  Activa / desactiva el inicio de sesion automatico en Windows 11
::  Probado en Windows 11 26H2
::
::  Autor   : Javier Gutierrez (javifly)
::  Repo    : https://github.com/javifly/AutoLogon
::  Licencia: MIT
:: ============================================================

:: --- Auto-elevacion a administrador ---
fltmc >nul 2>&1 || (
    echo Solicitando permisos de administrador...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

set "WL=HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
set "PL=HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\PasswordLess\Device"
set "BK=HKLM\SOFTWARE\AutoLogonScript"

:MENU
cls
set "ESTADO=DESACTIVADO"
set "USR_ACT="
for /f "tokens=3" %%a in ('reg query "%WL%" /v AutoAdminLogon 2^>nul ^| find "AutoAdminLogon"') do if "%%a"=="1" set "ESTADO=ACTIVADO"
for /f "tokens=2,*" %%a in ('reg query "%WL%" /v DefaultUserName 2^>nul ^| find "DefaultUserName"') do set "USR_ACT=%%b"
echo ==================================================
echo    INICIO DE SESIÓN AUTOMÁTICO - WINDOWS 11
echo ==================================================
echo    Estado actual : %ESTADO%
if "%ESTADO%"=="ACTIVADO" echo    Usuario       : %USR_ACT%
echo.
echo    1. Activar inicio de sesión automático
echo    2. Desactivar (volver a pedir contraseña)
echo    3. Salir sin hacer nada
echo.
choice /c 123 /n /m "   Elige una opción [1-3]: "
if errorlevel 3 goto SALIR
if errorlevel 2 goto DESACTIVAR
if errorlevel 1 goto ACTIVAR
goto MENU

:: ============================================================
:ACTIVAR
cls
echo --- ACTIVAR INICIO DE SESIÓN AUTOMÁTICO ---
echo.
echo Cuentas de usuario activas en este equipo:
echo.
powershell -NoProfile -Command "$i=0; Get-LocalUser | Where-Object Enabled | Sort-Object Name | ForEach-Object { $i++; $t=if($_.PrincipalSource -eq 'MicrosoftAccount'){'Cuenta Microsoft'}else{'Local'}; $m=if($_.Name -eq $env:USERNAME){'  <- actual'}else{''}; '   {0}. {1,-22} ({2}){3}' -f $i,$_.Name,$t,$m }"
echo.
set "AL_USER=%USERNAME%"
set /p "AL_USER=Escribe el número o el nombre del usuario [Intro = %USERNAME%]: "
for /f "usebackq delims=" %%a in (`powershell -NoProfile -Command "$u=@(Get-LocalUser | Where-Object Enabled | Sort-Object Name); $n=0; if([int]::TryParse($env:AL_USER,[ref]$n) -and $n -ge 1 -and $n -le $u.Count){$u[$n-1].Name}else{$env:AL_USER}"`) do set "AL_USER=%%a"
echo Usuario elegido: %AL_USER%
set "AL_DOMAIN=%COMPUTERNAME%"
set "SRC="
for /f "usebackq delims=" %%a in (`powershell -NoProfile -Command "try{(Get-LocalUser -Name $env:AL_USER -ErrorAction Stop).PrincipalSource}catch{'NOEXISTE'}"`) do set "SRC=%%a"

if /i "%SRC%"=="NOEXISTE" (
    echo.
    echo [ERROR] No existe ninguna cuenta local llamada "%AL_USER%".
    echo         Este script no está pensado para cuentas de dominio.
    echo.
    pause
    goto MENU
)

if /i "%SRC%"=="MicrosoftAccount" (
    echo.
    echo Esta cuenta está vinculada a una cuenta Microsoft.
    set "AL_USER="
    set /p "AL_USER=Correo completo de la cuenta Microsoft: "
    set "AL_DOMAIN=MicrosoftAccount"
)
if not defined AL_USER (
    echo [ERROR] No has indicado usuario.
    pause
    goto MENU
)

echo.
echo Introduce la contraseña de la cuenta (la contraseña real, NO el PIN de Windows Hello).
echo No se verá mientras escribes.
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $k='HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'; function Leer-Clave($m){$s=Read-Host $m -AsSecureString; $b=[Runtime.InteropServices.Marshal]::SecureStringToBSTR($s); try{[Runtime.InteropServices.Marshal]::PtrToStringBSTR($b)}finally{[Runtime.InteropServices.Marshal]::ZeroFreeBSTR($b)}}; try{$a=Leer-Clave 'Clave'; $c=Leer-Clave 'Repite la clave'}catch{Write-Host ('Error leyendo la clave: '+$_) -ForegroundColor Red; exit 1}; if([string]::IsNullOrEmpty($a)){Write-Host 'La clave esta vacia. No se ha cambiado nada.' -ForegroundColor Red; exit 1}; if($a -cne $c){Write-Host 'Las claves no coinciden. No se ha cambiado nada.' -ForegroundColor Red; exit 1}; New-ItemProperty -Path $k -Name AutoAdminLogon -Value '1' -PropertyType String -Force | Out-Null; New-ItemProperty -Path $k -Name DefaultUserName -Value $env:AL_USER -PropertyType String -Force | Out-Null; New-ItemProperty -Path $k -Name DefaultDomainName -Value $env:AL_DOMAIN -PropertyType String -Force | Out-Null; New-ItemProperty -Path $k -Name DefaultPassword -Value $a -PropertyType String -Force | Out-Null; Remove-ItemProperty -Path $k -Name AutoLogonCount -ErrorAction SilentlyContinue; Write-Host 'Clave guardada.' -ForegroundColor Green; exit 0"
if errorlevel 1 (
    echo.
    pause
    goto MENU
)

:: Desactivar "Solo permitir inicio de sesion con Windows Hello para cuentas Microsoft"
:: (si esta activo, Windows ignora el inicio automatico). Se guarda el valor original.
reg query "%BK%" /v PrevPasswordLess >nul 2>&1 || (
    for /f "tokens=3" %%a in ('reg query "%PL%" /v DevicePasswordLessBuildVersion 2^>nul ^| find "DevicePasswordLessBuildVersion"') do reg add "%BK%" /v PrevPasswordLess /t REG_DWORD /d %%a /f >nul
)
reg add "%PL%" /v DevicePasswordLessBuildVersion /t REG_DWORD /d 0 /f >nul

echo.
choice /c SN /m "¿Quitar también la contraseña al volver de suspensión"
if errorlevel 2 goto ACT_FIN
powercfg /SETACVALUEINDEX SCHEME_CURRENT SUB_NONE CONSOLELOCK 0
powercfg /SETDCVALUEINDEX SCHEME_CURRENT SUB_NONE CONSOLELOCK 0
powercfg /SETACTIVE SCHEME_CURRENT

:ACT_FIN
echo.
echo [OK] Inicio de sesión automático ACTIVADO para "%AL_USER%".
goto REINICIO

:: ============================================================
:DESACTIVAR
cls
echo --- DESACTIVAR INICIO DE SESIÓN AUTOMÁTICO ---
echo.
reg add "%WL%" /v AutoAdminLogon /t REG_SZ /d 0 /f >nul
reg delete "%WL%" /v DefaultPassword /f >nul 2>&1
reg delete "%WL%" /v AutoLogonCount /f >nul 2>&1

:: Restaurar la opcion de Windows Hello a como estaba (2 = valor por defecto)
set "PREV=2"
for /f "tokens=3" %%a in ('reg query "%BK%" /v PrevPasswordLess 2^>nul ^| find "PrevPasswordLess"') do set "PREV=%%a"
reg add "%PL%" /v DevicePasswordLessBuildVersion /t REG_DWORD /d %PREV% /f >nul
reg delete "%BK%" /f >nul 2>&1

:: Volver a pedir contrasena al salir de suspension
powercfg /SETACVALUEINDEX SCHEME_CURRENT SUB_NONE CONSOLELOCK 1
powercfg /SETDCVALUEINDEX SCHEME_CURRENT SUB_NONE CONSOLELOCK 1
powercfg /SETACTIVE SCHEME_CURRENT

echo [OK] Inicio de sesión automático DESACTIVADO. La contraseña guardada se ha borrado.
goto REINICIO

:: ============================================================
:REINICIO
echo.
choice /c SN /m "¿Reiniciar ahora para comprobarlo"
if errorlevel 2 goto SALIR
shutdown /r /t 5 /c "Reinicio para aplicar el inicio de sesion automatico"
goto SALIR

:SALIR
endlocal
exit /b
