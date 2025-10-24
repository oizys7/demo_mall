#!/bin/bash

# Demo Mall 健康检查脚本

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
print_color "green" "Demo Mall 健康检查脚本"
print_color "green" "========================================"
echo

# 解析命令行参数
ENVIRONMENT="prod"
COMPOSE_FILE="docker/docker-compose.prod.yml"
CONTINUOUS=false
OUTPUT_FORMAT="table"
TIMEOUT=30

while [[ $# -gt 0 ]]; do
    case $1 in
        --env|-e)
            ENVIRONMENT="$2"
            if [ "$ENVIRONMENT" = "dev" ]; then
                COMPOSE_FILE="docker/docker-compose.dev.yml"
            fi
            shift 2
            ;;
        --continuous|-c)
            CONTINUOUS=true
            shift
            ;;
        --timeout|-t)
            TIMEOUT="$2"
            shift 2
            ;;
        --json|-j)
            OUTPUT_FORMAT="json"
            shift
            ;;
        --help|-h)
            echo "用法: $0 [选项]"
            echo
            echo "选项:"
            echo "  -e, --env ENV            环境类型 (dev|prod, 默认: prod)"
            echo "  -c, --continuous         连续监控模式"
            echo "  -t, --timeout SECONDS    超时时间 (默认: 30秒)"
            echo "  -j, --json               JSON 格式输出"
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
    print_color "red" "错误: Docker 未运行"
    exit 1
fi

# 服务配置
declare -A SERVICES=(
    ["nacos"]="Nacos Service Registry:http://localhost:8848/nacos/"
    ["gateway"]="API Gateway:http://localhost:9100/actuator/health"
    ["user"]="User Service:http://localhost:9201/actuator/health"
    ["product"]="Product Service:http://localhost:9202/actuator/health"
    ["order"]="Order Service:http://localhost:9203/actuator/health"
    ["postgres"]="PostgreSQL Database:port:5432"
    ["redis"]="Redis Cache:port:6379"
    ["elasticsearch"]="Elasticsearch:http://localhost:9200/_cluster/health"
)

# 容器映射
declare -A CONTAINERS=(
    ["nacos"]="demo-mall-nacos"
    ["gateway"]="demo-mall-gateway"
    ["user"]="demo-mall-user"
    ["product"]="demo-mall-product"
    ["order"]="demo-mall-order"
    ["postgres"]="demo-mall-postgres"
    ["redis"]="demo-mall-redis"
    ["elasticsearch"]="demo-mall-elasticsearch"
)

# 检查函数
check_service() {
    local service_name=$1
    local service_desc=$2
    local check_url=$3

    # 检查容器是否运行
    local container_name=${CONTAINERS[$service_name]}
    if [ -n "$container_name" ]; then
        if docker ps --format "{{.Names}}" | grep -q "^${container_name}$"; then
            container_status="running"
        else
            container_status="stopped"
        fi
    else
        container_status="unknown"
    fi

    # 检查服务健康状态
    local health_status="unhealthy"
    local response_time="timeout"
    local start_time=$(date +%s%3N)

    case $check_url in
        port:*)
            local port=$(echo $check_url | cut -d: -f2)
            if timeout $TIMEOUT bash -c "</dev/tcp/localhost/$port" 2>/dev/null; then
                health_status="healthy"
                end_time=$(date +%s%3N)
                response_time=$((end_time - start_time))ms
            fi
            ;;
        http:*)
            if command -v curl >/dev/null 2>&1; then
                local response_code=$(curl -s -w "%{http_code}" -o /dev/null --max-time $TIMEOUT "$check_url" 2>/dev/null)
                if [ "$response_code" = "200" ]; then
                    health_status="healthy"
                    end_time=$(date +%s%3N)
                    response_time=$((end_time - start_time))ms
                else
                    health_status="http_$response_code"
                fi
            else
                health_status="curl_missing"
            fi
            ;;
        *)
            health_status="invalid_check"
            ;;
    esac

    # 返回结果
    echo "$service_name|$service_desc|$container_status|$health_status|$response_time"
}

# 输出表格格式的结果
output_table() {
    local results=("$@")

    print_color "cyan" "健康检查结果 ($ENVIRONMENT 环境):"
    echo
    printf "%-12s %-20s %-10s %-12s %-10s\n" "服务" "描述" "容器状态" "健康状态" "响应时间"
    printf "%-12s %-20s %-10s %-12s %-10s\n" "----" "----" "--------" "--------" "--------"

    local healthy_count=0
    local total_count=${#results[@]}

    for result in "${results[@]}"; do
        IFS='|' read -r name desc container health response <<< "$result"

        # 确定健康状态颜色
        local status_color="white"
        if [ "$health" = "healthy" ]; then
            status_color="green"
            healthy_count=$((healthy_count + 1))
        elif [[ "$health" =~ ^http_[45] ]]; then
            status_color="red"
        elif [ "$health" = "timeout" ]; then
            status_color="yellow"
        else
            status_color="red"
        fi

        # 确定容器状态颜色
        local container_color="white"
        if [ "$container" = "running" ]; then
            container_color="green"
        elif [ "$container" = "stopped" ]; then
            container_color="red"
        else
            container_color="yellow"
        fi

        printf "%-12s %-20s " "$name" "$desc"
        print_color "$container_color" "%-10s" "$container"
        printf " "
        print_color "$status_color" "%-12s" "$health"
        printf "%-10s\n" "$response"
    done

    echo
    print_color "cyan" "健康统计: $healthy_count/$total_count 服务正常"

    if [ $healthy_count -eq $total_count ]; then
        print_color "green" "🎉 所有服务运行正常！"
    elif [ $healthy_count -gt 0 ]; then
        print_color "yellow" "⚠️  部分服务存在问题"
    else
        print_color "red" "❌ 所有服务都存在问题"
    fi
}

# 输出 JSON 格式的结果
output_json() {
    local results=("$@")
    local healthy_count=0
    local total_count=${#results[@]}

    # 计算健康服务数量
    for result in "${results[@]}"; do
        IFS='|' read -r name desc container health response <<< "$result"
        if [ "$health" = "healthy" ]; then
            healthy_count=$((healthy_count + 1))
        fi
    done

    # 生成 JSON 输出
    echo "{"
    echo "  \"timestamp\": \"$(date -Iseconds)\","
    echo "  \"environment\": \"$ENVIRONMENT\","
    echo "  \"total_services\": $total_count,"
    echo "  \"healthy_services\": $healthy_count,"
    echo "  \"services\": ["

    local first=true
    for result in "${results[@]}"; do
        IFS='|' read -r name desc container health response <<< "$result"
        if [ "$first" = false ]; then
            echo ","
        fi
        first=false
        echo "    {"
        echo "      \"name\": \"$name\","
        echo "      \"description\": \"$desc\","
        echo "      \"container_status\": \"$container\","
        echo "      \"health_status\": \"$health\","
        echo "      \"response_time_ms\": \"$response\""
        echo -n "    }"
    done

    echo ""
    echo "  ],"
    echo "  \"summary\": {"
    echo "    \"status\": \"$([ $healthy_count -eq $total_count ] && echo "healthy" || echo "unhealthy")\","
    echo "    \"message\": \"$([ $healthy_count -eq $total_count ] && echo "All services are healthy" || echo "$healthy_count out of $total_count services are healthy")\""
    echo "  }"
    echo "}"
}

# 连续监控模式
continuous_monitoring() {
    print_color "cyan" "启动连续监控模式 (按 Ctrl+C 停止)..."
    echo

    while true; do
        clear
        print_color "green" "========================================"
        print_color "green" "Demo Mall 实时健康监控"
        print_color "green" "========================================"
        echo
        print_color "white" "检查时间: $(date)"
        print_color "white" "环境: $ENVIRONMENT"
        echo

        # 执行检查
        local results=()
        for service in "${!SERVICES[@]}"; do
            results+=("$(check_service "$service" "${SERVICES[$service]}")")
        done

        # 输出结果
        output_table "${results[@]}"

        print_color "cyan" "下次检查: $(date --date='+%Y-%m-%d %H:%M:%S' --date='+30 seconds')"
        echo

        sleep 30
    done
}

# 单次检查模式
single_check() {
    print_color "white" "检查时间: $(date)"
    print_color "white" "环境: $ENVIRONMENT"
    print_color "white" "超时时间: ${TIMEOUT}秒"
    echo

    # 执行检查
    local results=()
    for service in "${!SERVICES[@]}"; do
        results+=("$(check_service "$service" "${SERVICES[$service]}")")
    done

    # 输出结果
    if [ "$OUTPUT_FORMAT" = "json" ]; then
        output_json "${results[@]}"
    else
        output_table "${results[@]}"
    fi

    # 如果有健康问题，显示建议
    local healthy_count=0
    local total_count=${#results[@]}

    for result in "${results[@]}"; do
        IFS='|' read -r name desc container health response <<< "$result"
        if [ "$health" = "healthy" ]; then
            healthy_count=$((healthy_count + 1))
        fi
    done

    if [ $healthy_count -lt $total_count ]; then
        echo
        print_color "yellow" "故障排除建议:"
        echo "1. 检查容器日志: docker logs [container_name]"
        echo "2. 重启服务: docker-compose -f $COMPOSE_FILE restart [service_name]"
        echo "3. 查看详细状态: docker-compose -f $COMPOSE_FILE ps"
        echo "4. 检查资源使用: docker stats"
    fi
}

# 执行检查
if [ "$CONTINUOUS" = true ]; then
    continuous_monitoring
else
    single_check
fi

print_color "green" "========================================"