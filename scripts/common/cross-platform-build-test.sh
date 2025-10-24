#!/bin/bash

# Demo Mall 跨平台构建脚本 - 测试版本

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

# 解析命令行参数
APP_VERSION="1.0.0"
DOCKER_REGISTRY_PREFIX="demo-mall"
BUILD_TYPE="dev"
TARGET_PLATFORMS="linux/amd64,linux/arm64"
PARALLEL_JOBS="4"
VERBOSE=false
SKIP_FAILED=false

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

# 检查 Docker 环境
if ! docker info >/dev/null 2>&1; then
    print_color "red" "错误: Docker 未运行"
    exit 1
fi

# 模拟构建功能
print_color "green" "========================================"
print_color "green" "Demo Mall 跨平台构建脚本 (测试版)"
print_color "green" "========================================"
echo

print_color "cyan" "构建配置:"
echo "  - 应用版本: $APP_VERSION"
echo "  - 镜像前缀: $DOCKER_REGISTRY_PREFIX"
echo "  - 构建类型: $BUILD_TYPE"
echo "  - 目标平台: $TARGET_PLATFORMS"
echo "  - 并行作业: $PARALLEL_JOBS"
echo "  - 跳过失败: $SKIP_FAILED"
echo "  - 详细输出: $VERBOSE"
echo

# 模拟构建过程
services=(gateway user product order)
platforms=(${TARGET_PLATFORMS//,/ })

print_color "cyan" "开始模拟构建..."
print_color "white" "目标平台: ${platforms[*]}"
print_color "white" "服务数量: ${#services[@]}"
echo

for platform in "${platforms[@]}"; do
    print_color "white" "构建平台: $platform"
    for service in "${services[@]}"; do
        image_name="$DOCKER_REGISTRY_PREFIX/$service:$BUILD_TYPE"
        platform_tag="${image_name}-${platform//\//-}"

        if [ "$VERBOSE" = true ]; then
            echo "构建命令: docker buildx build --platform=$platform -t $platform_tag -f Dockerfile.$BUILD_TYPE demo-mall-$service/"
        fi

        # 模拟构建过程
        print_color "yellow" "  构建 $service 服务 ($platform)..."
        sleep 0.5
        print_color "green" "  ✓ $service ($platform): 构建成功 (模拟)"
    done
    echo
done

print_color "green" "🎉 所有构建模拟完成！"
print_color "green" "========================================"