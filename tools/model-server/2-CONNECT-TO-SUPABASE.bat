@echo off
rem Run on the GPU machine after START-HERE.bat, with server-key.txt and supabase-url.txt next to it.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup-worker.ps1"
