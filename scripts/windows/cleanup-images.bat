@echo off
echo ========================================
echo Demo Mall Docker 镜像清理脚本 (Windows)
echo ========================================

REM 检查 Docker Desktop 是否运行
echo 检查 Docker Desktop 状态...
docker version >nul 2>&1
if %errorlevel% neq 0 (
    echo 错误: Docker Desktop 未运行
    pause
    exit /b 1
)

echo 当前 Demo Mall 镜像:
docker images demo-mall --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
echo.

set /p confirm=确定要清理所有 Demo Mall 镜像吗？(y/N):
if /i not "%confirm%"=="y" (
    echo 操作已取消。
    pause
    exit /b 0
)

echo.
echo 开始清理 Demo Mall 镜像...

REM 停止相关容器
echo 停止相关容器...
docker-compose -f docker/docker-compose.dev.yml down 2>nul
docker-compose -f docker/docker-compose.yml down 2>nul

REM 删除镜像
echo 删除 Demo Mall 镜像...
for /f "tokens=1,2" %%i in ('docker images demo-mall --format "{{.Repository}}:{{.Tag}}"') do (
    echo 删除镜像: %%i:%%j
    docker rmi %%i:%%j 2>nul
)

REM 清理悬空镜像
echo 清理悬空镜像...
docker image prune -f

REM 清理未使用的容器和网络
echo 清理未使用的资源...
docker container prune -f
docker network prune -f

echo.
echo ========================================
echo 清理完成！
echo.
echo 如需重新构建，请运行 build-images.bat
echo ========================================
pause