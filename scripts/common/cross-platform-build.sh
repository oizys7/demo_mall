#!/bin/bash

# Demo Mall 跨平台构建脚本

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
print_color "green" "Demo Mall 跨平台构建脚本"
print_color "green" "========================================"
echo

# 解析命令行参数
APP_VERSION="1.0.0"
DOCKER_REGISTRY_PREFIX="demo-mall"
BUILD_TYPE="dev"
TARGET_PLATFORMS=""
PARALLEL_JOBS=""
SKIP_FAILED=false
VERBOSE=false

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
        --type|-t)
            BUILD_TYPE="$2"
            shift 2
            ;;
        --platforms|-p)
            TARGET_PLATFORMS="$2"
            shift 2
            ;;
        --jobs|-j)
            PARALLEL_JOBS="$2"
            shift 2
            ;;
        --skip-failed|-s)
            SKIP_FAILED=true
            shift
            ;;
        --production)
            BUILD_TYPE="prod"
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
            echo "  -t, --type TYPE          构建类型 (dev|prod, 默认: dev)"
            echo "  -p, --platforms PLATFORMS 目标平台 (默认: linux/amd64,linux/arm64)"
            echo "  -j, --jobs NUM            并行作业数 (默认: CPU核心数)"
            echo "  -s, --skip-failed         跳过失败的构建"
            echo "  --production             使用生产配置 (等同于 -t prod)"
            echo "  -V, --verbose             详细输出"
            echo "  -h, --help               显示帮助信息"
            echo
            echo "示例:"
            echo "  $0                      # 本地平台构建"
            echo "  $0 --platforms \"linux/amd64,linux/arm64,linux/arm/v7\""
            echo "  $0 --production --platforms \"linux/amd64,linux/arm64\""
            exit 0
            ;;
        *)
            print_color "red" "未知参数: $1"
            exit 1
            ;;
    esac
done

# 设置默认平台
if [ -z "$TARGET_PLATFORMS" ]; then
    TARGET_PLATFORMS="linux/amd64,linux/arm64"
fi

# 设置并行作业数
if [ -z "$PARALLEL_JOBS" ]; then
    if command -v nproc >/dev/null 2>&1; then
        PARALLEL_JOBS=$(nproc)
    elif [ "$OSTYPE" = "darwin" ]; then
        PARALLEL_JOBS=$(sysctl -n hw.ncpu | cut -d: -f2)
    else
        PARALLEL_JOBS=4
    fi
fi

# 检测 Docker 平台支持
check_docker_platform() {
    local platform=$1

    print_color "white" "检查平台支持: $platform"

    # 检查 buildx
    if ! docker buildx version >/dev/null 2>&1; then
        print_color "red" "错误: Docker Buildx 未安装或不支持"
        return 1
    fi

    # 创建 builder（如果不存在）
    local builder_name="demo-mall-builder"
    if ! docker buildx ls | grep -q "$builder_name"; then
        print_color "yellow" "创建 Docker Buildx builder: $builder_name"
        docker buildx create --name "$builder_name" --driver docker-container --use
        docker buildx use "$builder_name"
    fi

    return 0
}

# 构建单个服务镜像
build_service_image() {
    local service=$1
    local platform=$2
    local dockerfile="demo-mall-$service/Dockerfile.$BUILD_TYPE"

    if [ ! -f "$dockerfile" ]; then
        print_color "red" "错误: Dockerfile 不存在: $dockerfile"
        return 1
    fi

    local start_time=$(date +%s)
    local image_name="$DOCKER_REGISTRY_PREFIX/$service:$BUILD_TYPE"
    local platform_tag="${image_name}-${platform//\//-}"

    print_color "yellow" "构建 $service 服务 ($platform)..."

    if [ "$VERBOSE" = true ]; then
        echo "构建命令: docker buildx build --platform=$platform -t $platform_tag -f $dockerfile demo-mall-$service/"
    fi

    # 执行构建
    if docker buildx build \
        --platform="$platform" \
        -t "$platform_tag" \
        -f "$dockerfile" \
        --build-arg "APP_VERSION=$APP_VERSION" \
        --build-arg "TARGETPLATFORM=$platform" \
        "demo-mall-$service/"; then

        local end_time=$(date +%s)
        local duration=$((end_time - start_time))

        print_color "green" "✓ $service ($platform): 构建成功 (耗时: ${duration}s)"

        # 获取镜像大小
        local image_size=$(docker images --format "{{.Size}}" "$platform_tag" 2>/dev/null || echo "Unknown")
        echo "  镜像大小: $image_size"

        return 0
    else
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))

        print_color "red" "✗ $service ($platform): 构建失败 (耗时: ${duration}s)"

        if [ "$VERBOSE" = true ]; then
            echo "查看错误日志: docker buildx build --platform=$platform $platform_tag"
        fi

        return 1
    fi
}

# 并行构建服务
parallel_build() {
    local platforms=($TARGET_PLATFORMS)
    local services=(gateway user product order)

    print_color "cyan" "开始并行构建..."
    print_color "white" "目标平台: ${platforms[*]}"
    print_color "white" "并行作业数: $PARALLEL_JOBS"
    print_color "white" "服务数量: ${#services[@]}"
    echo

    # 使用 xargs 并行构建
    {
        for platform in "${platforms[@]}"; do
            for service in "${services[@]}; do
                echo "$platform $service"
            done
        done
    } | xargs -P "$PARALLEL_JOBS" -I {} bash -c '
        platform={} read service
        build_service_image "$service" "$platform"
    '
}

# 串行构建服务
sequential_build() {
    local platforms=($TARGET_PLATFORMS)
    local services=(gateway user product order)

    print_color "cyan" "开始串行构建..."
    print_color "white" "目标平台: ${platforms[*]}"
    print_color "white" "服务数量: ${#services[@]}"
    echo

    for platform in "${platforms[@]}"; do
        print_color "white" "构建平台: $platform"
        for service in "${services[@]}; do
            build_service_image "$service" "$platform"
            if [ $? -ne 0 ] && [ "$SKIP_FAILED" = false ]; then
                print_color "red" "构建失败，停止执行"
                exit 1
            fi
        done
        echo
    done
}

# 构建结果统计
build_statistics() {
    local platforms=($TARGET_PLATFORMS)
    local services=(gateway user product order)
    local total_builds=$((${#platforms[@]} * ${#services[@]}))
    local successful_builds=0
    local failed_builds=0

    print_color "cyan" "构建统计:"
    echo

    for platform in "${platforms[@]}"; do
        local platform_success=0
        local platform_total=${#services[@]}

        print_color "white" "平台: $platform"
        for service in "${services[@]}"; do
            local platform_tag="${DOCKER_REGISTRY_PREFIX}/${service}:${BUILD_TYPE}-${platform//\//-}"
            if docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^${platform_tag}$"; then
                print_color "green" "  ✓ $service"
                platform_success=$((platform_success + 1))
                successful_builds=$((successful_builds + 1))
            else
                print_color "red" "  ✗ $service"
                failed_builds=$((failed_builds + 1))
            fi
        done

        local success_rate=$((platform_success * 100 / platform_total))
        echo "  成功率: $success_rate% ($platform_success/$platform_total)"
        echo
    done

    print_color "cyan" "总体统计:"
    echo "  - 计划构建: $total_builds"
    echo "  - 成功构建: $successful_builds"
    echo "  - 失败构建: $failed_builds"
    echo "  - 成功率: $((successful_builds * 100 / total_builds))%"
    echo

    if [ $successful_builds -eq $total_builds ]; then
        print_color "green" "🎉 所有构建成功！"
    elif [ $successful_builds -gt 0 ]; then
        print_color "yellow" "⚠️  部分构建成功"
    else
        print_color "red" "❌ 所有构建失败"
    fi
}

# 主函数
main() {
    print_color "cyan" "构建配置:"
    echo "  - 应用版本: $APP_VERSION"
    echo "  - 镜像前缀: $DOCKER_REGISTRY_PREFIX"
    echo "  - 构建类型: $BUILD_TYPE"
    echo "  - 目标平台: $TARGET_PLATFORMS"
    echo "  - 并行作业: $PARALLEL_JOBS"
    echo "  - 跳过失败: $SKIP_FAILED"
    echo "  - 详细输出: $VERBOSE"
    echo

    # 检查 Docker 环境
    if ! docker info >/dev/null 2>&1; then
        print_color "red" "错误: Docker 未运行"
        exit 1
    fi

    # 检查平台支持
    for platform in ${TARGET_PLATFORMS//,/ }; do
        if ! check_docker_platform "$platform"; then
            print_color "red" "错误: 平台 $platform 不支持"
            exit 1
        fi
    done

    echo
    print_color "green" "平台支持检查通过"
    echo

    # 开始构建
    local start_time=$(date +%s)

    if [ "$PARALLEL_JOBS" -gt 1 ]; then
        parallel_build
    else
        sequential_build
    fi

    local end_time=$(date +%s)
    local total_duration=$((end_time - start_time))

    print_color "cyan" "总构建时间: ${total_duration}s"
    echo

    # 统计结果
    build_statistics

    # 显示构建的镜像
    echo
    print_color "cyan" "构建的镜像:"
    docker images "$DOCKER_REGISTRY_PREFIX" --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"

    print_color "green" "========================================"
}

# 执行主函数
main