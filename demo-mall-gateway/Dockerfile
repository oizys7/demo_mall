# Gateway 服务生产环境 Dockerfile
# 基于模板构建的超轻量化生产环境

# 构建阶段 - 使用 Maven 构建应用
FROM --platform=$BUILDPLATFORM maven:3.9-alpine AS builder

# 设置构建参数
ARG TARGETPLATFORM
ARG BUILDPLATFORM
ARG APP_VERSION=1.0.0

# 设置工作目录
WORKDIR /app

# 安装必要的工具
RUN apk add --no-cache curl unzip

# 复制 Maven 配置文件
COPY pom.xml .

# 下载依赖（利用 Docker 层缓存）
RUN mvn dependency:go-offline -B

# 复制源代码
COPY src ./src

# 生产环境构建（包含所有检查）
RUN mvn clean package -DskipTests=false

# 运行阶段 - 超轻量化运行时环境
FROM --platform=$TARGETPLATFORM eclipse-temurin:21-jre-alpine

# 设置运行时参数
ARG APP_NAME=demo-mall-gateway
ARG APP_VERSION=1.0.0
ARG JAR_FILE=demo-mall-gateway-1.0.0.jar

# 只安装运行时必需的包
RUN apk add --no-cache \
    curl \
    tzdata \
    && rm -rf /var/cache/apk/* \
    && rm -rf /tmp/* \
    && rm -rf /var/tmp/*

# 设置时区
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 创建应用用户（安全考虑）
RUN addgroup -g 1000 -S appuser && \
    adduser -u 1000 -S appuser -G appuser

# 设置工作目录
WORKDIR /app

# 复制 JAR 文件
COPY --from=builder /app/target/${JAR_FILE} app.jar

# 创建非特权数据目录
RUN mkdir -p /app/data /app/logs && \
    chown -R appuser:appuser /app

# 切换到应用用户
USER appuser

# 生产环境 JVM 参数（优化内存和性能）
ENV JAVA_OPTS="-Xmx256m -Xms128m -XX:+UseG1GC -XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap -Djava.security.egd=file:/dev/./urandom -Dfile.encoding=UTF-8 -Duser.timezone=Asia/Shanghai -Dspring.profiles.active=prod"

# 健康检查（生产环境配置）
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=5 \
    CMD curl -f http://localhost:9100/actuator/health || exit 1

# 暴露端口
EXPOSE 9100

# 数据卷
VOLUME ["/app/data", "/app/logs"]

# 启动命令（生产环境）
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]