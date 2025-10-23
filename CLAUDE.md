# CLAUDE.md

使用中文回复，代码注释也使用中文。
以后生成的md文件都放在项目根目录下的doc文件夹下

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

Demo Mall 是基于 Spring Boot 3.x 和 Spring Cloud 构建的微服务电商系统。项目采用模块化架构，为不同业务域提供独立服务。

## 项目架构

### 微服务结构
- **demo-mall-gateway**: API 网关，运行在 9100 端口，负责路由请求到对应服务
- **demo-mall-user**: 用户管理服务，运行在 9201 端口
- **demo-mall-product**: 商品管理服务，运行在 9202 端口
- **demo-mall-order**: 订单管理服务，运行在 9203 端口
- **demo-mall-common**: 共享通用模块，包含工具类和标准响应格式

### 技术栈
- Java 21
- Spring Boot 3.3.4
- Spring Cloud 2023.0.3
- Spring Cloud Alibaba 2022.0.0.0
- Spring Cloud Gateway
- Nacos 服务发现（需要 Nacos 服务器运行在 localhost:8848）
- **Spring Data JPA** ORM 框架
- **PostgreSQL** 数据库（每个服务独立数据库）

### 数据库结构
每个服务拥有独立的 PostgreSQL 数据库：
- demo_mall_user: 用户数据（ums_user 表）
- demo_mall_product: 商品数据（pms_product 表）
- demo_mall_order: 订单数据（oms_order 表）

## 开发命令

### 项目构建
```bash
# 编译所有模块
mvn clean compile

# 打包所有模块
mvn clean package

# 打包特定模块
mvn clean package -pl demo-mall-user

# 跳过测试打包
mvn clean package -DskipTests
```

### 服务启动
每个服务需要单独启动：

```bash
# 启动用户服务
cd demo-mall-user
mvn spring-boot:run

# 启动商品服务
cd demo-mall-product
mvn spring-boot:run

# 启动订单服务
cd demo-mall-order
mvn spring-boot:run

# 启动网关服务
cd demo-mall-gateway
mvn spring-boot:run
```

### 前置条件
1. **Nacos 服务器**: 启动任何服务前必须先运行在 localhost:8848
2. **PostgreSQL 数据库**: 需要创建三个独立数据库：
   - demo_mall_user
   - demo_mall_product
   - demo_mall_order
3. **Java 21**: 编译和运行必需
4. **数据库连接**: 连接地址 120.26.203.218:5432，用户名为 oizys
5. **环境变量**: 数据库密码使用 PGSQL_PASSWD 环境变量

## 项目结构

### Maven 模块配置
- **父 POM**: `pom.xml` 管理所有依赖版本和模块
- ** groupId**: `com.oizys`
- **artifactId**: `demo-mall`
- **version**: `1.0.0`

### 服务标准结构
每个业务服务遵循相同的包结构：
```
com.oizys.mall.{service}/
├── {Service}Application.java     # Spring Boot 启动类
├── controller/                   # 控制器层
├── entity/                      # 实体类
├── mapper/                      # MyBatis 映射器
└── service/                     # 服务层接口和实现
```

## API 网关路由

网关路由规则：
- `/api/user/**` → demo-mall-user 服务
- `/api/product/**` → demo-mall-product 服务
- `/api/order/**` → demo-mall-order 服务

## 通用模块模式

### 标准响应格式
所有服务使用 `demo-mall-common` 模块的 `Result<T>` 类统一 API 响应：
- `Result.success(data)`: 成功响应（状态码 200）
- `Result.error(message)`: 错误响应（状态码 500）
- `Result.error(code, message)`: 自定义错误码响应

### 实体类规范
实体类遵循 JPA 标准模式：
- 使用 JPA 注解进行表映射（@Entity, @Table, @Id, @GeneratedValue）
- 使用 Lombok 减少样板代码
- 自增主键（GenerationType.IDENTITY）
- 标准审计字段（createTime, updateTime）
- 时间字段使用 LocalDateTime 类型

### 服务层模式
服务层使用 JPA Repository 接口，所有 Mapper 接口继承 `JpaRepository<Entity, Long>`，提供基础 CRUD 操作。

## 开发注意事项

- 每个服务独立运行，拥有自己的数据库
- 服务间通过 API 网关进行通信
- 所有服务使用 Nacos 进行服务注册和发现
- 数据库配置使用统一的连接信息（localhost:3306, root/root）
- JPA 配置启用 SQL 日志输出和格式化，使用 MySQL 方言
- 目前项目缺少数据库脚本，需要手动创建表结构
- 没有环境特定配置文件，只有默认的 application.yml
- 项目中暂无测试文件和 API 文档

## Nacos 配置说明

所有服务使用统一的 Nacos 配置：
- 服务器地址：localhost:8848
- 命名空间：public
- 分组：DEFAULT_GROUP

启动服务前请确保 Nacos Server 已正常运行，访问 http://localhost:8848/nacos 查看服务注册状态。

## JPA 配置说明

所有服务使用统一的 JPA 配置：
```yaml
spring:
  datasource:
    driver-class-name: org.postgresql.Driver
    url: jdbc:postgresql://120.26.203.218:5432/{database_name}?useUnicode=true&characterEncoding=UTF-8&serverTimezone=Asia/Shanghai
    username: oizys
    password: ${PGSQL_PASSWD}  # 使用环境变量
  jpa:
    hibernate:
      ddl-auto: none  # 不自动创建表结构
    show-sql: true    # 显示 SQL 语句
    properties:
      hibernate:
        format_sql: true    # 格式化 SQL 输出
        dialect: org.hibernate.dialect.PostgreSQLDialect
    database-platform: org.hibernate.dialect.PostgreSQLDialect
```

## 数据库表结构示例

### 用户表 (ums_user)
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
```