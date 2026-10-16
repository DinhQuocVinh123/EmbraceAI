@echo off
rem Run on the GPU machine after 2-CONNECT-TO-SUPABASE.bat. Adds Whisper for voice typing; safe to run again.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup-speech.ps1"
