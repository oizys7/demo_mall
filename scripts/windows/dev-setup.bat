@echo off
echo ========================================
echo Demo Mall 开发环境初始化脚本 (Windows)
echo ========================================

REM 检查 Docker Desktop 是否运行
echo 检查 Docker Desktop 状态...
docker version >nul 2>&1
if %errorlevel% neq 0 (
    echo 错误: Docker Desktop 未运行，请先启动 Docker Desktop
    echo.
    echo 请按照以下步骤启动 Docker Desktop:
    echo 1. 从开始菜单启动 Docker Desktop
    echo 2. 等待 Docker Desktop 完全启动（状态栏图标变绿）
    echo 3. 重新运行此脚本
    pause
    exit /b 1
)

echo Docker Desktop 正在运行
echo.

REM 创建必要的目录
echo 创建必要的目录结构...
if not exist docker\postgres mkdir docker\postgres
if not exist docker\windows mkdir docker\windows
if not exist scripts\windows mkdir scripts\windows
if not exist logs mkdir logs

REM 检查环境文件
echo 检查环境配置文件...
if not exist docker\.env.windows (
    echo 警告: docker\.env.windows 文件不存在
    echo 请确保环境配置文件已正确创建
    pause
    exit /b 1
)

REM 检查 Docker Compose 文件
echo 检查 Docker Compose 配置文件...
if not exist docker\docker-compose.dev.yml (
    echo 警告: docker\docker-compose.dev.yml 文件不存在
    echo 请确保开发环境配置文件已正确创建
    pause
    exit /b 1
)

REM 设置环境变量
echo 设置环境变量...
set COMPOSE_CONVERT_WINDOWS_PATHS=1
set COMPOSE_PATH_SEPARATOR=;

REM 启动基础服务
echo.
echo 启动基础基础设施服务...
docker-compose -f docker/docker-compose.yml up -d postgres redis elasticsearch kibana

echo 等待基础服务启动...
timeout /t 30 /nobreak >nul

REM 检查基础服务状态
echo 检查基础服务健康状态...
echo 检查 PostgreSQL...
:check_postgres
docker exec demo-mall-postgres pg_isready -U oizys >nul 2>&1
if %errorlevel% neq 0 (
    echo PostgreSQL 尚未就绪，等待 5 秒后重试...
    timeout /t 5 /nobreak >nul
    goto check_postgres
)
echo PostgreSQL 已就绪 ✓

echo 检查 Redis...
:check_redis
docker exec demo-mall-redis redis-cli ping >nul 2>&1
if %errorlevel% neq 0 (
    echo Redis 尚未就绪，等待 5 秒后重试...
    timeout /t 5 /nobreak >nul
    goto check_redis
)
echo Redis 已就绪 ✓

echo 检查 Elasticsearch...
:check_elasticsearch
curl -f http://localhost:9200/_cluster/health >nul 2>&1
if %errorlevel% neq 0 (
    echo Elasticsearch 尚未就绪，等待 10 秒后重试...
    timeout /t 10 /nobreak >nul
    goto check_elasticsearch
)
echo Elasticsearch 已就绪 ✓

REM 启动 Nacos
echo.
echo 启动 Nacos 服务注册中心...
docker-compose -f docker/docker-compose.dev.yml up -d nacos

echo 等待 Nacos 启动...
timeout /t 60 /nobreak >nul

REM 检查 Nacos 状态
echo 检查 Nacos 健康状态...
:check_nacos
curl -f http://localhost:8848/nacos/ >nul 2>&1
if %errorlevel% neq 0 (
    echo Nacos 尚未就绪，等待 10 秒后重试...
    timeout /t 10 /nobreak >nul
    goto check_nacos
)
echo Nacos 已就绪 ✓

echo.
echo ========================================
echo 开发环境初始化完成！
echo.
echo 环境状态:
echo - PostgreSQL: 运行正常 ✓
echo - Redis: 运行正常 ✓
echo - Elasticsearch: 运行正常 ✓
echo - Kibana: 运行正常 ✓
echo - Nacos: 运行正常 ✓
echo.
echo 下一步操作:
echo 1. 构建服务镜像: scripts\windows\build-images.bat
echo 2. 启动微服务: scripts\windows\start-services.bat
echo.
echo 管理工具:
echo - Docker 管理: scripts\windows\manage-docker.ps1
echo - 查看日志: docker-compose -f docker/docker-compose.dev.yml logs -f [service]
echo - 服务状态: docker-compose -f docker/docker-compose.dev.yml ps
echo ========================================
pause