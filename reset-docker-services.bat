@echo off
echo 警告: 此操作将删除所有 Docker 数据和容器！
echo 这包括数据库、Redis 缓存和 Elasticsearch 索引。
echo.
set /p confirm=确定要继续吗？(y/N):
if /i not "%confirm%"=="y" (
    echo 操作已取消。
    pause
    exit /b 0
)

echo 正在停止并删除 Docker 服务和数据...
docker-compose down -v

:: 删除相关镜像（可选）
echo.
set /p delete_images=是否要删除相关镜像？(y/N):
if /i "%delete_images%"=="y" (
    echo 删除相关镜像...
    docker rmi postgres:latest redis:latest docker.elastic.co/elasticsearch/elasticsearch:9.1.5 docker.elastic.co/kibana/kibana:9.1.5
)

echo.
echo Docker 服务和数据已完全重置。
echo 下次运行 start-docker-services.bat 将重新创建所有服务。
pause