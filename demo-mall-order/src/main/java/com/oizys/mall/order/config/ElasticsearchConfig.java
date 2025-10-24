package com.oizys.mall.order.config;

import co.elastic.clients.elasticsearch.ElasticsearchClient;
import co.elastic.clients.json.jackson.JacksonJsonpMapper;
import co.elastic.clients.transport.ElasticsearchTransport;
import co.elastic.clients.transport.rest_client.RestClientTransport;
import org.apache.http.Header;
import org.apache.http.HttpHost;
import org.apache.http.message.BasicHeader;
import org.elasticsearch.client.RestClient;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Elasticsearch 配置类
 * 配置 Elasticsearch 客户端连接
 */
@Configuration
public class ElasticsearchConfig {

    @Value("${spring.elasticsearch.rest.uris:http://localhost:9200}")
    private String[] elasticsearchUris;

    @Value("${spring.elasticsearch.rest.connection-timeout:5s}")
    private String connectionTimeout;

    @Value("${spring.elasticsearch.rest.read-timeout:30s}")
    private String readTimeout;

    /**
     * 创建 Elasticsearch 客户端
     */
    @Bean
    public ElasticsearchClient elasticsearchClient() {
        // 解析主机地址
        HttpHost[] hosts = parseHosts();

        // 创建 RestClient
        RestClient restClient = RestClient.builder(hosts)
                .setDefaultHeaders(new Header[]{
                        new BasicHeader("Content-Type", "application/json")
                })
                .setRequestConfigCallback(builder ->
                    builder.setConnectTimeout(parseTimeout(connectionTimeout))
                           .setSocketTimeout(parseTimeout(readTimeout)))
                .build();

        // 创建 Transport
        ElasticsearchTransport transport = new RestClientTransport(
                restClient, new JacksonJsonpMapper());

        // 创建 API 客户端
        return new ElasticsearchClient(transport);
    }

    /**
     * 解析主机地址
     */
    private HttpHost[] parseHosts() {
        HttpHost[] hosts = new HttpHost[elasticsearchUris.length];
        for (int i = 0; i < elasticsearchUris.length; i++) {
            String uri = elasticsearchUris[i];
            // 移除 http:// 或 https:// 前缀
            if (uri.startsWith("http://")) {
                uri = uri.substring(7);
            } else if (uri.startsWith("https://")) {
                uri = uri.substring(8);
            }

            // 分割主机和端口
            String[] parts = uri.split(":");
            if (parts.length == 2) {
                hosts[i] = new HttpHost(parts[0], Integer.parseInt(parts[1]), "http");
            } else {
                hosts[i] = new HttpHost(parts[0], 9200, "http");
            }
        }
        return hosts;
    }

    /**
     * 解析超时时间字符串为毫秒
     */
    private int parseTimeout(String timeout) {
        if (timeout.endsWith("s")) {
            return Integer.parseInt(timeout.substring(0, timeout.length() - 1)) * 1000;
        } else if (timeout.endsWith("ms")) {
            return Integer.parseInt(timeout.substring(0, timeout.length() - 2));
        } else {
            return Integer.parseInt(timeout);
        }
    }
}