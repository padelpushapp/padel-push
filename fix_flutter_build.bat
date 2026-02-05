@echo off
title Limpieza completa Flutter + Gradle + Kotlin
echo =============================================
echo  LIMPIANDO PROCESOS BLOQUEADOS
echo =============================================

taskkill /F /IM java.exe >nul 2>&1
taskkill /F /IM gradle* >nul 2>&1
taskkill /F /IM kotlinc* >nul 2>&1
taskkill /F /IM adb.exe >nul 2>&1

echo Procesos terminados.
echo.

echo =============================================
echo  BORRANDO CACHES DEL PROYECTO
echo =============================================

if exist android\.gradle (
    echo Eliminando android\.gradle ...
    rmdir /s /q android\.gradle
)

if exist build (
    echo Eliminando build ...
    rmdir /s /q build
)

echo Caches del proyecto eliminadas.
echo.

echo =============================================
echo  BORRANDO CACHES GLOBALES DE GRADLE
echo =============================================

if exist "%USERPROFILE%\.gradle" (
    echo Eliminando %USERPROFILE%\.gradle ...
    rmdir /s /q "%USERPROFILE%\.gradle"
)

echo Caches globales borradas.
echo.

echo =============================================
echo  BORRANDO CACHE DE PUB
echo =============================================

if exist "%LOCALAPPDATA%\Pub\Cache" (
    echo Eliminando %LOCALAPPDATA%\Pub\Cache ...
    rmdir /s /q "%LOCALAPPDATA%\Pub\Cache"
)

echo Cache Pub eliminada.
echo.

echo =============================================
echo  EJECUTANDO flutter clean
echo =============================================

flutter clean

echo =============================================
echo  EJECUTANDO flutter pub get
echo =============================================

flutter pub get

echo =============================================
echo  PROCESO COMPLETO
echo Ya puedes ejecutar:
echo flutter build apk --release --no-tree-shake-icons
echo =============================================

pause
