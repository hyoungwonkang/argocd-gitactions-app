#=============================================================================
# [Stage 1] Build Stage
#=============================================================================
# Gradle이 설치된 이미지를 사용하여 소스 코드를 빌드합니다.
FROM gradle:8.5-jdk17-alpine AS builder

WORKDIR /build

# 1. Gradle 설정 파일들만 먼저 복사합니다.
# 소스 코드(src)는 아직 복사하지 않습니다.
COPY build.gradle settings.gradle ./

# 2. 의존성을 다운로드합니다.
# 소스 코드가 없어도 의존성 목록(build.gradle)만 있으면 라이브러리를 받을 수 있습니다.
# 이 단계(Layer)는 build.gradle이 바뀌지 않는 한 캐시(Cache)에서 재사용됩니다.
RUN gradle dependencies --no-daemon

# 3. 이제 실제 소스 코드를 복사합니다.
# 코드를 수정하면, Docker는 여기서부터 다시 빌드를 수행합니다. (캐시해 두었으므로)
# 위 2번 단계(RUN)까지는 건너뛰고 바로 여기로 옵니다. (속도 향상)
COPY src ./src

# 4. 빌드 수행 (이미 라이브러리는 다운로드되어 있음)
# bootJar 태스크를 통해 실행 가능한 jar만 생성합니다.
RUN gradle clean bootJar --no-daemon

#=============================================================================
# [Stage 2] Runner Stage
#=============================================================================
# 실행에 필요한 경량화된 JRE 이미지만 사용합니다. (용량 절감)
FROM eclipse-temurin:17-jre-alpine

WORKDIR /app

# builder 스테이지에서 생성된 JAR 파일만 복사해옵니다. (builder 스테이지는 이미지에 불포함)
COPY --from=builder /build/build/libs/*.jar app.jar

ENTRYPOINT ["java", "-jar", "app.jar"]