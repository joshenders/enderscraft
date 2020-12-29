FROM debian-base-corretto:latest

LABEL org.opencontainers.image.authors="Josh Enders <josh.enders@gmail.com>"

ARG DATA_DIR
ARG MINECRAFT_GROUP
ARG MINECRAFT_HOME
ARG MINECRAFT_PORT
ARG MINECRAFT_USER

COPY files /

RUN     set -x \
    &&  useradd \
            --system \
            --shell /usr/sbin/nologin \
            --home "${MINECRAFT_HOME}" \
                "${MINECRAFT_USER}" \
    &&  chown \
            --recursive \
                "${MINECRAFT_USER}:${MINECRAFT_GROUP}" \
                "${MINECRAFT_HOME}" \
    &&  chmod \
            +x \
                "/healthcheck.sh" \
                "/entrypoint.sh"

ENV MINECRAFT_HOME="${MINECRAFT_HOME}" \
    ACCEPT_EULA="${ACCEPT_EULA}"

WORKDIR "${MINECRAFT_HOME}"
VOLUME ["${DATA_DIR}"]
EXPOSE ${MINECRAFT_PORT} ${RCON_PORT}

ENTRYPOINT ["/entrypoint.sh"]
HEALTHCHECK --start-period=1m CMD "/healthcheck.sh"
