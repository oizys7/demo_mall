# Demo Mall Docker 镜像构建脚本 (PowerShell)
# 支持并行构建和详细日志

param(
    [string]$AppVersion = "1.0.0",
    [string]$DockerRegistryPrefix = "demo-mall",
    [switch]$Production,
    [switch]$Parallel,
    [switch]$Clean,
    [switch]$Verbose
)

# 设置错误处理
$ErrorActionPreference = "Stop"

# 颜色输出函数
function Write-ColorOutput {
    param(
        [string]$Message,
        [ConsoleColor]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

# 显示标题
Write-ColorOutput "========================================" "Green"
Write-ColorOutput "Demo Mall Docker 镜像构建脚本 (PowerShell)" "Green"
Write-ColorOutput "========================================" "Green"
Write-Host ""

# 检查 Docker Desktop
Write-ColorOutput "检查 Docker Desktop 状态..." "Yellow"
try {
    $dockerVersion = docker version --format "{{.Server.Version}}"
    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput "Docker Desktop 正在运行，版本: $dockerVersion" "Green"
    } else {
        throw "Docker Desktop 未运行"
    }
} catch {
    Write-ColorOutput "错误: Docker Desktop 未运行，请先启动 Docker Desktop" "Red"
    Read-Host "按 Enter 键退出"
    exit 1
}

Write-Host ""

# 清理旧镜像（如果指定）
if ($Clean) {
    Write-ColorOutput "清理旧镜像..." "Yellow"
    $oldImages = docker images $DockerRegistryPrefix --format "table {{.Repository}}:{{.Tag}}" | Select-Object -Skip 1
    if ($oldImages) {
        foreach ($image in $oldImages) {
            Write-ColorOutput "删除镜像: $image" "Gray"
            docker rmi $image 2>$null
        }
    }
    Write-Host ""
}

# 设置服务列表
$services = @(
    @{ Name = "gateway"; Port = 9100 },
    @{ Name = "user"; Port = 9201 },
    @{ Name = "product"; Port = 9202 },
    @{ Name = "order"; Port = 9203 }
)

# 设置构建类型
$buildType = if ($Production) { "prod" } else { "dev" }

Write-ColorOutput "构建配置:" "Cyan"
Write-Host "  - 应用版本: $AppVersion"
Write-Host "  - 镜像前缀: $DockerRegistryPrefix"
Write-Host "  - 构建类型: $buildType"
Write-Host "  - 并行构建: $Parallel"
Write-Host ""

# 构建函数
function Build-ServiceImage {
    param(
        [string]$ServiceName,
        [int]$Port
    )

    $startTime = Get-Date
    Write-ColorOutput "开始构建 $ServiceName 服务镜像..." "Yellow"

    if ($Verbose) {
        Write-Host "构建命令: docker build -f demo-mall-$ServiceName/Dockerfile.$buildType -t $DockerRegistryPrefix/$ServiceName`:$buildType --build-arg APP_VERSION=$AppVersion demo-mall-$ServiceName/"
    }

    try {
        $buildOutput = docker build -f "demo-mall-$ServiceName/Dockerfile.$buildType" `
            -t "$DockerRegistryPrefix/$ServiceName`:$buildType" `
            --build-arg "APP_VERSION=$AppVersion" `
            "demo-mall-$ServiceName/" 2>&1

        if ($LASTEXITCODE -eq 0) {
            $endTime = Get-Date
            $duration = $endTime - $startTime
            Write-ColorOutput "$ServiceName 镜像构建成功 (耗时: $($duration.TotalSeconds.ToString('F1'))s)" "Green"

            # 获取镜像大小
            $imageSize = docker images "$DockerRegistryPrefix/$ServiceName`:$buildType" --format "{{.Size}}"
            Write-Host "  镜像大小: $imageSize" "Gray"

            return @{
                Success = $true
                Service = $ServiceName
                Duration = $duration
                Size = $imageSize
            }
        } else {
            Write-ColorOutput "$ServiceName 镜像构建失败" "Red"
            if ($Verbose) {
                Write-Host "构建错误信息:" "Red"
                Write-Host $buildOutput "Red"
            }
            return @{
                Success = $false
                Service = $ServiceName
                Error = $buildOutput
            }
        }
    } catch {
        Write-ColorOutput "$ServiceName 构建过程中发生异常: $($_.Exception.Message)" "Red"
        return @{
            Success = $false
            Service = $ServiceName
            Error = $_.Exception.Message
        }
    }
}

# 开始构建
Write-ColorOutput "开始构建镜像..." "Cyan"
Write-Host ""

# 并行或串行构建
$buildResults = @()
if ($Parallel) {
    Write-ColorOutput "使用并行构建..." "Yellow"
    $jobs = @()

    foreach ($service in $services) {
        $job = Start-Job -ScriptBlock ${function:Build-ServiceImage} -ArgumentList $service.Name, $service.Port
        $jobs += $job
    }

    # 等待所有作业完成
    foreach ($job in $jobs) {
        $result = Receive-Job -Job $job
        $buildResults += $result
        Remove-Job -Job $job
    }
} else {
    Write-ColorOutput "使用串行构建..." "Yellow"
    foreach ($service in $services) {
        $result = Build-ServiceImage -ServiceName $service.Name -Port $service.Port
        $buildResults += $result
    }
}

# 显示构建结果
Write-Host ""
Write-ColorOutput "========================================" "Green"
Write-ColorOutput "构建结果汇总" "Green"
Write-ColorOutput "========================================" "Green"

$successCount = 0
$failureCount = 0
$totalDuration = [TimeSpan]::Zero

foreach ($result in $buildResults) {
    if ($result.Success) {
        $successCount++
        $totalDuration += $result.Duration
        Write-ColorOutput "✓ $($result.Service): $($result.Size) ($($result.Duration.TotalSeconds.ToString('F1'))s)" "Green"
    } else {
        $failureCount++
        Write-ColorOutput "✗ $($result.Service): 构建失败" "Red"
        if ($Verbose -and $result.Error) {
            Write-Host "   错误: $($result.Error)" "DarkRed"
        }
    }
}

Write-Host ""
Write-Host "统计信息:" "Cyan"
Write-Host "  - 成功: $successCount"
Write-Host "  - 失败: $failureCount"
Write-Host "  - 总耗时: $($totalDuration.TotalSeconds.ToString('F1'))s"

if ($successCount -gt 0) {
    Write-Host ""
    Write-ColorOutput "构建的镜像列表:" "Cyan"
    docker images $DockerRegistryPrefix --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
}

Write-Host ""
if ($failureCount -eq 0) {
    Write-ColorOutput "所有镜像构建成功！可以使用 start-services.ps1 启动服务。" "Green"
} else {
    Write-ColorOutput "部分镜像构建失败，请检查错误信息。" "Red"
}

Write-ColorOutput "========================================" "Green"
Read-Host "按 Enter 键退出"

# 返回退出码
if ($failureCount -gt 0) {
    exit 1
} else {
    exit 0
}