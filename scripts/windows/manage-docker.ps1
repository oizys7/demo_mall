# Demo Mall Docker 管理工具 (PowerShell)
# 提供完整的 Docker 环境管理功能

param(
    [ValidateSet("build", "start", "stop", "restart", "status", "logs", "clean", "size", "health", "dev", "prod")]
    [string]$Action,

    [string]$Service = "",
    [switch]$Verbose,
    [switch]$Force
)

# 颜色输出函数
function Write-ColorOutput {
    param(
        [string]$Message,
        [ConsoleColor]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

# 检查 Docker Desktop 状态
function Test-DockerDesktop {
    try {
        $null = docker version 2>$null
        return $LASTEXITCODE -eq 0
    } catch {
        return $false
    }
}

# 获取服务状态
function Get-ServiceStatus {
    try {
        $statusOutput = docker-compose -f docker/docker-compose.dev.yml ps --format "table {{.Name}}\t{{.State}}\t{{.Status}}"
        return $statusOutput
    } catch {
        return "无法获取服务状态: $($_.Exception.Message)"
    }
}

# 检查服务健康状态
function Test-ServiceHealth {
    $services = @(
        @{ Name = "Nacos"; Url = "http://localhost:8848/nacos/" },
        @{ Name = "Gateway"; Url = "http://localhost:9100/actuator/health" },
        @{ Name = "User Service"; Url = "http://localhost:9201/actuator/health" },
        @{ Name = "Product Service"; Url = "http://localhost:9202/actuator/health" },
        @{ Name = "Order Service"; Url = "http://localhost:9203/actuator/health" },
        @{ Name = "PostgreSQL"; Port = 5432 },
        @{ Name = "Redis"; Port = 6379 },
        @{ Name = "Elasticsearch"; Url = "http://localhost:9200/_cluster/health" }
    )

    Write-ColorOutput "服务健康检查结果:" "Cyan"
    Write-Host ""

    foreach ($service in $services) {
        if ($service.Url) {
            try {
                $response = Invoke-WebRequest -Uri $service.Url -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
                if ($response.StatusCode -eq 200) {
                    Write-ColorOutput "✓ $($service.Name): 健康" "Green"
                } else {
                    Write-ColorOutput "✗ $($service.Name): HTTP $($response.StatusCode)" "Yellow"
                }
            } catch {
                Write-ColorOutput "✗ $($service.Name): 无法访问" "Red"
            }
        } elseif ($service.Port) {
            try {
                $tcpClient = New-Object System.Net.Sockets.TcpClient
                $connect = $tcpClient.BeginConnect("localhost", $service.Port, $null, $null)
                $wait = $connect.AsyncWaitHandle.WaitOne(1000, $false)
                if ($wait) {
                    Write-ColorOutput "✓ $($service.Name): 端口 $($service.Port) 可达" "Green"
                } else {
                    Write-ColorOutput "✗ $($service.Name): 端口 $($service.Port) 不可达" "Red"
                }
                $tcpClient.Close()
            } catch {
                Write-ColorOutput "✗ $($service.Name): 端口 $($service.Port) 检查失败" "Red"
            }
        }
    }
}

# 清理 Docker 资源
function Clear-DockerResources {
    param([switch]$Force)

    Write-ColorOutput "清理 Docker 资源..." "Yellow"

    if ($Force) {
        Write-ColorOutput "强制清理模式，将删除所有相关资源" "Red"

        # 停止所有容器
        Write-Host "停止所有相关容器..." "Gray"
        docker-compose -f docker/docker-compose.dev.yml down -v 2>$null
        docker-compose -f docker/docker-compose.yml down -v 2>$null

        # 删除镜像
        Write-Host "删除相关镜像..." "Gray"
        $images = docker images "demo-mall*" --format "{{.Repository}}:{{.Tag}}"
        foreach ($image in $images) {
            Write-Host "删除镜像: $image" "DarkGray"
            docker rmi $image -f 2>$null
        }

        # 清理未使用的资源
        Write-Host "清理未使用的资源..." "Gray"
        docker system prune -f

        Write-ColorOutput "强制清理完成！" "Green"
    } else {
        Write-Host "清理停止的容器和未使用的镜像..." "Gray"
        docker container prune -f
        docker image prune -f
        Write-ColorOutput "常规清理完成！" "Green"
    }
}

# 分析镜像大小
function Get-ImageSizeAnalysis {
    Write-ColorOutput "Docker 镜像大小分析" "Cyan"
    Write-Host ""

    $images = docker images "demo-mall*" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
    Write-Host $images

    # 计算总大小
    $imageData = docker images "demo-mall*" --format "{{.Size}}" | Select-Object -Skip 1
    $totalSize = 0

    foreach ($size in $imageData) {
        if ($size -match "(\d+(?:\.\d+)?)\s*(KB|MB|GB)") {
            $value = [double]$matches[1]
            $unit = $matches[2]

            switch ($unit) {
                "KB" { $totalSize += $value / 1024 }
                "MB" { $totalSize += $value }
                "GB" { $totalSize += $value * 1024 }
            }
        }
    }

    Write-Host ""
    Write-Host "总大小: $([math]::Round($totalSize, 2)) MB" "Yellow"
}

# 主函数
function Main {
    Write-ColorOutput "========================================" "Green"
    Write-ColorOutput "Demo Mall Docker 管理工具" "Green"
    Write-ColorOutput "========================================" "Green"
    Write-Host ""

    # 检查 Docker Desktop
    if (-not (Test-DockerDesktop)) {
        Write-ColorOutput "错误: Docker Desktop 未运行，请先启动 Docker Desktop" "Red"
        exit 1
    }

    Write-Host "Docker Desktop 正在运行"
    Write-Host ""

    switch ($Action.ToLower()) {
        "build" {
            Write-ColorOutput "构建 Docker 镜像..." "Yellow"
            if ($Verbose) {
                & "$PSScriptRoot\build-images.ps1" -Verbose
            } else {
                & "$PSScriptRoot\build-images.ps1"
            }
        }

        "start" {
            Write-ColorOutput "启动服务..." "Yellow"
            & "$PSScriptRoot\start-services.bat"
        }

        "stop" {
            Write-ColorOutput "停止服务..." "Yellow"
            & "$PSScriptRoot\stop-services.bat"
        }

        "restart" {
            Write-ColorOutput "重启服务..." "Yellow"
            & "$PSScriptRoot\stop-services.bat"
            Write-Host "等待服务完全停止..." "Gray"
            Start-Sleep 10
            & "$PSScriptRoot\start-services.bat"
        }

        "status" {
            Write-ColorOutput "服务状态:" "Cyan"
            Write-Host ""
            $status = Get-ServiceStatus
            Write-Host $status
        }

        "logs" {
            Write-ColorOutput "查看服务日志..." "Yellow"
            if ($Service) {
                Write-Host "查看服务 '$Service' 的日志:" "Cyan"
                docker-compose -f docker/docker-compose.dev.yml logs -f $Service
            } else {
                Write-Host "查看所有服务的日志:" "Cyan"
                docker-compose -f docker/docker-compose.dev.yml logs -f
            }
        }

        "clean" {
            Clear-DockerResources -Force:$Force
        }

        "size" {
            Get-ImageSizeAnalysis
        }

        "health" {
            Test-ServiceHealth
        }

        "dev" {
            Write-ColorOutput "切换到开发环境配置..." "Yellow"
            $env:COMPOSE_FILE = "docker/docker-compose.dev.yml"
            Write-Host "开发环境配置已激活"
            Write-Host "使用 'start' 启动开发环境服务"
        }

        "prod" {
            Write-ColorOutput "切换到生产环境配置..." "Yellow"
            $env:COMPOSE_FILE = "docker/docker-compose.prod.yml"
            Write-Host "生产环境配置已激活"
            Write-Host "使用 'start' 启动生产环境服务"
        }

        default {
            Write-ColorOutput "用法: .\manage-docker.ps1 -Action <action> [options]" "Cyan"
            Write-Host ""
            Write-Host "可用操作:" "Yellow"
            Write-Host "  build    - 构建 Docker 镜像"
            Write-Host "  start    - 启动服务"
            Write-Host "  stop     - 停止服务"
            Write-Host "  restart  - 重启服务"
            Write-Host "  status   - 查看服务状态"
            Write-Host "  logs     - 查看服务日志"
            Write-Host "  clean    - 清理 Docker 资源"
            Write-Host "  size     - 分析镜像大小"
            Write-Host "  health   - 健康检查"
            Write-Host "  dev      - 切换到开发环境"
            Write-Host "  prod     - 切换到生产环境"
            Write-Host ""
            Write-Host "选项:" "Yellow"
            Write-Host "  -Service <name>  - 指定服务名称 (用于 logs)"
            Write-Host "  -Verbose          - 详细输出"
            Write-Host "  -Force            - 强制执行 (用于 clean)"
        }
    }
}

# 执行主函数
Main