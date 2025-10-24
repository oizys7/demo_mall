package com.oizys.mall.product.util;

import co.elastic.clients.elasticsearch.ElasticsearchClient;
import co.elastic.clients.elasticsearch._types.query_dsl.Query;
import co.elastic.clients.elasticsearch.core.*;
import co.elastic.clients.elasticsearch.core.search.Hit;
import co.elastic.clients.elasticsearch.indices.CreateIndexRequest;
import co.elastic.clients.elasticsearch.indices.DeleteIndexRequest;
import co.elastic.clients.elasticsearch.indices.ExistsRequest;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import java.io.StringReader;
import java.util.List;
import java.util.Map;

/**
 * Elasticsearch 工具类
 * 提供常用的 Elasticsearch 操作方法
 */
@Slf4j
@Component
public class ElasticsearchUtil {

    @Autowired
    private ElasticsearchClient elasticsearchClient;

    // =============================索引操作============================

    /**
     * 创建索引
     * @param indexName 索引名称
     * @param mapping 索引映射配置
     * @return true 创建成功，false 创建失败
     */
    public boolean createIndex(String indexName, String mapping) {
        try {
            CreateIndexRequest request = CreateIndexRequest.of(c -> c
                    .index(indexName)
                    .withJson(new StringReader(mapping))
            );

            elasticsearchClient.indices().create(request);
            log.info("创建索引成功: {}", indexName);
            return true;
        } catch (Exception e) {
            log.error("创建索引失败: {}", indexName, e);
            return false;
        }
    }

    /**
     * 删除索引
     * @param indexName 索引名称
     * @return true 删除成功，false 删除失败
     */
    public boolean deleteIndex(String indexName) {
        try {
            DeleteIndexRequest request = DeleteIndexRequest.of(c -> c
                    .index(indexName)
            );

            elasticsearchClient.indices().delete(request);
            log.info("删除索引成功: {}", indexName);
            return true;
        } catch (Exception e) {
            log.error("删除索引失败: {}", indexName, e);
            return false;
        }
    }

    /**
     * 判断索引是否存在
     * @param indexName 索引名称
     * @return true 存在，false 不存在
     */
    public boolean indexExists(String indexName) {
        try {
            ExistsRequest request = ExistsRequest.of(c -> c
                    .index(indexName)
            );

            return elasticsearchClient.indices().exists(request).value();
        } catch (Exception e) {
            log.error("判断索引是否存在失败: {}", indexName, e);
            return false;
        }
    }

    // =============================文档操作============================

    /**
     * 添加或更新文档
     * @param indexName 索引名称
     * @param documentId 文档ID
     * @param document 文档内容
     * @param clazz 文档类型
     * @return true 操作成功，false 操作失败
     */
    public <T> boolean indexDocument(String indexName, String documentId, T document, Class<T> clazz) {
        try {
            IndexRequest<T> request = IndexRequest.of(c -> c
                    .index(indexName)
                    .id(documentId)
                    .document(document)
            );

            elasticsearchClient.index(request);
            log.info("添加/更新文档成功: index={}, id={}", indexName, documentId);
            return true;
        } catch (Exception e) {
            log.error("添加/更新文档失败: index={}, id={}", indexName, documentId, e);
            return false;
        }
    }

    /**
     * 批量添加文档
     * @param indexName 索引名称
     * @param documents 文档列表
     * @param clazz 文档类型
     * @return true 操作成功，false 操作失败
     */
    public <T> boolean bulkIndex(String indexName, List<Map<String, Object>> documents, Class<T> clazz) {
        try {
            BulkRequest.Builder bulkBuilder = new BulkRequest.Builder();

            for (Map<String, Object> doc : documents) {
                String id = (String) doc.get("id");
                if (id == null) {
                    id = String.valueOf(doc.hashCode());
                }

                bulkBuilder.operations(op -> op
                        .index(idx -> idx
                                .index(indexName)
                                .id(id)
                                .document(doc)
                        )
                );
            }

            BulkResponse response = elasticsearchClient.bulk(bulkBuilder.build());

            if (response.errors()) {
                log.warn("批量添加文档部分失败: {}", response);
                return false;
            } else {
                log.info("批量添加文档成功: {} 条文档", documents.size());
                return true;
            }
        } catch (Exception e) {
            log.error("批量添加文档失败", e);
            return false;
        }
    }

    /**
     * 根据ID获取文档
     * @param indexName 索引名称
     * @param documentId 文档ID
     * @param clazz 文档类型
     * @return 文档内容，如果不存在返回null
     */
    public <T> T getDocument(String indexName, String documentId, Class<T> clazz) {
        try {
            GetRequest request = GetRequest.of(c -> c
                    .index(indexName)
                    .id(documentId)
            );

            GetResponse<T> response = elasticsearchClient.get(request, clazz);

            if (response.found()) {
                log.info("获取文档成功: index={}, id={}", indexName, documentId);
                return response.source();
            } else {
                log.warn("文档不存在: index={}, id={}", indexName, documentId);
                return null;
            }
        } catch (Exception e) {
            log.error("获取文档失败: index={}, id={}", indexName, documentId, e);
            return null;
        }
    }

    /**
     * 根据ID删除文档
     * @param indexName 索引名称
     * @param documentId 文档ID
     * @return true 删除成功，false 删除失败
     */
    public boolean deleteDocument(String indexName, String documentId) {
        try {
            DeleteRequest request = DeleteRequest.of(c -> c
                    .index(indexName)
                    .id(documentId)
            );

            elasticsearchClient.delete(request);
            log.info("删除文档成功: index={}, id={}", indexName, documentId);
            return true;
        } catch (Exception e) {
            log.error("删除文档失败: index={}, id={}", indexName, documentId, e);
            return false;
        }
    }

    // =============================搜索操作============================

    /**
     * 搜索文档
     * @param indexName 索引名称
     * @param query 查询条件
     * @param clazz 文档类型
     * @return 搜索结果
     */
    public <T> List<Hit<T>> search(String indexName, Query query, Class<T> clazz) {
        try {
            SearchRequest request = SearchRequest.of(c -> c
                    .index(indexName)
                    .query(query)
            );

            SearchResponse<T> response = elasticsearchClient.search(request, clazz);
            return response.hits().hits();
        } catch (Exception e) {
            log.error("搜索文档失败: index={}", indexName, e);
            return null;
        }
    }

    /**
     * 全文搜索
     * @param indexName 索引名称
     * @param field 搜索字段
     * @param keyword 搜索关键词
     * @param clazz 文档类型
     * @return 搜索结果
     */
    public <T> List<Hit<T>> fullTextSearch(String indexName, String field, String keyword, Class<T> clazz) {
        try {
            Query query = Query.of(q -> q
                    .match(m -> m
                            .field(field)
                            .query(keyword)
                    )
            );

            return search(indexName, query, clazz);
        } catch (Exception e) {
            log.error("全文搜索失败: index={}, field={}, keyword={}", indexName, field, keyword, e);
            return null;
        }
    }

    /**
     * 精确匹配搜索
     * @param indexName 索引名称
     * @param field 搜索字段
     * @param value 搜索值
     * @param clazz 文档类型
     * @return 搜索结果
     */
    public <T> List<Hit<T>> termSearch(String indexName, String field, String value, Class<T> clazz) {
        try {
            Query query = Query.of(q -> q
                    .term(t -> t
                            .field(field)
                            .value(value)
                    )
            );

            return search(indexName, query, clazz);
        } catch (Exception e) {
            log.error("精确匹配搜索失败: index={}, field={}, value={}", indexName, field, value, e);
            return null;
        }
    }

    /**
     * 范围搜索
     * @param indexName 索引名称
     * @param field 搜索字段
     * @param gte 大于等于
     * @param lte 小于等于
     * @param clazz 文档类型
     * @return 搜索结果
     */
    public <T> List<Hit<T>> rangeSearch(String indexName, String field, Object gte, Object lte, Class<T> clazz) {
        try {
            Query query = Query.of(q -> q
                    .range(r -> {
                        co.elastic.clients.elasticsearch._types.query_dsl.RangeQuery.Builder builder = r.field(field);
                        if (gte != null) {
                            builder.gte(co.elastic.clients.json.JsonData.of(gte));
                        }
                        if (lte != null) {
                            builder.lte(co.elastic.clients.json.JsonData.of(lte));
                        }
                        return builder;
                    })
            );

            return search(indexName, query, clazz);
        } catch (Exception e) {
            log.error("范围搜索失败: index={}, field={}, gte={}, lte={}", indexName, field, gte, lte, e);
            return null;
        }
    }

    /**
     * 分页搜索
     * @param indexName 索引名称
     * @param query 查询条件
     * @param from 起始位置
     * @param size 每页大小
     * @param clazz 文档类型
     * @return 搜索结果
     */
    public <T> SearchResponse<T> searchWithPage(String indexName, Query query, int from, int size, Class<T> clazz) {
        try {
            SearchRequest request = SearchRequest.of(c -> c
                    .index(indexName)
                    .query(query)
                    .from(from)
                    .size(size)
            );

            return elasticsearchClient.search(request, clazz);
        } catch (Exception e) {
            log.error("分页搜索失败: index={}, from={}, size={}", indexName, from, size, e);
            return null;
        }
    }

    /**
     * 获取索引文档总数
     * @param indexName 索引名称
     * @return 文档总数
     */
    public long countDocuments(String indexName) {
        try {
            SearchRequest request = SearchRequest.of(c -> c
                    .index(indexName)
                    .trackTotalHits(t -> t.enabled(true))
                    .size(0)
            );

            SearchResponse<Object> response = elasticsearchClient.search(request, Object.class);
            return response.hits().total().value();
        } catch (Exception e) {
            log.error("获取文档总数失败: index={}", indexName, e);
            return 0;
        }
    }

    /**
     * 根据查询条件获取文档总数
     * @param indexName 索引名称
     * @param query 查询条件
     * @return 文档总数
     */
    public long countByQuery(String indexName, Query query) {
        try {
            SearchRequest request = SearchRequest.of(c -> c
                    .index(indexName)
                    .query(query)
                    .trackTotalHits(t -> t.enabled(true))
                    .size(0)
            );

            SearchResponse<Object> response = elasticsearchClient.search(request, Object.class);
            return response.hits().total().value();
        } catch (Exception e) {
            log.error("根据查询条件获取文档总数失败: index={}", indexName, e);
            return 0;
        }
    }
}