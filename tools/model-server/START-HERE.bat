@echo off
rem Double-click on the GPU machine. Runs the setup once; safe to run again.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup-model-server.ps1"
pause
