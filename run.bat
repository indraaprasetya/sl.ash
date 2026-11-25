@echo off
setlocal

set "GODOT_EXE="

where godot >nul 2>nul
if %errorlevel%==0 (
	for /f "delims=" %%i in ('where godot') do (
		set "GODOT_EXE=%%i"
		goto :found
	)
)

for /d %%D in ("%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine*") do (
	for %%F in ("%%~D\Godot_v4*_win64.exe" "%%~D\*\Godot_v4*_win64.exe") do (
		if exist "%%~F" (
			set "GODOT_EXE=%%~F"
			goto :found
		)
	)
)

:found
if "%GODOT_EXE%"=="" (
	echo [ERROR] Godot 4 executable not found in PATH or WinGet packages.
	echo Install via: winget install GodotEngine.GodotEngine
	exit /b 1
)

if /i "%~1"=="--editor" (
	"%GODOT_EXE%" --editor --path "%~dp0."
) else (
	"%GODOT_EXE%" --path "%~dp0." %*
)
