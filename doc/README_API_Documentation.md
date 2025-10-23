# Demo Mall API 文档使用指南

## 概述

本项目已集成 **SpringDoc OpenAPI** 来自动生成和维护API文档。所有微服务的API文档都可以通过以下方式访问：

## 文档访问地址

### 各服务独立文档

1. **用户服务文档**
   - 地址: http://localhost:9201/swagger-ui.html
   - OpenAPI JSON: http://localhost:9201/v3/api-docs

2. **商品服务文档**
   - 地址: http://localhost:9202/swagger-ui.html
   - OpenAPI JSON: http://localhost:9202/v3/api-docs

3. **订单服务文档**
   - 地址: http://localhost:9203/swagger-ui.html
   - OpenAPI JSON: http://localhost:9203/v3/api-docs

### 网关聚合文档

- **统一访问入口**: http://localhost:9100/swagger-ui.html
- **聚合OpenAPI**: http://localhost:9100/v3/api-docs

## 功能特性

### 1. 自动API发现
- 自动扫描所有Spring Controller
- 根据注解自动生成API描述
- 支持路径参数、请求体、响应类型等

### 2. 交互式文档
- 在线测试API功能
- 支持JWT认证测试
- 自动填充示例数据
- 请求/响应格式展示

### 3. 多格式支持
- JSON格式的API描述
- HTML格式的用户界面
- 支持导入到其他工具（Postman、Insomnia等）

## 主要注解说明

### @Tag
- 用于对Controller进行分组
- 示例：`@Tag(name = "用户管理", description = "用户相关的操作接口")`

### @Operation
- 描述具体API接口的功能
- 示例：`@Operation(summary = "获取用户列表", description = "获取所有用户的列表信息")`

### @Parameter
- 描述API参数
- 示例：`@Parameter(description = "用户ID", required = true, example = "1")`

### @RequestBody
- 描述请求体参数
- 示例：`@RequestBody(description = "用户信息", required = true)`

### @ApiResponse
- 描述API响应
- 示例：`@ApiResponse(responseCode = "200", description = "成功获取用户列表")`

### @Schema
- 描述实体类和字段
- 示例：`@Schema(description = "用户ID", example = "1")`

## 使用说明

### 启动服务
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

### 访问文档
1. 确保所有服务已启动
2. 访问 http://localhost:9000/swagger-ui.html
3. 选择需要查看的服务API
4. 点击API可查看详细信息
5. 使用"Try it out"功能测试API

### JWT认证测试
如果API需要JWT认证：
1. 点击文档右上角的"Authorize"按钮
2. 在弹出框中输入JWT Token
3. 格式为：`Bearer your_jwt_token_here`
4. 点击"Authorize"完成认证
5. 所有后续API请求将自动携带认证信息

## 开发建议

### 1. 添加新API时
- 使用完整的注解描述
- 提供清晰的示例数据
- 添加响应码说明

### 2. 实体类注解
- 为所有字段添加@Schema注解
- 提供合理的示例值
- 描述字段的约束条件

### 3. 测试数据
- 在开发环境中使用有意义的测试数据
- 确保示例数据的真实性
- 覆盖各种数据场景

## 故障排除

### 常见问题
1. **文档页面无法访问**
   - 确保服务已正常启动
   - 检查端口是否被占用
   - 查看服务日志是否有错误

2. **API测试失败**
   - 检查请求数据格式
   - 确认数据库连接正常
   - 查看服务端日志

3. **认证不生效**
   - 确认JWT Token格式正确
   - 检查Token是否过期
   - 验证认证配置是否正确

## 扩展功能

未来可以考虑的功能扩展：
- 添加API版本管理
- 集成自动化API测试
- 添加API监控和统计
- 支持导出PDF文档