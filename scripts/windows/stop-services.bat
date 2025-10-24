@echo off
echo ========================================
echo Demo Mall 服务停止脚本 (Windows)
echo ========================================

REM 检查 Docker Desktop 是否运行
echo 检查 Docker Desktop 状态...
docker version >nul 2>&1
if %errorlevel% neq 0 (
    echo 错误: Docker Desktop 未运行
    pause
    exit /b 1
)

REM 停止微服务
echo 停止微服务...
docker-compose -f docker/docker-compose.dev.yml down demo-mall-gateway demo-mall-user demo-mall-product demo-mall-order

REM 停止基础设施服务
echo 停止基础设施服务...
docker-compose -f docker/docker-compose.dev.yml down

REM 停止基础服务
docker-compose -f docker/docker-compose.yml down

echo.
echo ========================================
echo 所有服务已停止
echo.
echo 如需重新启动，请运行 start-services.bat
echo ========================================
pause