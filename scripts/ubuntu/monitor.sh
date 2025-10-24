#!/bin/bash

# Demo Mall 服务监控脚本 (Ubuntu)

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
print_color "green" "Demo Mall 服务监控脚本 (Ubuntu)"
print_color "green" "========================================"
echo

# 解析命令行参数
ENVIRONMENT="prod"
COMPOSE_FILE="docker/docker-compose.prod.yml"
FOLLOW_LOGS=false
HEALTH_CHECK_ONLY=false
RESOURCE_USAGE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --env|-e)
            ENVIRONMENT="$2"
            if [ "$ENVIRONMENT" = "dev" ]; then
                COMPOSE_FILE="docker/docker-compose.dev.yml"
            fi
            shift 2
            ;;
        --logs|-l)
            FOLLOW_LOGS=true
            shift
            ;;
        --health|-h)
            HEALTH_CHECK_ONLY=true
            shift
            ;;
        --resources|-r)
            RESOURCE_USAGE=true
            shift
            ;;
        --help)
            echo "用法: $0 [选项]"
            echo
            echo "选项:"
            echo "  -e, --env ENV            环境类型 (dev|prod, 默认: prod)"
            echo "  -l, --logs               跟踪日志输出"
            echo "  -h, --health             仅执行健康检查"
            echo "  -r, --resources          显示资源使用情况"
            echo "  --help                   显示帮助信息"
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

# 获取系统信息
print_color "cyan" "系统信息:"
echo "  - 主机名: $(hostname)"
echo "  - 系统时间: $(date)"
echo "  - 系统负载: $(uptime)"
echo "  - 磁盘使用: $(df -h / | tail -1)"
echo "  - 内存使用: $(free -h | grep Mem)"
echo

# 容器状态监控
print_color "cyan" "容器状态:"
echo
docker-compose -f "$COMPOSE_FILE" ps
echo

# 健康检查
health_check() {
    local services=(
        "Nacos:http://localhost:8848/nacos/"
        "Gateway:http://localhost:9100/actuator/health"
        "User Service:http://localhost:9201/actuator/health"
        "Product Service:http://localhost:9202/actuator/health"
        "Order Service:http://localhost:9203/actuator/health"
        "PostgreSQL:port:5432"
        "Redis:port:6379"
        "Elasticsearch:http://localhost:9200/_cluster/health"
    )

    print_color "cyan" "健康检查结果:"
    echo

    local healthy_count=0
    local total_count=${#services[@]}

    for service in "${services[@]}"; do
        local name=$(echo $service | cut -d: -f1)
        local check_type=$(echo $service | cut -d: -f2)
        local check_value=$(echo $service | cut -d: -f3-)

        case $check_type in
            "http")
                if curl -s -f --max-time 10 "$check_value" >/dev/null 2>&1; then
                    print_color "green" "✓ $name: 健康"
                    healthy_count=$((healthy_count + 1))
                else
                    print_color "red" "✗ $name: 不健康"
                fi
                ;;
            "port")
                if timeout 5 bash -c "</dev/tcp/localhost/$check_value" 2>/dev/null; then
                    print_color "green" "✓ $name: 端口可达"
                    healthy_count=$((healthy_count + 1))
                else
                    print_color "red" "✗ $name: 端口不可达"
                fi
                ;;
        esac
    done

    echo
    print_color "cyan" "健康统计: $healthy_count/$total_count 服务正常"

    if [ $healthy_count -eq $total_count ]; then
        print_color "green" "🎉 所有服务运行正常！"
    else
        print_color "yellow" "⚠️  部分服务存在问题，请检查日志"
    fi
}

# 资源使用情况
resource_usage() {
    print_color "cyan" "资源使用情况:"
    echo

    # 容器资源使用
    print_color "white" "容器资源使用:"
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"
    echo

    # 磁盘使用情况
    print_color "white" "磁盘使用情况:"
    df -h | grep -E "(Filesystem|/dev/)"
    echo

    # 内存使用情况
    print_color "white" "内存使用情况:"
    free -h
    echo

    # Docker 系统信息
    print_color "white" "Docker 系统信息:"
    docker system df
    echo
}

# 日志监控
log_monitor() {
    print_color "cyan" "实时日志监控 (按 Ctrl+C 退出):"
    echo
    docker-compose -f "$COMPOSE_FILE" logs -f
}

# 主逻辑
if [ "$HEALTH_CHECK_ONLY" = true ]; then
    health_check
elif [ "$RESOURCE_USAGE" = true ]; then
    resource_usage
elif [ "$FOLLOW_LOGS" = true ]; then
    log_monitor
else
    # 完整监控
    health_check
    echo
    resource_usage
    echo

    print_color "cyan" "其他监控选项:"
    echo "  - 实时日志: $0 --logs"
    echo "  - 仅健康检查: $0 --health"
    echo "  - 资源使用情况: $0 --resources"
fi

print_color "green" "========================================"