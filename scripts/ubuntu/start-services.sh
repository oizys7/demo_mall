#!/bin/bash

# Demo Mall 服务启动脚本 (Ubuntu)

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

print_color "green" "========================================"
print_color "green" "Demo Mall 服务启动脚本 (Ubuntu)"
print_color "green" "========================================"
echo

# 解析命令行参数
ENVIRONMENT="prod"
COMPOSE_FILE="docker/docker-compose.prod.yml"
RESTART=false
SKIP_INFRA=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --env|-e)
            ENVIRONMENT="$2"
            if [ "$ENVIRONMENT" = "dev" ]; then
                COMPOSE_FILE="docker/docker-compose.dev.yml"
            fi
            shift 2
            ;;
        --restart|-r)
            RESTART=true
            shift
            ;;
        --skip-infra|-i)
            SKIP_INFRA=true
            shift
            ;;
        --help|-h)
            echo "用法: $0 [选项]"
            echo
            echo "选项:"
            echo "  -e, --env ENV            环境类型 (dev|prod, 默认: prod)"
            echo "  -r, --restart            重启现有服务"
            echo "  -i, --skip-infra         跳过基础设施服务"
            echo "  -h, --help               显示帮助信息"
            exit 0
            ;;
        *)
            print_color "red" "未知参数: $1"
            exit 1
            ;;
    esac
done

# 检查 Docker
if ! docker info >/dev/null 2>&1; then
    print_color "red" "错误: Docker 未运行，请先启动 Docker 服务"
    exit 1
fi

# 加载环境变量
ENV_FILE="docker/.env.ubuntu"
if [ -f "$ENV_FILE" ]; then
    print_color "cyan" "加载环境变量: $ENV_FILE"
    export $(grep -v '^#' "$ENV_FILE" | xargs)
fi

# 显示启动配置
print_color "cyan" "启动配置:"
echo "  - 环境: $ENVIRONMENT"
echo "  - 配置文件: $COMPOSE_FILE"
echo "  - 重启服务: $RESTART"
echo "  - 跳过基础设施: $SKIP_INFRA"
echo

# 如果指定重启，先停止服务
if [ "$RESTART" = true ]; then
    print_color "yellow" "停止现有服务..."
    docker-compose -f "$COMPOSE_FILE" down 2>/dev/null || true
    sleep 10
fi

# 启动基础设施服务
if [ "$SKIP_INFRA" = false ]; then
    print_color "cyan" "启动基础设施服务..."

    # 启动基础服务
    docker-compose -f docker/docker-compose.yml up -d postgres redis elasticsearch kibana

    # 等待基础设施服务启动
    print_color "white" "等待基础设施服务启动..."
    sleep 30

    # 检查服务状态
    print_color "white" "检查基础设施服务状态..."

    # 检查 PostgreSQL
    for i in {1..10}; do
        if docker exec demo-mall-postgres pg_isready -U oizys >/dev/null 2>&1; then
            print_color "green" "✓ PostgreSQL 已就绪"
            break
        fi
        if [ $i -eq 10 ]; then
            print_color "red" "✗ PostgreSQL 启动超时"
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
        fi
        sleep 3
    done

    # 启动 Nacos
    docker-compose -f "$COMPOSE_FILE" up -d nacos

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
        fi
        sleep 10
    done
fi

# 启动应用服务
print_color "cyan" "启动应用服务..."
docker-compose -f "$COMPOSE_FILE" up -d demo-mall-gateway demo-mall-user demo-mall-product demo-mall-order

# 等待应用服务启动
print_color "white" "等待应用服务启动..."
sleep 60

# 显示容器状态
print_color "cyan" "容器状态:"
docker-compose -f "$COMPOSE_FILE" ps
echo

# 显示访问地址
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

print_color "green" "========================================"
print_color "green" "服务启动完成！"
echo
print_color "cyan" "管理命令:"
echo "查看日志: docker-compose -f $COMPOSE_FILE logs -f [service_name]"
echo "停止服务: ./scripts/ubuntu/stop-services.sh"
echo "查看状态: ./scripts/ubuntu/monitor.sh"
echo "健康检查: ./scripts/ubuntu/health-check.sh"
print_color "green" "========================================"