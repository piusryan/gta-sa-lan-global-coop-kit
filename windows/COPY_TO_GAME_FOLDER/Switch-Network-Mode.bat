@echo off
title GTA SA Co-op - Network Mode Switcher
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Switch-Network-Mode.ps1"
if errorlevel 1 pause
