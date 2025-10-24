#!/bin/bash

# Demo Mall Docker 镜像构建脚本 (Ubuntu)
# 支持并行构建和详细日志

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
print_color "green" "Demo Mall Docker 镜像构建脚本 (Ubuntu)"
print_color "green" "========================================"
echo

# 解析命令行参数
APP_VERSION="1.0.0"
DOCKER_REGISTRY_PREFIX="demo-mall"
BUILD_TYPE="dev"
PARALLEL=false
CLEAN=false
VERBOSE=false
PRODUCTION=false

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
        --production|-p)
            PRODUCTION=true
            BUILD_TYPE="prod"
            shift
            ;;
        --parallel|-P)
            PARALLEL=true
            shift
            ;;
        --clean|-c)
            CLEAN=true
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
            echo "  -p, --production         构建生产环境镜像"
            echo "  -P, --parallel           并行构建"
            echo "  -c, --clean              构建前清理旧镜像"
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

# 检查 Docker 是否运行
print_color "yellow" "检查 Docker 状态..."
if ! docker info >/dev/null 2>&1; then
    print_color "red" "错误: Docker 未运行，请先启动 Docker 服务"
    exit 1
fi

DOCKER_VERSION=$(docker version --format '{{.Server.Version}}' 2>/dev/null)
print_color "green" "Docker 正在运行，版本: $DOCKER_VERSION"
echo

# 清理旧镜像（如果指定）
if [ "$CLEAN" = true ]; then
    print_color "yellow" "清理旧镜像..."
    OLD_IMAGES=$(docker images "$DOCKER_REGISTRY_PREFIX" --format '{{.Repository}}:{{.Tag}}' 2>/dev/null || true)
    if [ -n "$OLD_IMAGES" ]; then
        echo "$OLD_IMAGES" | xargs -r docker rmi 2>/dev/null || true
    fi
    echo
fi

# 设置服务列表
declare -A SERVICES=(
    ["gateway"]="9100"
    ["user"]="9201"
    ["product"]="9202"
    ["order"]="9203"
)

# 显示构建配置
print_color "cyan" "构建配置:"
echo "  - 应用版本: $APP_VERSION"
echo "  - 镜像前缀: $DOCKER_REGISTRY_PREFIX"
echo "  - 构建类型: $BUILD_TYPE"
echo "  - 并行构建: $PARALLEL"
echo "  - 详细输出: $VERBOSE"
echo

# 构建函数
build_service_image() {
    local service_name=$1
    local port=$2
    local start_time=$(date +%s)

    print_color "yellow" "开始构建 $service_name 服务镜像..."

    if [ "$VERBOSE" = true ]; then
        echo "构建命令: docker build -f demo-mall-$service_name/Dockerfile.$BUILD_TYPE -t $DOCKER_REGISTRY_PREFIX/$service_name:$BUILD_TYPE --build-arg APP_VERSION=$APP_VERSION demo-mall-$service_name/"
    fi

    local build_output
    if build_output=$(docker build -f "demo-mall-$service_name/Dockerfile.$BUILD_TYPE" \
            -t "$DOCKER_REGISTRY_PREFIX/$service_name:$BUILD_TYPE" \
            --build-arg "APP_VERSION=$APP_VERSION" \
            "demo-mall-$service_name/" 2>&1); then

        local end_time=$(date +%s)
        local duration=$((end_time - start_time))

        print_color "green" "$service_name 镜像构建成功 (耗时: ${duration}s)"

        # 获取镜像大小
        local image_size=$(docker images "$DOCKER_REGISTRY_PREFIX/$service_name:$BUILD_TYPE" --format '{{.Size}}' 2>/dev/null || echo "Unknown")
        echo "  镜像大小: $image_size"

        # 返回构建结果
        echo "SUCCESS:$service_name:$duration:$image_size"
    else
        print_color "red" "$service_name 镜像构建失败"
        if [ "$VERBOSE" = true ]; then
            echo "构建错误信息:"
            echo "$build_output" >&2
        fi
        echo "FAILED:$service_name:$build_output"
        return 1
    fi
}

# 开始构建
print_color "cyan" "开始构建镜像..."
echo

# 构建结果数组
BUILD_RESULTS=()

if [ "$PARALLEL" = true ]; then
    print_color "yellow" "使用并行构建..."

    # 启动并行构建
    PIDS=()
    for service in "${!SERVICES[@]}"; do
        port=${SERVICES[$service]}
        (
            result=$(build_service_image "$service" "$port")
            echo "$result"
        ) &
        PIDS+=($!)
    done

    # 等待所有构建完成
    for pid in "${PIDS[@]}"; do
        wait $pid
    done
else
    print_color "yellow" "使用串行构建..."
    for service in "${!SERVICES[@]}"; do
        port=${SERVICES[$service]}
        result=$(build_service_image "$service" "$port")
        BUILD_RESULTS+=("$result")
    done
fi

# 显示构建结果
echo
print_color "green" "========================================"
print_color "green" "构建结果汇总"
print_color "green" "========================================"

SUCCESS_COUNT=0
FAILURE_COUNT=0
TOTAL_DURATION=0

# 统计构建结果
for service in "${!SERVICES[@]}"; do
    image="$DOCKER_REGISTRY_PREFIX/$service:$BUILD_TYPE"
    if docker images --format '{{.Repository}}:{{.Tag}}' | grep -q "^$image$"; then
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        size=$(docker images "$image" --format '{{.Size}}')
        print_color "green" "✓ $service: $size"
    else
        FAILURE_COUNT=$((FAILURE_COUNT + 1))
        print_color "red" "✗ $service: 构建失败"
    fi
done

echo
print_color "cyan" "统计信息:"
echo "  - 成功: $SUCCESS_COUNT"
echo "  - 失败: $FAILURE_COUNT"

if [ $SUCCESS_COUNT -gt 0 ]; then
    echo
    print_color "cyan" "构建的镜像列表:"
    docker images "$DOCKER_REGISTRY_PREFIX" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
fi

echo
if [ $FAILURE_COUNT -eq 0 ]; then
    print_color "green" "所有镜像构建成功！可以使用 start-services.sh 启动服务。"
else
    print_color "red" "部分镜像构建失败，请检查错误信息。"
fi

print_color "green" "========================================"

# 返回适当的退出码
if [ $FAILURE_COUNT -gt 0 ]; then
    exit 1
else
    exit 0
fi