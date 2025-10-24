# Demo Mall Docker 跨平台部署指南

## 概述

本文档提供 Demo Mall 微服务项目在 Windows 11 开发环境和 Ubuntu 22 生产环境中的完整 Docker 部署指南。

## 目录

- [系统要求](#系统要求)
- [快速开始](#快速开始)
- [Windows 开发环境部署](#windows-开发环境部署)
- [Ubuntu 生产环境部署](#ubuntu-生产环境部署)
- [Docker Compose 配置](#docker-compose-配置)
- [服务管理](#服务管理)
- [监控和健康检查](#监控和健康检查)
- [故障排除](#故障排除)
- [最佳实践](#最佳实践)

## 系统要求

### Windows 11 开发环境
- **Docker Desktop**: 4.15+ 最新版本
- **内存**: 最少 8GB，推荐 16GB
- **磁盘空间**: 至少 10GB 可用空间
- **CPU**: 4核以上，支持虚拟化
- **网络**: 稳定的互联网连接

### Ubuntu 22 生产环境
- **操作系统**: Ubuntu 22.04 LTS
- **Docker**: 24.0+ 版本
- **Docker Compose**: v2.20+ 版本
- **内存**: 最少 16GB，推荐 32GB
- **磁盘空间**: 至少 50GB 可用空间 (SSD 推荐)
- **CPU**: 8核以上
- **网络**: 稳定的互联网连接
- **权限**: sudo 权限

## 快速开始

### 1. 克隆项目
```bash
git clone <repository-url>
cd demo_mall
```

### 2. 环境检测
```bash
# Windows
scripts\windows\check-env.bat

# Ubuntu
./scripts/ubuntu/check-env.sh
```

### 3. 基础服务启动
```bash
# 启动基础设施服务 (PostgreSQL, Redis, Elasticsearch, Nacos)
docker-compose up -d

# 等待服务就绪 (约2-3分钟)
./scripts/common/health-check.sh --env dev
```

### 4. 构建和部署服务
```bash
# Windows 开发环境
scripts\windows\build-images.bat
scripts\windows\start-services.bat

# Ubuntu 生产环境
./scripts/ubuntu/build-images.sh
./scripts/ubuntu/deploy.sh
```

## Windows 开发环境部署

### 1. 环境准备

#### 安装 Docker Desktop
1. 下载 [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop/)
2. 安装时确保启用 WSL 2 后端
3. 启动 Docker Desktop 并确保服务正在运行

#### 验证安装
```powershell
# 检查 Docker 版本
docker --version
docker-compose --version

# 检查 Docker 状态
docker info
```

### 2. 项目配置

#### 环境变量设置
创建 `.env` 文件 (Windows):
```env
# Docker 环境
COMPOSE_PROJECT_NAME=demo-mall-dev
COMPOSE_FILE=docker/docker-compose.dev.yml

# 数据库配置
POSTGRES_USER=oizys
POSTGRES_PASSWORD=postgres123
PGSQL_PASSWD=postgres123

# 服务端口配置
GATEWAY_PORT=9100
USER_SERVICE_PORT=9201
PRODUCT_SERVICE_PORT=9202
ORDER_SERVICE_PORT=9203

# 开发环境特定配置
SPRING_PROFILES_ACTIVE=dev
LOG_LEVEL=DEBUG
```

### 3. 构建服务镜像

#### 使用脚本构建
```batch
# 自动构建所有服务镜像
scripts\windows\build-images.bat

# 构建特定服务
scripts\windows\build-images.bat gateway
```

#### 手动构建
```batch
# 构建单个服务
cd demo-mall-gateway
docker build -f Dockerfile.dev -t demo-mall/gateway:dev .

# 返回项目根目录
cd ..
```

### 4. 启动开发环境

#### 启动基础设施服务
```batch
# 启动 PostgreSQL, Redis, Elasticsearch, Nacos
docker-compose up -d postgres redis elasticsearch kibana nacos

# 等待服务就绪
timeout /t 180
```

#### 启动微服务
```batch
# 使用脚本启动所有服务
scripts\windows\start-services.bat

# 或手动启动
docker-compose -f docker/docker-compose.dev.yml up -d gateway user product order
```

### 5. 验证部署

#### 健康检查
```batch
# 运行健康检查脚本
scripts\common\health-check.bat --env dev

# 或手动检查服务状态
docker-compose ps
```

#### 访问服务
- **API 网关**: http://localhost:9100
- **Nacos 控制台**: http://localhost:8848/nacos
- **Kibana**: http://localhost:5601
- **Elasticsearch**: http://localhost:9200

## Ubuntu 生产环境部署

### 1. 系统准备

#### 安装 Docker
```bash
# 更新系统包
sudo apt update && sudo apt upgrade -y

# 安装必要的包
sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release

# 添加 Docker 官方 GPG 密钥
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# 设置 Docker 仓库
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 安装 Docker Engine
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 启动 Docker 服务
sudo systemctl start docker
sudo systemctl enable docker

# 将用户添加到 docker 组
sudo usermod -aG docker $USER
```

#### 安装 Docker Compose
```bash
# 下载 Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# 添加执行权限
sudo chmod +x /usr/local/bin/docker-compose

# 创建符号链接
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
```

#### 验证安装
```bash
# 检查 Docker 版本
docker --version
docker-compose --version

# 检查 Docker 状态
sudo systemctl status docker
docker info
```

### 2. 系统优化

#### 配置系统限制
```bash
# 编辑 limits.conf
sudo nano /etc/security/limits.conf

# 添加以下内容
* soft nofile 65536
* hard nofile 65536
* soft nproc 32768
* hard nproc 32768
root soft nofile 65536
root hard nofile 65536
```

#### 配置内核参数
```bash
# 编辑 sysctl.conf
sudo nano /etc/sysctl.conf

# 添加以下内容
vm.max_map_count=262144
net.core.somaxconn=65535
fs.file-max=2097152

# 应用配置
sudo sysctl -p
```

#### 配置 Docker 日志
```bash
# 创建或编辑 Docker daemon 配置
sudo nano /etc/docker/daemon.json

{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "5"
  },
  "storage-driver": "overlay2",
  "default-ulimits": {
    "nofile": {
      "Name": "nofile",
      "Hard": 65536,
      "Soft": 65536
    }
  }
}

# 重启 Docker
sudo systemctl restart docker
```

### 3. 项目部署

#### 克隆和配置项目
```bash
# 克隆项目
git clone <repository-url>
cd demo_mall

# 设置执行权限
chmod +x scripts/**/*.sh

# 创建生产环境配置
cp docker/.env.ubuntu .env
```

#### 环境变量配置
```bash
# 编辑 .env 文件
nano .env
```

生产环境配置示例:
```env
# Docker 环境
COMPOSE_PROJECT_NAME=demo-mall-prod
COMPOSE_FILE=docker/docker-compose.prod.yml

# 数据库配置
POSTGRES_USER=oizys
POSTGRES_PASSWORD=your_secure_password
PGSQL_PASSWD=your_secure_password

# 服务端口配置
GATEWAY_PORT=9100
USER_SERVICE_PORT=9201
PRODUCT_SERVICE_PORT=9202
ORDER_SERVICE_PORT=9203

# 生产环境特定配置
SPRING_PROFILES_ACTIVE=prod
LOG_LEVEL=INFO
JAVA_OPTS=-Xms512m -Xmx1024m
```

#### 运行部署脚本
```bash
# 执行完整部署
./scripts/ubuntu/deploy.sh

# 或分步执行
./scripts/ubuntu/check-env.sh
./scripts/ubuntu/build-images.sh
./scripts/ubuntu/start-services.sh
```

### 4. 生产环境优化

#### 配置防火墙
```bash
# 配置 UFW 防火墙
sudo ufw enable
sudo ufw allow ssh
sudo ufw allow 9100/tcp  # Gateway
sudo ufw allow 9201/tcp  # User Service
sudo ufw allow 9202/tcp  # Product Service
sudo ufw allow 9203/tcp  # Order Service
sudo ufw allow 8848/tcp  # Nacos (内部访问)
```

#### 配置日志轮转
```bash
# 创建 logrotate 配置
sudo nano /etc/logrotate.d/demo-mall

/var/log/demo-mall/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 root root
    postrotate
        docker-compose -f /path/to/demo_mall/docker/docker-compose.prod.yml restart
    endscript
}
```

## Docker Compose 配置

### 开发环境配置 (docker-compose.dev.yml)

```yaml
version: '3.8'

services:
  # API 网关
  gateway:
    image: demo-mall/gateway:dev
    container_name: demo-mall-gateway
    ports:
      - "9100:9100"
    environment:
      - SPRING_PROFILES_ACTIVE=dev
      - NACOS_SERVER_ADDR=nacos:8848
    volumes:
      - ./demo-mall-gateway/src/main/resources:/app/resources
    depends_on:
      nacos:
        condition: service_healthy
    networks:
      - demo-mall-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9100/actuator/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  # 用户服务
  user:
    image: demo-mall/user:dev
    container_name: demo-mall-user
    ports:
      - "9201:9201"
    environment:
      - SPRING_PROFILES_ACTIVE=dev
      - NACOS_SERVER_ADDR=nacos:8848
      - SPRING_DATASOURCE_URL=jdbc:postgresql://postgres:5432/demo_mall_user
    volumes:
      - ./demo-mall-user/src/main/resources:/app/resources
    depends_on:
      - postgres
      - nacos
    networks:
      - demo-mall-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9201/actuator/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  # 商品服务
  product:
    image: demo-mall/product:dev
    container_name: demo-mall-product
    ports:
      - "9202:9202"
    environment:
      - SPRING_PROFILES_ACTIVE=dev
      - NACOS_SERVER_ADDR=nacos:8848
      - SPRING_DATASOURCE_URL=jdbc:postgresql://postgres:5432/demo_mall_product
    volumes:
      - ./demo-mall-product/src/main/resources:/app/resources
    depends_on:
      - postgres
      - nacos
      - elasticsearch
    networks:
      - demo-mall-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9202/actuator/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  # 订单服务
  order:
    image: demo-mall/order:dev
    container_name: demo-mall-order
    ports:
      - "9203:9203"
    environment:
      - SPRING_PROFILES_ACTIVE=dev
      - NACOS_SERVER_ADDR=nacos:8848
      - SPRING_DATASOURCE_URL=jdbc:postgresql://postgres:5432/demo_mall_order
    volumes:
      - ./demo-mall-order/src/main/resources:/app/resources
    depends_on:
      - postgres
      - nacos
      - elasticsearch
      - redis
    networks:
      - demo-mall-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9203/actuator/health"]
      interval: 30s
      timeout: 10s
      retries: 3

networks:
  demo-mall-network:
    external: true
```

### 生产环境配置 (docker-compose.prod.yml)

```yaml
version: '3.8'

services:
  # API 网关
  gateway:
    image: demo-mall/gateway:prod
    container_name: demo-mall-gateway
    ports:
      - "9100:9100"
    environment:
      - SPRING_PROFILES_ACTIVE=prod
      - NACOS_SERVER_ADDR=nacos:8848
      - JAVA_OPTS=-Xms512m -Xmx1024m
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 1G
        reservations:
          cpus: '0.5'
          memory: 512M
    depends_on:
      nacos:
        condition: service_healthy
    networks:
      - demo-mall-network
    restart: unless-stopped
    logging:
      driver: "json-file"
      options:
        max-size: "50m"
        max-file: "3"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9100/actuator/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s

  # 用户服务
  user:
    image: demo-mall/user:prod
    container_name: demo-mall-user
    ports:
      - "9201:9201"
    environment:
      - SPRING_PROFILES_ACTIVE=prod
      - NACOS_SERVER_ADDR=nacos:8848
      - SPRING_DATASOURCE_URL=jdbc:postgresql://postgres:5432/demo_mall_user
      - JAVA_OPTS=-Xms512m -Xmx1024m
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 1G
        reservations:
          cpus: '0.5'
          memory: 512M
    depends_on:
      postgres:
        condition: service_healthy
      nacos:
        condition: service_healthy
    networks:
      - demo-mall-network
    restart: unless-stopped
    logging:
      driver: "json-file"
      options:
        max-size: "50m"
        max-file: "3"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9201/actuator/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s

  # 商品服务
  product:
    image: demo-mall/product:prod
    container_name: demo-mall-product
    ports:
      - "9202:9202"
    environment:
      - SPRING_PROFILES_ACTIVE=prod
      - NACOS_SERVER_ADDR=nacos:8848
      - SPRING_DATASOURCE_URL=jdbc:postgresql://postgres:5432/demo_mall_product
      - JAVA_OPTS=-Xms512m -Xmx1024m
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 1G
        reservations:
          cpus: '0.5'
          memory: 512M
    depends_on:
      postgres:
        condition: service_healthy
      nacos:
        condition: service_healthy
      elasticsearch:
        condition: service_healthy
    networks:
      - demo-mall-network
    restart: unless-stopped
    logging:
      driver: "json-file"
      options:
        max-size: "50m"
        max-file: "3"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9202/actuator/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s

  # 订单服务
  order:
    image: demo-mall/order:prod
    container_name: demo-mall-order
    ports:
      - "9203:9203"
    environment:
      - SPRING_PROFILES_ACTIVE=prod
      - NACOS_SERVER_ADDR=nacos:8848
      - SPRING_DATASOURCE_URL=jdbc:postgresql://postgres:5432/demo_mall_order
      - JAVA_OPTS=-Xms512m -Xmx1024m
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 1G
        reservations:
          cpus: '0.5'
          memory: 512M
    depends_on:
      postgres:
        condition: service_healthy
      nacos:
        condition: service_healthy
      elasticsearch:
        condition: service_healthy
      redis:
        condition: service_healthy
    networks:
      - demo-mall-network
    restart: unless-stopped
    logging:
      driver: "json-file"
      options:
        max-size: "50m"
        max-file: "3"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9203/actuator/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s

networks:
  demo-mall-network:
    external: true
```

## 服务管理

### 启动服务

#### 启动所有服务
```bash
# Windows
scripts\windows\start-services.bat

# Ubuntu
./scripts/ubuntu/start-services.sh
```

#### 启动特定服务
```bash
# 启动单个服务
docker-compose up -d gateway

# 启动多个服务
docker-compose up -d gateway user product
```

### 停止服务

#### 停止所有服务
```bash
docker-compose down
```

#### 停止并删除数据
```bash
docker-compose down -v
```

### 重启服务

#### 重启所有服务
```bash
docker-compose restart
```

#### 重启特定服务
```bash
docker-compose restart gateway
```

### 查看服务状态

#### 查看运行状态
```bash
docker-compose ps
```

#### 查看服务日志
```bash
# 查看所有服务日志
docker-compose logs -f

# 查看特定服务日志
docker-compose logs -f gateway

# 查看最近的日志
docker-compose logs --tail=100 gateway
```

## 监控和健康检查

### 健康检查脚本

#### 单次检查
```bash
# 开发环境
./scripts/common/health-check.sh --env dev

# 生产环境
./scripts/common/health-check.sh --env prod

# JSON 格式输出
./scripts/common/health-check.sh --env prod --json
```

#### 连续监控
```bash
# 启动连续监控模式
./scripts/common/health-check.sh --env prod --continuous
```

### 手动健康检查

#### 检查服务端点
```bash
# Gateway
curl http://localhost:9100/actuator/health

# User Service
curl http://localhost:9201/actuator/health

# Product Service
curl http://localhost:9202/actuator/health

# Order Service
curl http://localhost:9203/actuator/health
```

#### 检查基础设施服务
```bash
# PostgreSQL
docker exec demo-mall-postgres pg_isready -U oizys

# Redis
docker exec demo-mall-redis redis-cli ping

# Elasticsearch
curl http://localhost:9200/_cluster/health

# Nacos
curl http://localhost:8848/nacos/
```

### 性能监控

#### 查看资源使用情况
```bash
# 查看容器资源使用
docker stats

# 查看磁盘使用
docker system df

# 查看详细信息
docker inspect demo-mall-gateway
```

#### 镜像大小分析
```bash
# 生成镜像大小报告
./scripts/common/size-report.sh

# 与基线比较
./scripts/common/size-report.sh --compare

# 导出 CSV 报告
./scripts/common/size-report.sh --csv
```

## 故障排除

### 常见问题

#### 1. 服务无法启动

**症状**: 容器启动失败或立即退出

**解决方案**:
```bash
# 查看容器日志
docker logs demo-mall-gateway

# 检查配置文件
docker exec demo-mall-gateway cat /app/application.yml

# 检查端口占用
netstat -tulpn | grep 9100
```

#### 2. 数据库连接失败

**症状**: 服务日志显示数据库连接错误

**解决方案**:
```bash
# 检查 PostgreSQL 状态
docker-compose ps postgres
docker logs demo-mall-postgres

# 测试数据库连接
docker exec -it demo-mall-postgres psql -U oizys -d demo_mall_user

# 检查网络连接
docker exec demo-mall-gateway ping postgres
```

#### 3. Nacos 注册失败

**症状**: 服务无法注册到 Nacos

**解决方案**:
```bash
# 检查 Nacos 状态
docker-compose ps nacos
docker logs demo-mall-nacos

# 检查网络连接
docker exec demo-mall-gateway ping nacos

# 访问 Nacos 控制台
curl http://localhost:8848/nacos/
```

#### 4. Elasticsearch 内存不足

**症状**: Elasticsearch 启动失败或响应缓慢

**解决方案**:
```bash
# 增加 JVM 堆内存
# 在 docker-compose.yml 中修改 ES_JAVA_OPTS
environment:
  - "ES_JAVA_OPTS=-Xms1g -Xmx1g"

# 检查系统内存
free -h

# 调整虚拟内存设置
sudo sysctl vm.max_map_count=262144
```

#### 5. 镜像构建失败

**症状**: Docker 镜像构建过程中失败

**解决方案**:
```bash
# 清理构建缓存
docker builder prune -a

# 检查 Maven 构建
cd demo-mall-gateway
mvn clean package -DskipTests

# 检查 Dockerfile 语法
docker build -f Dockerfile.prod --no-cache .
```

### 日志分析

#### 应用日志
```bash
# 查看应用错误日志
docker logs demo-mall-gateway | grep ERROR

# 查看最近 50 行日志
docker logs --tail 50 demo-mall-gateway

# 实时监控日志
docker logs -f demo-mall-gateway
```

#### 系统日志
```bash
# 查看 Docker 系统日志
sudo journalctl -u docker.service

# 查看系统资源日志
top
htop
iostat -x 1
```

### 网络问题排查

#### 检查网络连接
```bash
# 查看网络列表
docker network ls

# 查看网络详情
docker network inspect demo-mall-demo-mall-network

# 测试容器间连接
docker exec demo-mall-gateway ping demo-mall-user
```

#### 端口映射问题
```bash
# 检查端口占用
sudo netstat -tulpn | grep 9100

# 检查防火墙设置
sudo ufw status
sudo iptables -L
```

## 最佳实践

### 1. 镜像优化

#### 使用多阶段构建
```dockerfile
# 构建阶段
FROM maven:3.9-alpine AS builder
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn clean package -DskipTests

# 运行阶段
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
COPY --from=builder /app/target/*.jar app.jar
EXPOSE 9100
ENTRYPOINT ["java", "-jar", "app.jar"]
```

#### 减小镜像大小
- 使用 Alpine Linux 基础镜像
- 清理不必要的包和缓存
- 使用 `.dockerignore` 文件
- 合并 RUN 指令减少层数

### 2. 安全配置

#### 最小权限原则
```yaml
# 在 docker-compose.yml 中配置
user: "1000:1000"  # 非 root 用户运行
read_only: true    # 只读文件系统
tmpfs:
  - /tmp          # 临时文件系统
```

#### 敏感信息管理
- 使用环境变量而非配置文件存储敏感信息
- 使用 Docker secrets 管理敏感数据
- 定期轮换密码和密钥

### 3. 性能优化

#### 资源限制
```yaml
# 在 docker-compose.yml 中配置
deploy:
  resources:
    limits:
      cpus: '1.0'
      memory: 1G
    reservations:
      cpus: '0.5'
      memory: 512M
```

#### JVM 优化
```yaml
environment:
  - "JAVA_OPTS=-Xms512m -Xmx1024m -XX:+UseG1GC -XX:MaxGCPauseMillis=200"
```

### 4. 监控和日志

#### 结构化日志
```yaml
logging:
  driver: "json-file"
  options:
    max-size: "50m"
    max-file: "3"
    labels: "service,environment"
```

#### 健康检查
```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:9100/actuator/health"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 60s
```

### 5. 备份和恢复

#### 数据备份
```bash
# PostgreSQL 备份
docker exec demo-mall-postgres pg_dump -U oizys demo_mall_user > backup.sql

# 数据卷备份
docker run --rm -v demo_mall_postgres_data:/data -v $(pwd):/backup ubuntu tar czf /backup/postgres-backup.tar.gz -C /data .
```

#### 配置备份
```bash
# 备份配置文件
tar czf config-backup.tar.gz docker/ scripts/ .env

# 备份 Docker Compose 文件
cp docker-compose.yml docker-compose.backup.yml
```

### 6. 升级和维护

#### 滚动升级
```bash
# 构建新版本镜像
./scripts/ubuntu/build-images.sh

# 逐个升级服务
docker-compose up -d --no-deps gateway
docker-compose up -d --no-deps user
docker-compose up -d --no-deps product
docker-compose up -d --no-deps order
```

#### 定期维护
```bash
# 清理未使用的镜像
docker image prune -f

# 清理未使用的容器
docker container prune -f

# 清理未使用的网络
docker network prune -f

# 清理未使用的卷
docker volume prune -f
```

---

## 联系和支持

如果在部署过程中遇到问题，请：

1. 查看本文档的故障排除部分
2. 检查项目的 GitHub Issues
3. 联系技术支持团队

**版本**: 1.0.0
**更新日期**: 2024年
**维护者**: Demo Mall 开发团队