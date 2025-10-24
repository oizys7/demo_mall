@echo off
echo 正在停止 Demo Mall Docker 服务...

:: 停止所有 Docker 服务
docker-compose down

echo.
echo Docker 服务已停止。
echo 如需重新启动，请运行 start-docker-services.bat
pause