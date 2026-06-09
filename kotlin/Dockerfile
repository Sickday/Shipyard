# Forgejo Actions CI image for the Kotlin clients.
#   - BlackLobster/Client: raw `kotlinc -include-runtime` -> needs the
#     standalone Kotlin compiler on PATH (no Gradle).
#   - high_level_alchemy/Client/377: Gradle 9.0 via ./gradlew -> the wrapper
#     self-downloads Gradle, so only a JDK is required here.
# Both are plain JVM (NOT Android), so no Android SDK is needed.
# Pushed as sickday/kotlin:latest (see .github/workflows/ci-images.yml).
FROM eclipse-temurin:21-jdk

# Matches high_level_alchemy's Kotlin Gradle plugin (2.1.20); recent enough for
# BlackLobster's `kotlinc -jvm-target 21`. Bump as needed.
ARG KOTLIN_VERSION=2.1.20
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl unzip zip git ca-certificates nodejs npm \
    && rm -rf /var/lib/apt/lists/* \
    && curl -fsSL -o /tmp/kotlin.zip \
        "https://github.com/JetBrains/kotlin/releases/download/v${KOTLIN_VERSION}/kotlin-compiler-${KOTLIN_VERSION}.zip" \
    && unzip -q /tmp/kotlin.zip -d /opt \
    && rm /tmp/kotlin.zip
ENV PATH="/opt/kotlinc/bin:${PATH}"

# node is required because Forgejo runs JS actions (actions/checkout, etc.)
# with `node` INSIDE this job container — same reason the other Shipyard
# images are "<lang>/node" variants.
RUN java -version && kotlinc -version && node --version
