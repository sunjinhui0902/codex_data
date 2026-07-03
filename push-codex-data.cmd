@echo off
set MSG=%*
if "%MSG%"=="" set MSG=sync: update codex_data
powershell -ExecutionPolicy Bypass -Command "Set-Location 'D:\ai_data\codex'; git add -A; git commit -m \"%MSG%\"; if ($LASTEXITCODE -eq 0) { git push origin main }"
pause
