# Redis 和 Elasticsearch 使用指南

## 概述

Demo Mall 项目已集成了 Redis 和 Elasticsearch 功能，提供了完整的配置和工具类支持：

- **Redis**: 在 `demo-mall-common` 模块中提供统一的缓存功能
- **Elasticsearch**: 在 `demo-mall-order` 和 `demo-mall-product` 模块中提供搜索功能

## Redis 使用指南

### 1. 配置

Redis 配置已在 `application-dev.yml` 中设置：

```yaml
spring:
  data:
    redis:
      host: localhost
      port: 6379
      timeout: 2000ms
      lettuce:
        pool:
          max-active: 8
          max-idle: 8
          min-idle: 0
```

### 2. 自动配置

项目已自动配置 Redis：
- `RedisConfig.java`: 配置 RedisTemplate 序列化
- `RedisUtil.java`: 提供常用的 Redis 操作方法

### 3. 使用示例

在 Service 类中注入 RedisUtil：

```java
@Service
public class UserServiceImpl implements UserService {

    @Autowired
    private RedisUtil redisUtil;

    public User getUserById(Long id) {
        // 先从缓存中获取
        String cacheKey = "user:" + id;
        User cachedUser = (User) redisUtil.get(cacheKey);
        if (cachedUser != null) {
            return cachedUser;
        }

        // 缓存中没有，从数据库查询
        User user = userMapper.findById(id);
        if (user != null) {
            // 存入缓存，有效期 30 分钟
            redisUtil.set(cacheKey, user, 1800);
        }

        return user;
    }

    public void updateUser(User user) {
        // 更新数据库
        userMapper.update(user);

        // 删除缓存
        String cacheKey = "user:" + user.getId();
        redisUtil.del(cacheKey);
    }
}
```

### 4. RedisUtil 主要方法

#### String 操作
```java
// 设置缓存
redisUtil.set("key", "value");
redisUtil.set("key", "value", 60); // 60秒过期

// 获取缓存
Object value = redisUtil.get("key");

// 删除缓存
redisUtil.del("key");
```

#### Hash 操作
```java
// 设置 hash
Map<String, Object> map = new HashMap<>();
map.put("name", "张三");
map.put("age", 25);
redisUtil.hmset("user:1", map);

// 获取 hash
Map<Object, Object> userMap = redisUtil.hmget("user:1");
String name = (String) redisUtil.hget("user:1", "name");
```

#### List 操作
```java
// 从右边推入
redisUtil.lSet("messages", "Hello");
redisUtil.lSet("messages", Arrays.asList("Hello", "World"));

// 获取列表
List<Object> messages = redisUtil.lGet("messages", 0, -1);
```

#### Set 操作
```java
// 添加成员
redisUtil.sSet("tags", "java", "spring", "redis");

// 获取所有成员
Set<Object> tags = redisUtil.sGet("tags");

// 判断是否存在
boolean exists = redisUtil.sHasKey("tags", "java");
```

#### ZSet 操作
```java
// 添加成员和分数
redisUtil.zSet("rankings", "user1", 100.0);
redisUtil.zSet("rankings", "user2", 95.5);

// 获取排行榜
Set<Object> topUsers = redisUtil.zRange("rankings", 0, 9);
```

## Elasticsearch 使用指南

### 1. 配置

Elasticsearch 配置已在 `application-dev.yml` 中设置：

```yaml
spring:
  elasticsearch:
    rest:
      uris: http://localhost:9200
      connection-timeout: 5s
      read-timeout: 30s
```

### 2. 自动配置

项目已为 order 和 product 模块配置 Elasticsearch：
- `ElasticsearchConfig.java`: 配置 ElasticsearchClient
- `ElasticsearchUtil.java`: 提供常用的 ES 操作方法

### 3. 使用示例

在 Service 类中注入 ElasticsearchUtil：

```java
@Service
public class ProductServiceImpl implements ProductService {

    @Autowired
    private ElasticsearchUtil elasticsearchUtil;

    // 创建商品索引
    @PostConstruct
    public void createProductIndex() {
        String mapping = """
        {
          "mappings": {
            "properties": {
              "id": {"type": "long"},
              "name": {"type": "text", "analyzer": "ik_max_word"},
              "description": {"type": "text", "analyzer": "ik_max_word"},
              "price": {"type": "double"},
              "category": {"type": "keyword"},
              "stock": {"type": "integer"},
              "createTime": {"type": "date"}
            }
          }
        }
        """;

        elasticsearchUtil.createIndex("products", mapping);
    }

    // 添加商品到索引
    public void indexProduct(Product product) {
        elasticsearchUtil.indexDocument("products",
            String.valueOf(product.getId()), product, Product.class);
    }

    // 全文搜索商品
    public List<Product> searchProducts(String keyword) {
        List<Hit<Product>> hits = elasticsearchUtil.fullTextSearch(
            "products", "name", keyword, Product.class);

        return hits.stream()
                .map(Hit::source)
                .collect(Collectors.toList());
    }

    // 价格范围搜索
    public List<Product> searchByPriceRange(Double minPrice, Double maxPrice) {
        List<Hit<Product>> hits = elasticsearchUtil.rangeSearch(
            "products", "price", minPrice, maxPrice, Product.class);

        return hits.stream()
                .map(Hit::source)
                .collect(Collectors.toList());
    }

    // 分页搜索
    public SearchResponse<Product> searchWithPage(String keyword, int page, int size) {
        Query query = Query.of(q -> q
                .match(m -> m
                        .field("name")
                        .query(keyword)
                )
        );

        return elasticsearchUtil.searchWithPage(
            "products", query, page * size, size, Product.class);
    }
}
```

### 4. ElasticsearchUtil 主要方法

#### 索引操作
```java
// 创建索引
boolean success = elasticsearchUtil.createIndex("products", mapping);

// 删除索引
boolean success = elasticsearchUtil.deleteIndex("products");

// 检查索引是否存在
boolean exists = elasticsearchUtil.indexExists("products");
```

#### 文档操作
```java
// 添加/更新文档
elasticsearchUtil.indexDocument("products", "1", product, Product.class);

// 获取文档
Product product = elasticsearchUtil.getDocument("products", "1", Product.class);

// 删除文档
elasticsearchUtil.deleteDocument("products", "1");

// 批量添加
List<Map<String, Object>> documents = ...;
elasticsearchUtil.bulkIndex("products", documents, Product.class);
```

#### 搜索操作
```java
// 全文搜索
List<Hit<Product>> results = elasticsearchUtil.fullTextSearch(
    "products", "name", "iPhone", Product.class);

// 精确匹配
List<Hit<Product>> results = elasticsearchUtil.termSearch(
    "products", "category", "electronics", Product.class);

// 范围搜索
List<Hit<Product>> results = elasticsearchUtil.rangeSearch(
    "products", "price", 1000.0, 5000.0, Product.class);

// 分页搜索
SearchResponse<Product> response = elasticsearchUtil.searchWithPage(
    "products", query, 0, 10, Product.class);

// 获取总数
long total = elasticsearchUtil.countDocuments("products");
```

## 最佳实践

### 1. Redis 使用建议

- **缓存键命名**: 使用有意义的命名规范，如 `user:profile:123`
- **过期时间**: 为缓存设置合理的过期时间，避免缓存雪崩
- **缓存更新**: 更新数据时及时删除或更新相关缓存
- **异常处理**: Redis 故障时不影响主业务流程

### 2. Elasticsearch 使用建议

- **索引设计**: 合理设计字段类型和分析器
- **批量操作**: 使用批量 API 提高性能
- **查询优化**: 避免深度分页，使用 scroll API 处理大量数据
- **监控指标**: 监控集群健康状态和查询性能

### 3. 性能优化

- **连接池配置**: 合理配置连接池大小
- **序列化优化**: 使用高效的序列化方式
- **索引分片**: 根据数据量设置合适的分片数
- **副本配置**: 设置适当的副本数提高可用性

## 故障排除

### Redis 常见问题
1. **连接超时**: 检查 Redis 服务状态和网络连接
2. **内存不足**: 调整 Redis 内存配置或设置数据淘汰策略
3. **序列化异常**: 检查对象序列化配置

### Elasticsearch 常见问题
1. **连接失败**: 检查 Elasticsearch 服务状态
2. **映射冲突**: 检查字段类型定义
3. **查询超时**: 优化查询或调整超时配置

## 监控和维护

### 监控指标
- Redis: 内存使用率、连接数、命令执行时间
- Elasticsearch: 集群状态、索引大小、查询响应时间

### 维护建议
- 定期清理过期缓存
- 监控索引大小和性能
- 定期备份重要数据
- 更新和升级依赖版本