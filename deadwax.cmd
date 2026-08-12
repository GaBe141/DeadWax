@echo off
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\deadwax.ps1" %*
exit /b %errorlevel%
