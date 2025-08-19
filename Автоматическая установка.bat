@echo off
chcp 65001 >nul
title Автоустановщик модов Minecraft
echo ========================================
echo АВТОМАТИЧЕСКАЯ УСТАНОВКА МОДОВ
echo ========================================
echo.

:: ПРАВИЛЬНЫЙ URL ДЛЯ RAW ФАЙЛА
set "MODS_LIST_URL=https://raw.githubusercontent.com/rouzylil/client-mods/main/mods_list.txt"
set "MODS_FOLDER=%APPDATA%\.minecraft\mods"
set "TEMP_LIST=temp_mods_list.txt"

echo Проверяем наличие curl...
where curl >nul 2>&1
if errorlevel 1 (
    echo Устанавливаем curl...
    powershell -Command "Invoke-WebRequest -Uri 'https://curl.se/windows/dl-7.88.1_8/curl-7.88.1-win64-mingw.zip' -OutFile 'curl.zip'"
    powershell -Command "Expand-Archive -Path 'curl.zip' -DestinationPath 'curl'"
    set "PATH=%PATH%;%~dp0curl\bin"
    del curl.zip
)

echo Создаем папку для модов...
if not exist "%MODS_FOLDER%" (
    mkdir "%MODS_FOLDER%"
    echo Создана папка: %MODS_FOLDER%
) else (
    echo Папка модов уже существует
)

echo Скачиваем список модов...
echo URL: %MODS_LIST_URL%
curl -s -L -o "%TEMP_LIST%" "%MODS_LIST_URL%"

if not exist "%TEMP_LIST%" (
    echo Ошибка: Не удалось скачать список модов!
    echo Проверьте ссылку: %MODS_LIST_URL%
    pause
    exit /b 1
)

echo Проверяем содержимое файла...
for %%F in ("%TEMP_LIST%") do set filesize=%%~zF
echo Размер файла: %filesize% байт
echo Первые 5 строк:
setlocal EnableDelayedExpansion
set count=0
for /f "usebackq delims=" %%a in ("%TEMP_LIST%") do (
    echo %%a
    set /a count+=1
    if !count! equ 5 goto end_head
)
:end_head
echo.

findstr /i "html\|DOCTYPE\|http" "%TEMP_LIST%" >nul
if not errorlevel 1 (
    echo ОШИБКА: Скачался HTML вместо списка модов!
    echo Убедитесь что используете RAW ссылку
    del "%TEMP_LIST%"
    pause
    exit /b 1
)

:: Проверяем что файл не пустой
for %%A in ("%TEMP_LIST%") do set size=%%~zA
if !size! LSS 10 (
    echo ОШИБКА: Файл mods_list.txt пустой или почти пустой!
    echo Добавьте ссылки на моды в файл
    del "%TEMP_LIST%"
    pause
    exit /b 1
)

echo Начинаем загрузку модов...
setlocal enabledelayedexpansion
set "counter=0"
set "success_count=0"

for /f "usebackq tokens=*" %%i in ("%TEMP_LIST%") do (
    set "url=%%i"
    set "url=!url: =!" :: Удаляем пробелы
    set "url=!url:~0,255!" :: Ограничение длины URL
    
    :: Пропускаем пустые строки и комментарии
    if not "!url!"=="" (
        if not "!url:~0,1!"=="#" (
            set /a counter+=1
            echo [!counter!] Загружаем: !url!
            
            for /f "delims=/ tokens=*" %%p in ("!url!") do set "filename=%%~nxp"
            
            echo Скачиваем: !filename!
            curl -s -L -o "%MODS_FOLDER%\!filename!" "!url!"
            
            if exist "%MODS_FOLDER%\!filename!" (
                echo ✓ Успешно: !filename!
                set /a success_count+=1
            ) else (
                echo ✗ Ошибка: !filename!
            )
            echo.
        )
    )
)

PAUSE