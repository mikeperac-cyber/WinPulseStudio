@echo off
title Microsoft WinPulse Control Studio
if exist "%~dp0WinPulseStudio.exe" (
    start "" "%~dp0WinPulseStudio.exe"
) else if exist "%~dp0src\WinPulseStudio\bin\Release\net10.0-windows\win-x64\WinPulseStudio.exe" (
    start "" "%~dp0src\WinPulseStudio\bin\Release\net10.0-windows\win-x64\WinPulseStudio.exe"
) else (
    dotnet run --project "%~dp0src\WinPulseStudio\WinPulseStudio.csproj" -c Release
)
