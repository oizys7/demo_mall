#!/bin/bash

# Demo Mall 系统清理脚本 (Ubuntu)

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
print_color "green" "Demo Mall 系统清理脚本 (Ubuntu)"
print_color "green" "========================================"
echo

# 解析命令行参数
DEEP_CLEAN=false
REMOVE_IMAGES=false
REMOVE_VOLUMES=false
REMOVE_LOGS=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --deep|-d)
            DEEP_CLEAN=true
            shift
            ;;
        --images|-i)
            REMOVE_IMAGES=true
            shift
            ;;
        --volumes|-v)
            REMOVE_VOLUMES=true
            shift
            ;;
        --logs|-l)
            REMOVE_LOGS=true
            shift
            ;;
        --dry-run|-n)
            DRY_RUN=true
            shift
            ;;
        --all|-a)
            DEEP_CLEAN=true
            REMOVE_IMAGES=true
            REMOVE_VOLUMES=true
            REMOVE_LOGS=true
            shift
            ;;
        --help|-h)
            echo "用法: $0 [选项]"
            echo
            echo "选项:"
            echo "  -d, --deep               深度清理 (停止所有容器)"
            echo "  -i, --images             删除相关镜像"
            echo "  -v, --volumes            删除数据卷"
            echo "  -l, --logs               删除日志文件"
            echo "  -n, --dry-run             仅显示将要执行的操作"
            echo "  -a, --all                执行所有清理操作"
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

# 显示清理配置
print_color "cyan" "清理配置:"
echo "  - 深度清理: $DEEP_CLEAN"
echo "  - 删除镜像: $REMOVE_IMAGES"
echo "  - 删除数据卷: $REMOVE_VOLUMES"
echo "  - 删除日志: $REMOVE_LOGS"
echo "  - 试运行模式: $DRY_RUN"
echo

# 显示当前状态
print_color "cyan" "当前 Docker 状态:"
echo
print_color "white" "运行的容器:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(demo-mall|CONTAINER)" || print_color "yellow" "没有运行的相关容器"
echo

print_color "white" "相关镜像:"
docker images "demo-mall*" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}" || print_color "yellow" "没有相关镜像"
echo

print_color "white" "数据卷:"
docker volume ls | grep "demo-mall" || print_color "yellow" "没有相关数据卷"
echo

# 显示将要执行的操作
print_color "yellow" "将要执行的操作:"
echo

if [ "$DEEP_CLEAN" = true ]; then
    print_color "white" "  • 停止所有 Demo Mall 容器"
fi

if [ "$REMOVE_IMAGES" = true ]; then
    print_color "white" "  • 删除所有 Demo Mall 镜像"
fi

if [ "$REMOVE_VOLUMES" = true ]; then
    print_color "white" "  • 删除所有 Demo Mall 数据卷"
fi

if [ "$REMOVE_LOGS" = true ]; then
    print_color "white" "  • 删除日志文件"
fi

print_color "white" "  • 清理未使用的容器、网络和镜像"
echo

# 确认操作
if [ "$DRY_RUN" = false ]; then
    print_color "yellow" "⚠️  警告: 此操作将删除 Docker 资源"
    print_color "yellow" "请确认是否继续"
    read -p "确定要继续吗？(y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_color "green" "操作已取消"
        exit 0
    fi
else
    print_color "cyan" "试运行模式 - 不会执行实际操作"
    echo
fi

# 执行清理操作
cleanup_command() {
    echo "$1"
    if [ "$DRY_RUN" = false ]; then
        eval "$1"
    fi
}

# 停止容器
if [ "$DEEP_CLEAN" = true ]; then
    print_color "yellow" "停止所有 Demo Mall 容器..."
    cleanup_command "docker-compose -f docker/docker-compose.dev.yml down 2>/dev/null || true"
    cleanup_command "docker-compose -f docker/docker-compose.prod.yml down 2>/dev/null || true"
    cleanup_command "docker-compose -f docker/docker-compose.yml down 2>/dev/null || true"

    # 停止单个容器
    DEMO_CONTAINERS=$(docker ps -q --filter "name=demo-mall" 2>/dev/null || true)
    if [ -n "$DEMO_CONTAINERS" ]; then
        cleanup_command "docker stop $DEMO_CONTAINERS 2>/dev/null || true"
        cleanup_command "docker rm $DEMO_CONTAINERS 2>/dev/null || true"
    fi
    echo
fi

# 删除镜像
if [ "$REMOVE_IMAGES" = true ]; then
    print_color "yellow" "删除 Demo Mall 镜像..."
    DEMO_IMAGES=$(docker images "demo-mall*" --format "{{.Repository}}:{{.Tag}}" 2>/dev/null || true)
    if [ -n "$DEMO_IMAGES" ]; then
        echo "$DEMO_IMAGES" | xargs -r cleanup_command "docker rmi -f 2>/dev/null || true"
    fi
    echo
fi

# 删除数据卷
if [ "$REMOVE_VOLUMES" = true ]; then
    print_color "yellow" "删除 Demo Mall 数据卷..."
    DEMO_VOLUMES=$(docker volume ls -q --filter "name=demo-mall" 2>/dev/null || true)
    if [ -n "$DEMO_VOLUMES" ]; then
        echo "$DEMO_VOLUMES" | xargs -r cleanup_command "docker volume rm -f 2>/dev/null || true"
    fi

    # 删除本地数据目录
    if [ "$DRY_RUN" = false ]; then
        print_color "white" "删除本地数据目录..."
        if [ -d "/var/lib/demo-mall" ]; then
            cleanup_command "sudo rm -rf /var/lib/demo-mall/* 2>/dev/null || true"
        fi
        if [ -d "/var/log/demo-mall" ]; then
            cleanup_command "sudo rm -rf /var/log/demo-mall/* 2>/dev/null || true"
        fi
    fi
    echo
fi

# 删除日志文件
if [ "$REMOVE_LOGS" = true ]; then
    print_color "yellow" "删除日志文件..."
    cleanup_command "sudo find /var/lib/docker/containers/ -name '*demo-mall*.log' -delete 2>/dev/null || true"
    cleanup_command "sudo find /var/lib/docker/containers/ -name '*demo-mall*.log.*' -delete 2>/dev/null || true"
    echo
fi

# 通用清理
print_color "yellow" "清理未使用的 Docker 资源..."
cleanup_command "docker container prune -f"
cleanup_command "docker network prune -f"
cleanup_command "docker image prune -f"

if [ "$DRY_RUN" = false ]; then
    # 清理系统缓存
    print_color "white" "清理系统缓存..."
    cleanup_command "sudo sync && sudo echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true"
fi

echo

# 显示清理结果
if [ "$DRY_RUN" = false ]; then
    print_color "green" "========================================"
    print_color "green" "清理完成！"
    echo

    print_color "cyan" "清理后状态:"
    echo
    print_color "white" "运行的容器:"
    docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "(demo-mall|CONTAINER)" || print_color "green" "✓ 没有运行的相关容器"
    echo

    print_color "white" "相关镜像:"
    docker images "demo-mall*" --format "table {{.Repository}}\t{{.Tag}}" 2>/dev/null || print_color "green" "✓ 没有相关镜像"
    echo

    print_color "white" "数据卷:"
    docker volume ls | grep "demo-mall" || print_color "green" "✓ 没有相关数据卷"
    echo

    print_color "white" "Docker 系统空间使用:"
    docker system df
    echo

    print_color "cyan" "重新部署建议:"
    echo "  • 完全重新部署: ./scripts/ubuntu/deploy.sh"
    echo "  • 仅启动服务: ./scripts/ubuntu/start-services.sh"
    echo "  • 构建镜像: ./scripts/ubuntu/build-images.sh"
else
    print_color "cyan" "试运行完成"
    echo "移除 --dry-run 参数执行实际清理操作"
fi

print_color "green" "========================================"