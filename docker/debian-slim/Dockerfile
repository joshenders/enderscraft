FROM debian:buster-slim as debian-base

LABEL org.opencontainers.image.authors="Josh Enders <josh.enders@gmail.com>"

RUN apt-get update \
    && apt-get install \
    --assume-yes \
    --no-install-recommends \
    ca-certificates \
    python3-minimal \
    && apt-get clean \
    --assume-yes \
    && rm \
    --recursive \
    --force \
    /var/lib/apt/lists/*

# KLUDGE: debian-slim variants do not have man page dirs (which causes
# 'update-alternatives' to fail) -- https://github.com/debuerreotype/debuerreotype/issues/10
RUN mkdir \
    --parents \
    --verbose \
    /usr/share/man/man1

FROM debian-base

LABEL org.opencontainers.image.authors="Josh Enders <josh.enders@gmail.com>"

ARG DATA_DIR
ARG SERVICE_USER
ARG SERVICE_GROUP
ARG SERVICE_HOME
ARG SERVICE_PORT
ARG JAVA_PACKAGE
ARG LISTEN_PORT

COPY files /

RUN apt-get update \
    && apt-get install \
    --assume-yes \
    --no-install-recommends \
    ${JAVA_PACKAGE} \
    && apt-get clean \
    --assume-yes \
    && rm \
    --recursive \
    --force \
    /var/lib/apt/lists/*

RUN useradd \
    --system \
    --shell /usr/sbin/nologin \
    --home ${SERVICE_HOME} \
    ${SERVICE_USER} \
    && chown \
    --recursive \
    ${SERVICE_USER}:${SERVICE_GROUP} \
    ${SERVICE_HOME}

# rcon-cli
# mc-monitor
# mc-server-runner

# COPY files/server.properties /tmp/server.properties
# COPY files/log4j2.xml /tmp/log4j2.xml
# COPY start* /
# COPY health.sh /
# ADD files/autopause /autopause

# ENV UID=1000 \
#     GID=1000 \
#     JVM_XX_OPTS="-XX:+UseG1GC" \
#     MEMORY=${JVM_MEMORY} \
#     TYPE=VANILLA \
#     VERSION=LATEST \
#     LEVEL=world \
#     PVP=true \
#     DIFFICULTY=easy \
#     ENABLE_RCON=true \
#     RCON_PORT=25575 \
#     RCON_PASSWORD=minecraft \
#     LEVEL_TYPE=DEFAULT \
#     SERVER_PORT=25565 \
#     ONLINE_MODE=TRUE \
#     SERVER_NAME="Dedicated Server" \
#     ENABLE_AUTOPAUSE=false \
#     AUTOPAUSE_TIMEOUT_EST=3600 \
#     AUTOPAUSE_TIMEOUT_KN=120 \
#     AUTOPAUSE_TIMEOUT_INIT=600 \
#     AUTOPAUSE_PERIOD=10

WORKDIR ${SERVICE_HOME}
VOLUME ["${DATA_DIR}"]
EXPOSE ${LISTEN_PORT} ${RCON_PORT}

# ENTRYPOINT [ "/entrypoint.py" ]
# HEALTHCHECK --start-period=1m CMD /health.sh