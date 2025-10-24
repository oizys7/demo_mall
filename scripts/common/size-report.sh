#!/bin/bash

# Demo Mall Docker 镜像大小分析报告脚本

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
print_color "green" "Demo Mall Docker 镜像大小分析报告"
print_color "green" "========================================"
echo

# 解析命令行参数
REGISTRY_PREFIX="demo-mall"
COMPARE_BASELINE=false
EXPORT_CSV=false
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --registry|-r)
            REGISTRY_PREFIX="$2"
            shift 2
            ;;
        --compare|-c)
            COMPARE_BASELINE=true
            shift
            ;;
        --csv|-e)
            EXPORT_CSV=true
            shift
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --help|-h)
            echo "用法: $0 [选项]"
            echo
            echo "选项:"
            echo "  -r, --registry PREFIX    镜像前缀 (默认: demo-mall)"
            echo "  -c, --compare            与基线版本比较"
            echo "  -e, --csv                导出 CSV 报告"
            echo "  -v, --verbose            详细输出"
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

# 函数：转换大小为 MB
convert_size_to_mb() {
    local size=$1
    if [[ $size =~ ([0-9.]+)(KB|MB|GB) ]]; then
        local value=${BASH_REMATCH[1]}
        local unit=${BASH_REMATCH[2]}

        case $unit in
            "KB") echo "scale=2; $value / 1024" | bc ;;
            "MB") echo "$value" ;;
            "GB") echo "scale=2; $value * 1024" | bc ;;
            *) echo "0" ;;
        esac
    else
        echo "0"
    fi
}

# 函数：格式化大小
format_size() {
    local size_mb=$1
    if (( $(echo "$size_mb < 1" | bc -l) )); then
        echo "0 MB"
    elif (( $(echo "$size_mb < 1024" | bc -l) )); then
        echo "scale=1; $size_mb" | bc | sed 's/\.0$//' | sed 's/$/ MB/'
    else
        echo "scale=2; $size_mb / 1024" | bc | sed 's/\.0$//' | sed 's/$/ GB/'
    fi
}

# 收集镜像信息
collect_image_info() {
    local images=$(docker images "$REGISTRY_PREFIX" --format "{{.Repository}}:{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}" 2>/dev/null)

    if [ -z "$images" ]; then
        print_color "yellow" "没有找到匹配的镜像: $REGISTRY_PREFIX"
        return 1
    fi

    echo "$images" | while IFS=$'\t' read -r repo_tag size created_at; do
        local name=$(echo "$repo_tag" | cut -d: -f2)
        local tag=$(echo "$repo_tag" | cut -d: -f3)
        local size_mb=$(convert_size_to_mb "$size")

        echo "$name,$tag,$size,$size_mb,$created_at"
    done
}

# 计算统计信息
calculate_statistics() {
    local total_size_mb=0
    local image_count=0
    local largest_size_mb=0
    local largest_image=""
    local smallest_size_mb=999999
    local smallest_image=""

    while IFS=',' read -r name tag size size_mb created_at; do
        if [ -n "$name" ]; then
            total_size_mb=$(echo "$total_size_mb + $size_mb" | bc)
            image_count=$((image_count + 1))

            # 查找最大镜像
            if (( $(echo "$size_mb > $largest_size_mb" | bc -l) )); then
                largest_size_mb=$size_mb
                largest_image="$name:$tag"
            fi

            # 查找最小镜像
            if (( $(echo "$size_mb < $smallest_size_mb" | bc -l) )); then
                smallest_size_mb=$size_mb
                smallest_image="$name:$tag"
            fi
        fi
    done

    echo "$image_count,$total_size_mb,$largest_image,$largest_size_mb,$smallest_image,$smallest_size_mb"
}

# 生成报告标题
print_color "cyan" "镜像信息汇总:"
echo

# 收集并显示镜像信息
echo "收集镜像信息..."
IMAGE_DATA=$(collect_image_info)

if [ -z "$IMAGE_DATA" ]; then
    print_color "red" "没有找到可分析的镜像"
    exit 1
fi

# 显示详细镜像信息
print_color "white" "镜像详情:"
echo "名称              版本     大小      创建时间"
echo "---------------------------------------------"

echo "$IMAGE_DATA" | while IFS=',' read -r name tag size size_mb created_at; do
    printf "%-16s %-8s %-8s %s\n" "$name" "$tag" "$size" "$created_at"
done

echo

# 计算统计信息
STATS=$(calculate_statistics <<< "$IMAGE_DATA")
IMAGE_COUNT=$(echo "$STATS" | cut -d, -f1)
TOTAL_SIZE_MB=$(echo "$STATS" | cut -d, -f2)
LARGEST_IMAGE=$(echo "$STATS" | cut -d, -f3)
LARGEST_SIZE_MB=$(echo "$STATS" | cut -d, -f4)
SMALLEST_IMAGE=$(echo "$STATS" | cut -d, -f5)
SMALLEST_SIZE_MB=$(echo "$STATS" | cut -d, -f6)

# 显示统计信息
print_color "cyan" "统计信息:"
echo "镜像总数: $IMAGE_COUNT"
echo "总大小: $(format_size $TOTAL_SIZE_MB)"
echo "最大镜像: $LARGEST_IMAGE ($(format_size $LARGEST_SIZE_MB))"
echo "最小镜像: $SMALLEST_IMAGE ($(format_size $SMALLEST_SIZE_MB))"
echo

# 计算平均大小
if [ "$IMAGE_COUNT" -gt 0 ]; then
    AVG_SIZE_MB=$(echo "scale=2; $TOTAL_SIZE_MB / $IMAGE_COUNT" | bc)
    echo "平均大小: $(format_size $AVG_SIZE_MB)"
fi

echo

# 大小分布分析
print_color "cyan" "大小分布分析:"
echo

# 定义大小分类
declare -A size_categories=(
    ["small"]="< 100MB"
    ["medium"]="100MB - 200MB"
    ["large"]="200MB - 500MB"
    ["xlarge"]="> 500MB"
)

declare -A size_counts
size_counts["small"]=0
size_counts["medium"]=0
size_counts["large"]=0
size_counts["xlarge"]=0

echo "$IMAGE_DATA" | while IFS=',' read -r name tag size size_mb created_at; do
    if (( $(echo "$size_mb < 100" | bc -l) )); then
        size_counts["small"]=$((${size_counts["small"]} + 1))
    elif (( $(echo "$size_mb < 200" | bc -l) )); then
        size_counts["medium"]=$((${size_counts["medium"]} + 1))
    elif (( $(echo "$size_mb < 500" | bc -l) )); then
        size_counts["large"]=$((${size_counts["large"]} + 1))
    else
        size_counts["xlarge"]=$((${size_counts["xlarge"]} + 1))
    fi
done

for category in small medium large xlarge; do
    count=${size_counts[$category]}
    percentage=$(echo "scale=1; $count * 100 / $IMAGE_COUNT" | bc)
    echo "  ${size_categories[$category]}: $count 个镜像 ($percentage%)"
done

echo

# 优化建议
print_color "cyan" "优化建议:"
echo

# 分析镜像大小
AVG_SIZE=$(echo "scale=0; $TOTAL_SIZE_MB / $IMAGE_COUNT" | bc)
if (( $(echo "$AVG_SIZE > 200" | bc -l) )); then
    print_color "yellow" "⚠ 平均镜像大小较大，建议优化："
    echo "  • 使用更小的基础镜像 (如 alpine)"
    echo "  • 多阶段构建减少最终镜像大小"
    echo "  • 清理不必要的包和缓存"
    echo "  • 优化依赖管理"
elif (( $(echo "$AVG_SIZE > 150" | bc -l) )); then
    print_color "white" "• 镜像大小适中，可进一步优化"
else
    print_color "green" "✓ 镜像大小控制良好"
fi

echo
print_color "cyan" "最佳实践建议:"
echo "  • 定期清理未使用的镜像: docker image prune -f"
echo "  • 使用 .dockerignore 减少构建上下文"
echo "  • 合并相似的 RUN 指令减少层数"
echo "  • 使用多阶段构建分离构建和运行时"

# 导出 CSV 报告
if [ "$EXPORT_CSV" = true ]; then
    local csv_file="docker-image-size-report-$(date +%Y%m%d-%H%M%S).csv"
    print_color "cyan" "导出 CSV 报告: $csv_file"

    echo "镜像名称,版本,原始大小,大小(MB),创建时间" > "$csv_file"
    echo "$IMAGE_DATA" | while IFS=',' read -r name tag size size_mb created_at; do
        echo "$name,$tag,$size,$size_mb,$created_at" >> "$csv_file"
    done

    echo "报告已导出到: $csv_file"
fi

# 与基线比较
if [ "$COMPARE_BASELINE" = true ]; then
    echo
    print_color "cyan" "基线比较 (假设目标大小 < 150MB):"
    echo "$IMAGE_DATA" | while IFS=',' read -r name tag size size_mb created_at; do
        if (( $(echo "$size_mb <= 150" | bc -l) )); then
            print_color "green" "✓ $name:$tag - $(format_size $size_mb) (符合目标)"
        else
            print_color "yellow" "⚠ $name:$tag - $(format_size $size_mb) (超出目标)"
        fi
    done
fi

print_color "green" "========================================"