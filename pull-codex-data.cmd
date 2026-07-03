@echo off
powershell -ExecutionPolicy Bypass -Command "Set-Location 'D:\ai_data\codex'; git pull --ff-only origin main"
pause
