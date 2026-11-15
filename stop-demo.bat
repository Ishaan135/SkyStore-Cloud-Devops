@echo off
cd /d "%~dp0"
docker compose down
docker rm -f skystore-app-ci
pause
