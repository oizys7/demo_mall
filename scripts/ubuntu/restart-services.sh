#!/bin/bash

# Demo Mall 服务重启脚本 (Ubuntu)

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
print_color "green" "Demo Mall 服务重启脚本 (Ubuntu)"
print_color "green" "========================================"
echo

# 解析命令行参数
ENVIRONMENT="prod"
COMPOSE_FILE="docker/docker-compose.prod.yml"
SERVICES=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --env|-e)
            ENVIRONMENT="$2"
            if [ "$ENVIRONMENT" = "dev" ]; then
                COMPOSE_FILE="docker/docker-compose.dev.yml"
            fi
            shift 2
            ;;
        --services|-s)
            SERVICES="$2"
            shift 2
            ;;
        --help|-h)
            echo "用法: $0 [选项]"
            echo
            echo "选项:"
            echo "  -e, --env ENV            环境类型 (dev|prod, 默认: prod)"
            echo "  -s, --services SERVICES   指定要重启的服务 (用逗号分隔)"
            echo "  -h, --help               显示帮助信息"
            echo
            echo "示例:"
            echo "  $0                      # 重启所有服务"
            echo "  $0 -s gateway,user     # 只重启 gateway 和 user 服务"
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
    print_color "red" "错误: Docker 未运行"
    exit 1
fi

# 显示重启配置
print_color "cyan" "重启配置:"
echo "  - 环境: $ENVIRONMENT"
echo "  - 配置文件: $COMPOSE_FILE"
if [ -n "$SERVICES" ]; then
    echo "  - 指定服务: $SERVICES"
else
    echo "  - 重启所有服务"
fi
echo

# 重启前状态检查
print_color "cyan" "重启前状态检查:"
docker-compose -f "$COMPOSE_FILE" ps 2>/dev/null || print_color "yellow" "没有运行的服务"
echo

# 重启服务
print_color "yellow" "重启服务..."

if [ -n "$SERVICES" ]; then
    # 重启指定服务
    IFS=',' read -ra SERVICE_ARRAY <<< "$SERVICES"
    for service in "${SERVICE_ARRAY[@]}"; do
        service=$(echo "$service" | xargs)  # 去除空格
        print_color "white" "重启服务: $service"
        docker-compose -f "$COMPOSE_FILE" restart "$service"
    done
else
    # 重启所有服务
    print_color "white" "重启所有服务..."
    docker-compose -f "$COMPOSE_FILE" restart
fi

# 等待服务启动
print_color "white" "等待服务启动..."
sleep 30

# 健康检查
print_color "cyan" "重启后健康检查:"

SERVICES_TO_CHECK=(
    "Nacos:http://localhost:8848/nacos/"
    "Gateway:http://localhost:9100/actuator/health"
    "User Service:http://localhost:9201/actuator/health"
    "Product Service:http://localhost:9202/actuator/health"
    "Order Service:http://localhost:9203/actuator/health"
)

HEALTHY_COUNT=0

for service in "${SERVICES_TO_CHECK[@]}"; do
    NAME=$(echo $service | cut -d: -f1)
    URL=$(echo $service | cut -d: -f2-)

    for i in {1..10}; do
        if curl -s -f --max-time 10 "$URL" >/dev/null 2>&1; then
            print_color "green" "✓ $NAME: 健康"
            HEALTHY_COUNT=$((HEALTHY_COUNT + 1))
            break
        fi
        if [ $i -eq 10 ]; then
            print_color "red" "✗ $NAME: 不健康"
        fi
        sleep 5
    done
done

echo
# 显示重启后状态
print_color "cyan" "重启后状态:"
docker-compose -f "$COMPOSE_FILE" ps
echo

# 显示统计信息
print_color "cyan" "重启统计:"
echo "  - 健康服务: $HEALTHY_COUNT/${#SERVICES_TO_CHECK[@]}"
echo

if [ $HEALTHY_COUNT -eq ${#SERVICES_TO_CHECK[@]} ]; then
    print_color "green" "🎉 服务重启成功！所有服务运行正常。"
else
    print_color "yellow" "⚠️  服务重启完成，但部分服务可能需要更多时间启动。"
    print_color "yellow" "建议稍后使用 ./scripts/ubuntu/monitor.sh 检查详细状态。"
fi

print_color "green" "========================================"