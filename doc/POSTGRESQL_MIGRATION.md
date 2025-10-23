# PostgreSQL 数据库迁移指南

## 概述

本文档说明如何从 MySQL 迁移到 PostgreSQL 数据库，以及如何配置和使用新的数据库连接。

## 配置变更

### 1. 数据库连接信息
- **数据库类型**: MySQL → PostgreSQL
- **连接地址**: localhost:3306 → 120.26.203.218:5432
- **用户名**: root → oizys
- **密码**: 硬编码 → 环境变量 PGSQL_PASSWD
- **驱动类**: com.mysql.cj.jdbc.Driver → org.postgresql.Driver

### 2. 环境变量配置
Spring Boot 支持使用环境变量来配置数据库密码：

```yaml
# application.yml 配置
spring:
  datasource:
    password: ${PGSQL_PASSWD:oizys}  # 使用环境变量，默认值 oizys
```

这种配置方式的优点：
- **安全性**: 密码不会硬编码在配置文件中
- **灵活性**: 不同环境可设置不同的密码
- **默认值**: 如果未设置环境变量，使用默认值 oizys

### 2. 数据库URL变更
```yaml
# 旧的 MySQL 配置
url: jdbc:mysql://localhost:3306/demo_mall_user?useUnicode=true&characterEncoding=UTF-8&serverTimezone=Asia/Shanghai

# 新的 PostgreSQL 配置
url: jdbc:postgresql://120.26.203.218:5432/demo_mall_user?useUnicode=true&characterEncoding=UTF-8&serverTimezone=Asia/Shanghai
```

### 3. JPA方言变更
```yaml
# MySQL 方言
dialect: org.hibernate.dialect.MySQLDialect
database-platform: org.hibernate.dialect.MySQLDialect

# PostgreSQL 方言
dialect: org.hibernate.dialect.PostgreSQLDialect
database-platform: org.hibernate.dialect.PostgreSQLDialect
```

## 数据库结构差异

### 主键类型变更
```sql
-- MySQL
CREATE TABLE ums_user (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    -- 其他字段...
);

-- PostgreSQL
CREATE TABLE ums_user (
    id BIGSERIAL PRIMARY KEY,
    -- 其他字段...
);
```

### 时间字段类型建议
```sql
-- MySQL
CREATE TABLE ums_user (
    create_time DATETIME,
    update_time DATETIME
);

-- PostgreSQL (推荐)
CREATE TABLE ums_user (
    create_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    update_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## 数据库创建脚本

### 创建数据库和用户
```sql
-- 连接到 PostgreSQL 服务器
-- 创建用户 oizys (如果不存在)
CREATE USER oizys WITH PASSWORD 'oizys';

-- 创建数据库
CREATE DATABASE demo_mall_user OWNER oizys;
CREATE DATABASE demo_mall_product OWNER oizys;
CREATE DATABASE demo_mall_order OWNER oizys;

-- 授予权限
GRANT ALL PRIVILEGES ON DATABASE demo_mall_user TO oizys;
GRANT ALL PRIVILEGES ON DATABASE demo_mall_product TO oizys;
GRANT ALL PRIVILEGES ON DATABASE demo_mall_order TO oizys;
```

### 表结构创建脚本

#### 用户表 (ums_user)
```sql
CREATE TABLE ums_user (
    id BIGSERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL,
    password VARCHAR(100) NOT NULL,
    nickname VARCHAR(50),
    mobile VARCHAR(20),
    email VARCHAR(100),
    status INT DEFAULT 1,
    create_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    update_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 创建索引
CREATE INDEX idx_username ON ums_user(username);
CREATE INDEX idx_mobile ON ums_user(mobile);
CREATE INDEX idx_email ON ums_user(email);
```

#### 商品表 (pms_product)
```sql
CREATE TABLE pms_product (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    stock INT DEFAULT 0,
    image_url VARCHAR(500),
    status INT DEFAULT 1,
    create_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    update_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 创建索引
CREATE INDEX idx_name ON pms_product(name);
CREATE INDEX idx_status ON pms_product(status);
```

#### 订单表 (oms_order)
```sql
CREATE TABLE oms_order (
    id BIGSERIAL PRIMARY KEY,
    order_sn VARCHAR(100) NOT NULL,
    user_id BIGINT NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    status INT DEFAULT 1,
    receiver_name VARCHAR(50) NOT NULL,
    receiver_phone VARCHAR(20),
    receiver_address TEXT,
    create_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    update_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 创建索引
CREATE INDEX idx_order_sn ON oms_order(order_sn);
CREATE INDEX idx_user_id ON oms_order(user_id);
CREATE INDEX idx_status ON oms_order(status);
```

## 迁移步骤

### 1. 备份现有数据（如果需要）
```bash
# 从 MySQL 导出数据
mysqldump -u root -p demo_mall_user > user_backup.sql
mysqldump -u root -p demo_mall_product > product_backup.sql
mysqldump -u root -p demo_mall_order > order_backup.sql
```

### 2. 准备 PostgreSQL 环境
```bash
# 连接到 PostgreSQL 服务器
psql -h 120.26.203.218 -p 5432 -U postgres

# 执行数据库和用户创建脚本
```

### 3. 数据迁移（可选）
如果有现有数据需要迁移：

#### 方法一：使用转换工具
```bash
# 使用 pgloader 工具进行数据迁移
pgloader mysql://root:root@localhost/demo_mall_user \
         postgresql://oizys:oizys@120.26.203.218:5432/demo_mall_user
```

#### 方法二：导出导入
```bash
# 从 MySQL 导出为 CSV
mysql -u root -p -e "
SELECT * FROM ums_user
INTO OUTFILE '/tmp/users.csv'
FIELDS TERMINATED BY ','
ENCLOSED BY '\"'
LINES TERMINATED BY '\n';"

# 导入到 PostgreSQL
psql -h 120.26.203.218 -p 5432 -U oizys -d demo_mall_user -c "
COPY ums_user FROM '/tmp/users.csv'
WITH (FORMAT csv, HEADER);"
```

### 4. 验证迁移结果
```sql
-- 检查表结构
\d ums_user
\d pms_product
\d oms_order

-- 检查数据行数
SELECT COUNT(*) FROM ums_user;
SELECT COUNT(*) FROM pms_product;
SELECT COUNT(*) FROM oms_order;
```

## 应用配置验证

### 1. 启动应用
```bash
# 设置环境变量（Linux/macOS）
export PGSQL_PASSWD=your_actual_password

# 启动各个服务
cd demo-mall-user && mvn spring-boot:run
cd demo-mall-product && mvn spring-boot:run
cd demo-mall-order && mvn spring-boot:run
```

### 2. 环境变量设置（Windows）
```cmd
# Windows 命令行
set PGSQL_PASSWD=your_actual_password

# 或者在 PowerShell 中
$env:PGSQL_PASSWD="your_actual_password"

# 启动服务
cd demo-mall-user && mvn spring-boot:run
```

### 3. IDE 配置（IntelliJ IDEA）
1. 在 Run/Debug Configurations 中添加环境变量
2. Name: `PGSQL_PASSWD`
3. Value: 你的实际密码

### 4. 生产环境部署
在生产环境中，应该通过以下方式之一设置环境变量：
- 操作系统环境变量
- Docker 环境变量 (-e 参数）
- Kubernetes ConfigMap 或 Secret
- CI/CD 平台的环境变量设置

### 5. 检查日志
确认应用启动日志中没有数据库连接错误，类似：
```
Successfully connected to PostgreSQL database
```

### 3. 测试数据库连接
访问应用的健康检查端点或执行简单的查询来验证连接。

## 性能优化建议

### 1. 连接池配置
```yaml
spring:
  datasource:
    hikari:
      maximum-pool-size: 20
      minimum-idle: 5
      connection-timeout: 30000
      idle-timeout: 600000
      max-lifetime: 1800000
```

### 2. PostgreSQL 配置优化
```conf
# postgresql.conf 关键配置
shared_buffers = 256MB
effective_cache_size = 1GB
work_mem = 4MB
maintenance_work_mem = 64MB
checkpoint_completion_target = 0.9
wal_buffers = 16MB
```

## 注意事项

1. **大小写敏感**: PostgreSQL 对标识符大小写敏感，注意表名和字段名
2. **数据类型**: PostgreSQL 的数值类型范围与 MySQL 可能有差异
3. **自增字段**: 使用 BIGSERIAL 替代 AUTO_INCREMENT
4. **字符串长度**: PostgreSQL 中 VARCHAR 需要明确指定长度
5. **索引策略**: 根据查询模式调整索引策略

## 故障排除

### 常见问题
1. **连接失败**
   - 检查防火墙设置
   - 验证用户名和密码
   - 确认数据库服务运行状态

2. **权限错误**
   - 确认用户具有数据库访问权限
   - 检查表级别的权限设置

3. **性能问题**
   - 检查连接池配置
   - 分析查询执行计划
   - 考虑适当的索引

## 回滚方案

如果需要回滚到 MySQL：

1. 恢复 MySQL 数据库连接配置
2. 恢复 pom.xml 中的 MySQL 依赖
3. 恢复 application.yml 中的数据库配置
4. 重新编译和部署应用