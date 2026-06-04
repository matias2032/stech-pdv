# ─────────────────────────────────────────
# STAGE 1 — Build
# ─────────────────────────────────────────
FROM maven:3.9.6-eclipse-temurin-17 AS builder

WORKDIR /app

# Copia o pom.xml primeiro (aproveita cache do Docker se as deps não mudarem)
COPY pdv-backend/pom.xml .
RUN mvn dependency:go-offline -q

# Copia o código fonte e faz o build (sem testes)
COPY pdv-backend/src ./src
RUN mvn package -DskipTests -q

# ─────────────────────────────────────────
# STAGE 2 — Runtime (imagem mínima)
# ─────────────────────────────────────────
FROM eclipse-temurin:17-jre-alpine

WORKDIR /app

# Cria utilizador não-root (boa prática de segurança)
RUN addgroup -S spring && adduser -S spring -G spring

# Copia apenas o JAR gerado no stage anterior
COPY --from=builder /app/target/*.jar app.jar

USER spring

# O Render injeta a variável PORT automaticamente
EXPOSE 8080

# Flags JVM optimizadas para containers (evita OOM no free tier)
ENTRYPOINT ["java", \
  "-XX:+UseContainerSupport", \
  "-XX:MaxRAMPercentage=75.0", \
  "-Djava.security.egd=file:/dev/./urandom", \
  "-Dspring.profiles.active=prod", \
  "-jar", "app.jar"]