#!/bin/bash

# Demo Mall 完整部署脚本 (Ubuntu)
# 支持一键部署和完整的生产环境配置

set -e

# 颜色输出函数
print_color() {
    local color=$1
    local message=$2
    case $color in
        "red") echo -e "\033[31m$message\033[0m" ;;
        "green") echo -e "\033[32m$message\033[0m" ;;
        "yellow") echo -e "\033[33m$message\033[0m" ;;
        "blue") echo -e "\033[34m$message\033[0m" ;;
        "magenta") echo -e "\033[35m$message\033[0m" ;;
        "cyan") echo -e "\033[36m$message\033[0m" ;;
        "white") echo -e "\033[37m$message\033[0m" ;;
        *) echo "$message" ;;
    esac
}

# 显示标题
print_color "green" "========================================"
print_color "green" "Demo Mall 完整部署脚本 (Ubuntu)"
print_color "green" "========================================"
echo

# 解析命令行参数
APP_VERSION="1.0.0"
DOCKER_REGISTRY_PREFIX="demo-mall"
ENVIRONMENT="prod"
SKIP_BUILD=false
SKIP_INFRA=false
FORCE_RECREATE=false
VERBOSE=false
BACKUP_BEFORE_DEPLOY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --version|-v)
            APP_VERSION="$2"
            shift 2
            ;;
        --registry|-r)
            DOCKER_REGISTRY_PREFIX="$2"
            shift 2
            ;;
        --env|-e)
            ENVIRONMENT="$2"
            shift 2
            ;;
        --skip-build|-s)
            SKIP_BUILD=true
            shift
            ;;
        --skip-infra|-i)
            SKIP_INFRA=true
            shift
            ;;
        --force|-f)
            FORCE_RECREATE=true
            shift
            ;;
        --backup|-b)
            BACKUP_BEFORE_DEPLOY=true
            shift
            ;;
        --verbose|-V)
            VERBOSE=true
            shift
            ;;
        --help|-h)
            echo "用法: $0 [选项]"
            echo
            echo "选项:"
            echo "  -v, --version VERSION    应用版本 (默认: 1.0.0)"
            echo "  -r, --registry PREFIX    镜像前缀 (默认: demo-mall)"
            echo "  -e, --env ENV            环境类型 (dev|prod, 默认: prod)"
            echo "  -s, --skip-build         跳过镜像构建"
            echo "  -i, --skip-infra         跳过基础设施部署"
            echo "  -f, --force              强制重新创建容器"
            echo "  -b, --backup             部署前备份数据"
            echo "  -V, --verbose            详细输出"
            echo "  -h, --help               显示帮助信息"
            exit 0
            ;;
        *)
            print_color "red" "未知参数: $1"
            exit 1
            ;;
    esac
done

# 检查权限
if [[ $EUID -ne 0 ]]; then
    print_color "yellow" "警告: 建议使用 root 权限运行此脚本以获得最佳性能"
    echo "当前用户: $(whoami)"
    echo
fi

# 检查系统要求
print_color "cyan" "检查系统要求..."

# 检查 Docker
if ! command -v docker &> /dev/null; then
    print_color "red" "错误: Docker 未安装"
    exit 1
fi

# 检查 Docker Compose
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    print_color "red" "错误: Docker Compose 未安装"
    exit 1
fi

# 检查 Docker 服务状态
if ! docker info >/dev/null 2>&1; then
    print_color "red" "错误: Docker 服务未运行，请启动 Docker 服务"
    echo "尝试启动: sudo systemctl start docker"
    exit 1
fi

DOCKER_VERSION=$(docker version --format '{{.Server.Version}}' 2>/dev/null)
print_color "green" "系统要求检查通过"
echo "  - Docker 版本: $DOCKER_VERSION"
echo "  - 当前用户: $(whoami)"
echo

# 创建必要的目录
print_color "cyan" "创建必要的目录结构..."
DIRECTORIES=(
    "/var/lib/demo-mall/postgres"
    "/var/lib/demo-mall/redis"
    "/var/lib/demo-mall/elasticsearch"
    "/var/lib/demo-mall/nacos"
    "/var/log/demo-mall"
    "/var/backup/demo-mall"
)

for dir in "${DIRECTORIES[@]}"; do
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        print_color "white" "创建目录: $dir"
    fi
done

# 设置目录权限
chown -R 1000:1000 /var/lib/demo-mall 2>/dev/null || true
chown -R 1000:1000 /var/log/demo-mall 2>/dev/null || true

print_color "green" "目录结构创建完成"
echo

# 备份数据（如果指定）
if [ "$BACKUP_BEFORE_DEPLOY" = true ]; then
    print_color "yellow" "部署前备份数据..."
    BACKUP_DIR="/var/backup/demo-mall/backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP_DIR"

    # 备份 PostgreSQL 数据
    if docker ps | grep -q demo-mall-postgres; then
        print_color "white" "备份 PostgreSQL 数据..."
        docker exec demo-mall-postgres pg_dump -U oizys > "$BACKUP_DIR/postgres_backup.sql" 2>/dev/null || true
    fi

    # 备份其他数据目录
    for dir in postgres redis elasticsearch nacos; do
        if [ -d "/var/lib/demo-mall/$dir" ]; then
            cp -r "/var/lib/demo-mall/$dir" "$BACKUP_DIR/" 2>/dev/null || true
        fi
    done

    print_color "green" "数据备份完成: $BACKUP_DIR"
    echo
fi

# 显示部署配置
print_color "cyan" "部署配置:"
echo "  - 应用版本: $APP_VERSION"
echo "  - 镜像前缀: $DOCKER_REGISTRY_PREFIX"
echo "  - 部署环境: $ENVIRONMENT"
echo "  - 跳过构建: $SKIP_BUILD"
echo "  - 跳过基础设施: $SKIP_INFRA"
echo "  - 强制重新创建: $FORCE_RECREATE"
echo "  - 详细输出: $VERBOSE"
echo

# 加载环境变量
ENV_FILE="docker/.env.ubuntu"
if [ -f "$ENV_FILE" ]; then
    print_color "cyan" "加载环境变量: $ENV_FILE"
    export $(grep -v '^#' "$ENV_FILE" | xargs)
else
    print_color "yellow" "警告: 环境变量文件 $ENV_FILE 不存在，使用默认配置"
fi

# 构建镜像（如果需要）
if [ "$SKIP_BUILD" = false ]; then
    print_color "cyan" "构建 Docker 镜像..."

    BUILD_ARGS=""
    if [ "$VERBOSE" = true ]; then
        BUILD_ARGS="--verbose"
    fi

    if [ "$ENVIRONMENT" = "prod" ]; then
        BUILD_ARGS="$BUILD_ARGS --production"
    fi

    ./scripts/ubuntu/build-images.sh $BUILD_ARGS
    echo
fi

# 停止现有服务（如果存在）
if [ "$FORCE_RECREATE" = true ]; then
    print_color "yellow" "停止现有服务..."
    docker-compose -f docker/docker-compose.prod.yml down -v 2>/dev/null || true
    docker-compose -f docker/docker-compose.yml down -v 2>/dev/null || true
    echo
fi

# 部署基础设施服务
if [ "$SKIP_INFRA" = false ]; then
    print_color "cyan" "部署基础设施服务..."

    # 启动基础服务
    docker-compose -f docker/docker-compose.yml up -d postgres redis elasticsearch kibana

    # 等待基础设施服务启动
    print_color "white" "等待基础设施服务启动..."
    sleep 30

    # 检查基础设施服务健康状态
    print_color "white" "检查基础设施服务状态..."

    # 检查 PostgreSQL
    for i in {1..10}; do
        if docker exec demo-mall-postgres pg_isready -U oizys >/dev/null 2>&1; then
            print_color "green" "✓ PostgreSQL 已就绪"
            break
        fi
        if [ $i -eq 10 ]; then
            print_color "red" "✗ PostgreSQL 启动超时"
            exit 1
        fi
        sleep 5
    done

    # 检查 Redis
    for i in {1..10}; do
        if docker exec demo-mall-redis redis-cli ping >/dev/null 2>&1; then
            print_color "green" "✓ Redis 已就绪"
            break
        fi
        if [ $i -eq 10 ]; then
            print_color "red" "✗ Redis 启动超时"
            exit 1
        fi
        sleep 3
    done

    # 检查 Elasticsearch
    for i in {1..20}; do
        if curl -s http://localhost:9200/_cluster/health | grep -q '"status":"green\|yellow"'; then
            print_color "green" "✓ Elasticsearch 已就绪"
            break
        fi
        if [ $i -eq 20 ]; then
            print_color "red" "✗ Elasticsearch 启动超时"
            exit 1
        fi
        sleep 10
    done

    # 启动 Nacos
    docker-compose -f docker/docker-compose.prod.yml up -d nacos

    # 等待 Nacos 启动
    print_color "white" "等待 Nacos 启动..."
    sleep 60

    # 检查 Nacos
    for i in {1..15}; do
        if curl -s http://localhost:8848/nacos/ >/dev/null 2>&1; then
            print_color "green" "✓ Nacos 已就绪"
            break
        fi
        if [ $i -eq 15 ]; then
            print_color "red" "✗ Nacos 启动超时"
            exit 1
        fi
        sleep 10
    done

    print_color "green" "基础设施服务部署完成"
    echo
fi

# 部署应用服务
print_color "cyan" "部署应用服务..."

# 启动微服务
docker-compose -f docker/docker-compose.prod.yml up -d demo-mall-gateway demo-mall-user demo-mall-product demo-mall-order

# 等待应用服务启动
print_color "white" "等待应用服务启动..."
sleep 60

# 健康检查
print_color "cyan" "执行健康检查..."

SERVICES=(
    "Nacos:http://localhost:8848/nacos/"
    "Gateway:http://localhost:9100/actuator/health"
    "User Service:http://localhost:9201/actuator/health"
    "Product Service:http://localhost:9202/actuator/health"
    "Order Service:http://localhost:9203/actuator/health"
)

ALL_HEALTHY=true

for service in "${SERVICES[@]}"; do
    NAME=$(echo $service | cut -d: -f1)
    URL=$(echo $service | cut -d: -f2-)

    for i in {1..10}; do
        if curl -s -f "$URL" >/dev/null 2>&1; then
            print_color "green" "✓ $NAME: 健康"
            break
        fi
        if [ $i -eq 10 ]; then
            print_color "red" "✗ $NAME: 不健康"
            ALL_HEALTHY=false
        fi
        sleep 10
    done
done

# 显示部署结果
echo
print_color "green" "========================================"
print_color "green" "部署完成"
print_color "green" "========================================"

echo
print_color "cyan" "服务访问地址:"
echo "- API 网关: http://localhost:9100"
echo "- 用户服务: http://localhost:9201"
echo "- 商品服务: http://localhost:9202"
echo "- 订单服务: http://localhost:9203"
echo
echo "- PostgreSQL: localhost:5432"
echo "- Redis: localhost:6379"
echo "- Elasticsearch: http://localhost:9200"
echo "- Kibana: http://localhost:5601"
echo "- Nacos: http://localhost:8848/nacos"
echo

# 显示容器状态
print_color "cyan" "容器状态:"
docker-compose -f docker/docker-compose.prod.yml ps
echo

# 显示日志查看命令
print_color "cyan" "日志查看命令:"
echo "查看所有服务日志: docker-compose -f docker/docker-compose.prod.yml logs -f"
echo "查看特定服务日志: docker-compose -f docker/docker-compose.prod.yml logs -f [service_name]"
echo

# 显示管理命令
print_color "cyan" "管理命令:"
echo "停止服务: ./scripts/ubuntu/stop-services.sh"
echo "重启服务: ./scripts/ubuntu/restart-services.sh"
echo "查看状态: ./scripts/ubuntu/monitor.sh"
echo

if [ "$ALL_HEALTHY" = true ]; then
    print_color "green" "🎉 部署成功！所有服务运行正常。"
else
    print_color "yellow" "⚠️  部署完成，但部分服务可能需要更多时间启动。"
    print_color "yellow" "请稍后使用 ./scripts/ubuntu/monitor.sh 检查服务状态。"
fi

print_color "green" "========================================"