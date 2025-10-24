# Demo Mall Docker 环境使用指南

## 概述

Demo Mall 项目现在使用 Docker 来管理 PostgreSQL、Redis 和 Elasticsearch 服务。这种方式简化了环境配置，提高了开发效率。

## 服务架构

### Docker 服务
- **PostgreSQL**: 数据库服务，运行在 5432 端口
- **Redis**: 缓存服务，运行在 6379 端口
- **Elasticsearch**: 搜索服务，运行在 9200 端口
- **Kibana**: Elasticsearch 可视化工具，运行在 5601 端口

### 数据库结构
- `demo_mall_user`: 用户管理数据库
- `demo_mall_product`: 商品管理数据库
- `demo_mall_order`: 订单管理数据库

## 快速开始

### 1. 启动 Docker 服务

```bash
# Windows 环境
start-docker-services.bat

# Linux/Mac 环境
docker-compose up -d
```

### 2. 启动应用服务

```bash
# 启动用户服务
cd demo-mall-user
mvn spring-boot:run -Dspring-boot.run.profiles=dev

# 启动商品服务
cd demo-mall-product
mvn spring-boot:run -Dspring-boot.run.profiles=dev

# 启动订单服务
cd demo-mall-order
mvn spring-boot:run -Dspring-boot.run.profiles=dev

# 启动网关服务
cd demo-mall-gateway
mvn spring-boot:run -Dspring-boot.run.profiles=dev
```

## 服务访问地址

| 服务 | 地址 | 用户名 | 密码 |
|------|------|--------|------|
| PostgreSQL | localhost:5432 | oizys | postgres123 |
| Redis | localhost:6379 | - | - |
| Elasticsearch | http://localhost:9200 | - | - |
| Kibana | http://localhost:5601 | - | - |

## 数据库连接配置

所有服务已配置为连接本地 Docker 容器：

```yaml
spring:
  datasource:
    driver-class-name: org.postgresql.Driver
    url: jdbc:postgresql://localhost:5432/{database_name}
    username: oizys
    password: postgres123
```

## 管理命令

### 启动服务
```bash
# 启动所有服务（后台运行）
docker-compose up -d

# 启动并查看日志
docker-compose up

# 启动特定服务
docker-compose up postgres
```

### 停止服务
```bash
# 停止所有服务
docker-compose down

# 停止并删除数据卷（危险操作）
docker-compose down -v
```

### 查看状态
```bash
# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs [service_name]

# 实时查看日志
docker-compose logs -f [service_name]
```

### 进入容器
```bash
# 进入 PostgreSQL 容器
docker-compose exec postgres bash

# 进入 Redis 容器
docker-compose exec redis bash

# 进入 Elasticsearch 容器
docker-compose exec elasticsearch bash
```

## 数据管理

### 数据库备份
```bash
# 备份用户数据库
docker-compose exec postgres pg_dump -U oizys demo_mall_user > user_backup.sql

# 备份商品数据库
docker-compose exec postgres pg_dump -U oizys demo_mall_product > product_backup.sql

# 备份订单数据库
docker-compose exec postgres pg_dump -U oizys demo_mall_order > order_backup.sql
```

### 数据库恢复
```bash
# 恢复用户数据库
docker-compose exec -T postgres psql -U oizys demo_mall_user < user_backup.sql

# 恢复商品数据库
docker-compose exec -T postgres psql -U oizys demo_mall_product < product_backup.sql

# 恢复订单数据库
docker-compose exec -T postgres psql -U oizys demo_mall_order < order_backup.sql
```

## 初始化数据

首次启动时，PostgreSQL 会自动执行 `docker/postgres/init.sql` 脚本，创建以下内容：

1. 三个独立的数据库
2. 相应的数据表结构
3. 基础索引
4. 示例数据

## 故障排除

### 常见问题

1. **端口冲突**
   - 确保 5432、6379、9200、5601 端口未被占用
   - 如有冲突，可修改 docker-compose.yml 中的端口映射

2. **内存不足**
   - Elasticsearch 需要至少 1GB 可用内存
   - 可调整 docker-compose.yml 中的 ES_JAVA_OPTS 参数

3. **服务启动失败**
   - 检查 Docker Desktop 是否正常运行
   - 查看容器日志：`docker-compose logs [service_name]`

4. **数据库连接失败**
   - 确认 PostgreSQL 容器已启动
   - 检查网络连接和防火墙设置

### 重置环境

如果需要完全重置环境：

```bash
# Windows 环境
reset-docker-services.bat

# Linux/Mac 环境
docker-compose down -v
docker system prune -f
```

## 性能优化

### 开发环境优化
- PostgreSQL: 默认配置适合开发使用
- Redis: 开启持久化
- Elasticsearch: 512MB 堆内存

### 生产环境建议
- 增加 PostgreSQL 内存配置
- 配置 Redis 集群
- 调整 Elasticsearch 堆内存和副本数

## 监控和日志

### 日志查看
```bash
# 查看所有服务日志
docker-compose logs

# 查看特定服务日志
docker-compose logs postgres
docker-compose logs redis
docker-compose logs elasticsearch
```

### 健康检查
所有服务都配置了健康检查：

```bash
# 检查服务健康状态
docker-compose ps
```

## 版本信息

- PostgreSQL: latest
- Redis: latest
- Elasticsearch: 9.1.5
- Kibana: 9.1.5

## 更多资源

- [Docker Compose 官方文档](https://docs.docker.com/compose/)
- [PostgreSQL 官方文档](https://www.postgresql.org/docs/)
- [Redis 官方文档](https://redis.io/documentation)
- [Elasticsearch 官方文档](https://www.elastic.co/guide/)