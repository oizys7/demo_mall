#!/bin/bash

# Demo Mall 跨平台环境检测脚本

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
print_color "green" "Demo Mall 环境检测脚本"
print_color "green" "========================================"
echo

# 检测操作系统
detect_os() {
    case "$(uname -s)" in
        Linux*)     machine="Linux";;
        Darwin*)    machine="Mac";;
        CYGWIN*)    machine="Cygwin";;
        MINGW*)     machine="MinGw";;
        MSYS*)      machine="MSYS";;
        *)          machine="UNKNOWN:$(uname -s)";;
    esac
    echo "$machine"
}

# 检测操作系统版本
detect_os_version() {
    local os=$(detect_os)
    case $os in
        "Linux")
            if [ -f /etc/os-release ]; then
                grep PRETTY_NAME /etc/os-release | cut -d'"' -f2
            else
                uname -r
            fi
            ;;
        "Mac")
            sw_vers
            ;;
        "MinGw"|"Cygwin"|"MSYS")
            cmd /c ver
            ;;
        *)
            echo "Unknown"
            ;;
    esac
}

# 检测 Docker 状态
check_docker() {
    if command -v docker >/dev/null 2>&1; then
        local docker_version=$(docker version --format '{{.Server.Version}}' 2>/dev/null || echo "Unknown")
        echo "Docker found: $docker_version"

        # 检测 Docker 类型
        if docker info 2>/dev/null | grep -q "Operating System: Docker Desktop"; then
            echo "Docker Desktop detected"
            return 0
        elif docker info 2>/dev/null | grep -q "Operating System: Ubuntu"; then
            echo "Native Docker on Ubuntu detected"
            return 0
        else
            echo "Native Docker detected"
            return 0
        fi
    else
        echo "Docker not found"
        return 1
    fi
}

# 检测 Docker Compose
check_docker_compose() {
    if command -v docker-compose >/dev/null 2>&1; then
        local compose_version=$(docker-compose --version 2>/dev/null || echo "Unknown")
        echo "Docker Compose (standalone): $compose_version"
        return 0
    elif docker compose version >/dev/null 2>&1; then
        local compose_version=$(docker compose version --short 2>/dev/null || echo "Unknown")
        echo "Docker Compose (plugin): $compose_version"
        return 0
    else
        echo "Docker Compose not found"
        return 1
    fi
}

# 检测 Java 环境
check_java() {
    if command -v java >/dev/null 2>&1; then
        local java_version=$(java -version 2>&1 | head -1 | cut -d'"' -f2)
        echo "Java found: $java_version"

        # 检查 Java 版本是否符合要求
        if echo "$java_version" | grep -q "^21\."; then
            echo "✓ Java 21 detected (Recommended)"
        elif echo "$java_version" | grep -q "^1[78]\."; then
            echo "⚠ Java 1.7/1.8 detected (May cause issues)"
        else
            echo "⚠ Java version may not be compatible"
        fi
        return 0
    else
        echo "Java not found"
        return 1
    fi
}

# 检测 Maven 环境
check_maven() {
    if command -v mvn >/dev/null 2>&1; then
        local maven_version=$(mvn -version 2>/dev/null | head -1 | cut -d' ' -f3)
        echo "Maven found: $maven_version"
        return 0
    else
        echo "Maven not found"
        return 1
    fi
}

# 检测网络连接
check_network() {
    local services=(
        "localhost:9100:Gateway"
        "localhost:9201:User Service"
        "localhost:9202:Product Service"
        "localhost:9203:Order Service"
        "localhost:8848:Nacos"
        "localhost:5432:PostgreSQL"
        "localhost:6379:Redis"
        "localhost:9200:Elasticsearch"
    )

    print_color "cyan" "检查服务端口可用性:"
    for service in "${services[@]}"; do
        local host=$(echo $service | cut -d: -f1)
        local port=$(echo $service | cut -d: -f2)
        local name=$(echo $service | cut -d: -f3)

        if timeout 3 bash -c "</dev/tcp/$host/$port" 2>/dev/null; then
            print_color "green" "  ✓ $name ($host:$port) - 可用"
        else
            print_color "yellow" "  ✗ $name ($host:$port) - 不可用"
        fi
    done
}

# 检测磁盘空间
check_disk_space() {
    print_color "cyan" "磁盘空间使用情况:"
    df -h | head -1
    df -h | grep -E "(Filesystem|/dev/)" | head -5
}

# 检测内存使用
check_memory() {
    print_color "cyan" "内存使用情况:"
    if command -v free >/dev/null 2>&1; then
        free -h
    else
        print_color "yellow" "free 命令不可用"
    fi
}

# 检测 Docker 资源使用
check_docker_resources() {
    print_color "cyan" "Docker 资源使用:"
    if docker info >/dev/null 2>&1; then
        docker system df
    else
        print_color "yellow" "Docker 不可用"
    fi
}

# 主检测函数
main_checks() {
    local os=$(detect_os)
    local os_version=$(detect_os_version)

    print_color "cyan" "系统信息:"
    echo "  操作系统: $os"
    echo "  版本: $os_version"
    echo "  主机名: $(hostname)"
    echo "  当前时间: $(date)"
    echo

    print_color "cyan" "运行时环境检测:"
    echo

    # Docker 检测
    if check_docker; then
        docker_ok=true
    else
        docker_ok=false
    fi
    echo

    # Docker Compose 检测
    if check_docker_compose; then
        compose_ok=true
    else
        compose_ok=false
    fi
    echo

    # Java 检测
    if check_java; then
        java_ok=true
    else
        java_ok=false
    fi
    echo

    # Maven 检测
    if check_maven; then
        maven_ok=true
    else
        maven_ok=false
    fi
    echo

    # 系统资源检测
    check_disk_space
    echo
    check_memory
    echo
    check_docker_resources
    echo

    # 网络检测
    check_network
    echo

    # 检测结果汇总
    print_color "cyan" "检测结果汇总:"
    echo

    local all_ok=true

    if [ "$docker_ok" = true ]; then
        print_color "green" "  ✓ Docker: 已安装并运行"
    else
        print_color "red" "  ✗ Docker: 未安装或未运行"
        all_ok=false
    fi

    if [ "$compose_ok" = true ]; then
        print_color "green" "  ✓ Docker Compose: 已安装"
    else
        print_color "red" "  ✗ Docker Compose: 未安装"
        all_ok=false
    fi

    if [ "$java_ok" = true ]; then
        print_color "green" "  ✓ Java: 已安装"
    else
        print_color "yellow" "  ⚠ Java: 未安装 (可选，仅用于本地开发)"
    fi

    if [ "$maven_ok" = true ]; then
        print_color "green" "  ✓ Maven: 已安装"
    else
        print_color "yellow" "  ⚠ Maven: 未安装 (可选，仅用于本地构建)"
    fi

    echo

    # 推荐操作
    print_color "cyan" "推荐操作:"
    echo

    if [ "$docker_ok" = false ]; then
        echo "  1. 安装 Docker Desktop (Windows) 或 Docker Engine (Linux)"
        echo "  2. 确保 Docker 服务正在运行"
    fi

    if [ "$compose_ok" = false ]; then
        echo "  3. 安装 Docker Compose"
    fi

    if [ "$java_ok" = false ] || [ "$maven_ok" = false ]; then
        echo "  4. 安装 Java 21 和 Maven 3.9+ (用于本地开发)"
    fi

    if [ "$all_ok" = true ]; then
        print_color "green" "🎉 环境检测通过！可以开始部署 Demo Mall"
        echo
        echo "下一步操作:"
        if [ "$os" = "Linux" ]; then
            echo "  Linux: ./scripts/ubuntu/deploy.sh"
        elif [[ "$os" =~ ^(MinGw|Cygwin|MSYS)$ ]]; then
            echo "  Windows: scripts\\windows\\build-images.bat"
        else
            echo "  根据您的操作系统运行相应的部署脚本"
        fi
    else
        print_color "yellow" "请先解决上述问题，然后重新运行环境检测"
    fi
}

# 执行检测
main_checks

print_color "green" "========================================"