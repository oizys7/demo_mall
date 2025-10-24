@echo off
echo ========================================
echo Demo Mall Docker 镜像构建脚本 (Windows)
echo ========================================

REM 设置环境变量
set COMPOSE_CONVERT_WINDOWS_PATHS=1
set COMPOSE_PATH_SEPARATOR=;
set DOCKER_BUILDKIT=1

REM 检查 Docker Desktop 是否运行
echo 检查 Docker Desktop 状态...
docker version >nul 2>&1
if %errorlevel% neq 0 (
    echo 错误: Docker Desktop 未运行，请先启动 Docker Desktop
    pause
    exit /b 1
)

echo Docker Desktop 正在运行
echo.

REM 设置变量
set APP_VERSION=1.0.0
set DOCKER_REGISTRY_PREFIX=demo-mall

REM 构建镜像
echo 开始构建镜像...
echo.

REM 构建开发环境镜像
echo 构建 Gateway 服务开发镜像...
docker build -f demo-mall-gateway/Dockerfile.dev -t %DOCKER_REGISTRY_PREFIX%/gateway:dev --build-arg APP_VERSION=%APP_VERSION% demo-mall-gateway/
if %errorlevel% neq 0 (
    echo Gateway 镜像构建失败
    pause
    exit /b 1
)
echo Gateway 镜像构建成功

echo 构建 User 服务开发镜像...
docker build -f demo-mall-user/Dockerfile.dev -t %DOCKER_REGISTRY_PREFIX%/user:dev --build-arg APP_VERSION=%APP_VERSION% demo-mall-user/
if %errorlevel% neq 0 (
    echo User 镜像构建失败
    pause
    exit /b 1
)
echo User 镜像构建成功

echo 构建 Product 服务开发镜像...
docker build -f demo-mall-product/Dockerfile.dev -t %DOCKER_REGISTRY_PREFIX%/product:dev --build-arg APP_VERSION=%APP_VERSION% demo-mall-product/
if %errorlevel% neq 0 (
    echo Product 镜像构建失败
    pause
    exit /b 1
)
echo Product 镜像构建成功

echo 构建 Order 服务开发镜像...
docker build -f demo-mall-order/Dockerfile.dev -t %DOCKER_REGISTRY_PREFIX%/order:dev --build-arg APP_VERSION=%APP_VERSION% demo-mall-order/
if %errorlevel% neq 0 (
    echo Order 镜像构建失败
    pause
    exit /b 1
)
echo Order 镜像构建成功

echo.
echo ========================================
echo 所有开发镜像构建完成！
echo.
echo 构建的镜像:
docker images | findstr %DOCKER_REGISTRY_PREFIX%
echo.
echo 现在可以使用 start-services.bat 启动服务
echo ========================================
pause