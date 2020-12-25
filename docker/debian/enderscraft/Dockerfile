FROM debian-base-corretto:latest

LABEL org.opencontainers.image.authors="Josh Enders <josh.enders@gmail.com>"

ARG DATA_DIR
ARG SERVICE_GROUP
ARG SERVICE_HOME
ARG SERVICE_PORT
ARG SERVICE_USER

COPY files /

RUN     set -x \
    &&  useradd \
            --system \
            --shell /usr/sbin/nologin \
            --home "${SERVICE_HOME}" \
                "${SERVICE_USER}" \
    &&  chown \
            --recursive \
                "${SERVICE_USER}:${SERVICE_GROUP}" \
                "${SERVICE_HOME}" \
    &&  chmod \
            +x \
                "/healthcheck.sh" \
                "/entrypoint.sh"

ENV SERVICE_HOME="${SERVICE_HOME}" \
    ACCEPT_EULA="${ACCEPT_EULA}"

WORKDIR "${SERVICE_HOME}"
VOLUME ["${DATA_DIR}"]
EXPOSE ${SERVICE_PORT} ${RCON_PORT}

ENTRYPOINT ["/entrypoint.sh"]
HEALTHCHECK --start-period=1m CMD "/healthcheck.sh"