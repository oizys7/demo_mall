@echo off
echo ========================================
echo Demo Mall 服务启动脚本 (Windows)
echo ========================================

REM 设置环境变量
set COMPOSE_CONVERT_WINDOWS_PATHS=1
set COMPOSE_PATH_SEPARATOR=;

REM 检查 Docker Desktop 是否运行
echo 检查 Docker Desktop 状态...
docker version >nul 2>&1
if %errorlevel% neq 0 (
    echo 错误: Docker Desktop 未运行，请先启动 Docker Desktop
    pause
    exit /b 1
)

REM 加载环境变量
echo 加载开发环境配置...
set -a; source docker/.env.windows; set +a

REM 启动基础设施服务
echo.
echo 启动基础设施服务...
docker-compose -f docker/docker-compose.yml up -d postgres redis elasticsearch kibana

REM 等待基础设施服务启动
echo 等待基础设施服务启动完成...
timeout /t 30 /nobreak >nul

REM 启动 Nacos 服务
echo 启动 Nacos 服务...
docker-compose -f docker/docker-compose.dev.yml up -d nacos

REM 等待 Nacos 启动
echo 等待 Nacos 启动完成...
timeout /t 45 /nobreak >nul

REM 检查 Nacos 健康状态
echo 检查 Nacos 健康状态...
:check_nacos
curl -f http://localhost:8848/nacos/ >nul 2>&1
if %errorlevel% neq 0 (
    echo Nacos 尚未就绪，等待 10 秒后重试...
    timeout /t 10 /nobreak >nul
    goto check_nacos
)

echo Nacos 已就绪！

REM 启动微服务
echo.
echo 启动微服务...
docker-compose -f docker/docker-compose.dev.yml up -d demo-mall-gateway demo-mall-user demo-mall-product demo-mall-order

REM 等待服务启动
echo 等待服务启动完成...
timeout /t 60 /nobreak >nul

echo.
echo ========================================
echo 所有服务启动完成！
echo.
echo 服务访问地址:
echo - API 网关: http://localhost:9100
echo - 用户服务: http://localhost:9201
echo - 商品服务: http://localhost:9202
echo - 订单服务: http://localhost:9203
echo.
echo 基础设施服务:
echo - PostgreSQL: localhost:5432
echo - Redis: localhost:6379
echo - Elasticsearch: http://localhost:9200
echo - Kibana: http://localhost:5601
echo - Nacos: http://localhost:8848/nacos
echo.
echo 检查服务状态...
docker-compose -f docker/docker-compose.dev.yml ps
echo.
echo 查看服务日志: docker-compose -f docker/docker-compose.dev.yml logs -f [service_name]
echo 停止所有服务: stop-services.bat
echo ========================================
pause