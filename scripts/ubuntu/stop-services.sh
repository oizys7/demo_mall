#!/bin/bash

# Demo Mall 服务停止脚本 (Ubuntu)

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
print_color "green" "Demo Mall 服务停止脚本 (Ubuntu)"
print_color "green" "========================================"
echo

# 解析命令行参数
ENVIRONMENT="prod"
COMPOSE_FILE="docker/docker-compose.prod.yml"
REMOVE_VOLUMES=false
REMOVE_IMAGES=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --env|-e)
            ENVIRONMENT="$2"
            if [ "$ENVIRONMENT" = "dev" ]; then
                COMPOSE_FILE="docker/docker-compose.dev.yml"
            fi
            shift 2
            ;;
        --remove-volumes|-v)
            REMOVE_VOLUMES=true
            shift
            ;;
        --remove-images|-i)
            REMOVE_IMAGES=true
            shift
            ;;
        --help|-h)
            echo "用法: $0 [选项]"
            echo
            echo "选项:"
            echo "  -e, --env ENV            环境类型 (dev|prod, 默认: prod)"
            echo "  -v, --remove-volumes     删除数据卷"
            echo "  -i, --remove-images      删除镜像"
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

# 显示停止配置
print_color "cyan" "停止配置:"
echo "  - 环境: $ENVIRONMENT"
echo "  - 配置文件: $COMPOSE_FILE"
echo "  - 删除数据卷: $REMOVE_VOLUMES"
echo "  - 删除镜像: $REMOVE_IMAGES"
echo

# 显示停止前状态
print_color "cyan" "当前运行的容器:"
docker-compose -f "$COMPOSE_FILE" ps 2>/dev/null || echo "没有运行的服务"
echo

# 确认删除操作
if [ "$REMOVE_VOLUMES" = true ] || [ "$REMOVE_IMAGES" = true ]; then
    print_color "yellow" "⚠️  警告: 你选择了删除数据卷或镜像的操作"
    print_color "yellow" "这将导致数据丢失，请确认是否继续"
    read -p "确定要继续吗？(y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_color "green" "操作已取消"
        exit 0
    fi
fi

# 停止应用服务
print_color "yellow" "停止应用服务..."
docker-compose -f "$COMPOSE_FILE" down 2>/dev/null || true

# 停止基础设施服务
print_color "yellow" "停止基础设施服务..."
docker-compose -f docker/docker-compose.yml down 2>/dev/null || true

# 删除数据卷（如果指定）
if [ "$REMOVE_VOLUMES" = true ]; then
    print_color "yellow" "删除数据卷..."
    docker volume rm demo-mall_postgres_data demo-mall_redis_data demo-mall_es_data demo-mall_nacos_data 2>/dev/null || true

    # 删除本地数据目录
    print_color "yellow" "删除本地数据目录..."
    sudo rm -rf /var/lib/demo-mall/* 2>/dev/null || true
fi

# 删除镜像（如果指定）
if [ "$REMOVE_IMAGES" = true ]; then
    print_color "yellow" "删除相关镜像..."
    docker images "demo-mall*" --format "{{.Repository}}:{{.Tag}}" | xargs -r docker rmi -f 2>/dev/null || true
fi

# 清理未使用的资源
print_color "yellow" "清理未使用的 Docker 资源..."
docker container prune -f
docker network prune -f
docker image prune -f

echo
print_color "green" "========================================"
print_color "green" "所有服务已停止"
echo

if [ "$REMOVE_VOLUMES" = false ] && [ "$REMOVE_IMAGES" = false ]; then
    print_color "cyan" "数据卷和镜像已保留"
    echo "如需重新启动，请运行: ./scripts/ubuntu/start-services.sh"
else
    print_color "red" "数据卷或镜像已被删除"
    echo "如需重新部署，请运行: ./scripts/ubuntu/deploy.sh"
fi

print_color "green" "========================================"