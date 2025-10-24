@echo off
echo 正在启动 Demo Mall Docker 服务...

:: 检查 Docker Desktop 是否运行
docker version >nul 2>&1
if %errorlevel% neq 0 (
    echo 错误: Docker Desktop 未运行，请先启动 Docker Desktop
    pause
    exit /b 1
)

:: 启动所有 Docker 服务
echo 启动 PostgreSQL, Redis, Elasticsearch 和 Kibana...
docker-compose up -d

:: 等待服务启动完成
echo 等待服务启动完成...
timeout /t 30 /nobreak >nul

:: 检查服务状态
echo 检查服务状态...
docker-compose ps

echo.
echo ========================================
echo Docker 服务启动完成！
echo.
echo 服务访问地址:
echo - PostgreSQL: localhost:5432
echo - Redis: localhost:6379
echo - Elasticsearch: http://localhost:9200
echo - Kibana: http://localhost:5601
echo.
echo 现在可以启动 Demo Mall 微服务了。
echo ========================================
pause