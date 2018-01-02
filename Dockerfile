# See: https://hub.docker.com/_/python/
# Arguments from docker build proccess
ARG PYTHON_VERSION=3.6.4
ARG ALPINE_VERSION=3.7
FROM python:${PYTHON_VERSION}-alpine${ALPINE_VERSION}

# Extra arguments from docker build proccess
ARG AIRFLOW_VERSION

# Environment variables
ENV AIRFLOW_VERSION=${AIRFLOW_VERSION:-1.8.2} \
    AIRFLOW_USER="airflow" \
    AIRFLOW_GROUP="airflow" \
    AIRFLOW_HOME="/apache-airflow" \
    LANGUAGE=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    LC_CTYPE=en_US.UTF-8 \
    LC_MESSAGES=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

# Container Labels
LABEL maintainer="Christian González Di Antonio <christiangda@gmail.com>" \
    org.opencontainers.image.authors="Christian González Di Antonio <christiangda@gmail.com>" \
    org.opencontainers.image.url="https://github.com/christiangda/docker-apache-airflow" \
    org.opencontainers.image.documentation="https://github.com/christiangda/docker-apache-airflow" \
    org.opencontainers.image.source="https://github.com/christiangda/docker-apache-airflow" \
    org.opencontainers.image.version="${PYTHON_VERSION}-${AIRFLOW_VERSION}-alpine" \
    org.opencontainers.image.vendor="Christian González Di Antonio <christiangda@gmail.com>" \
    org.opencontainers.image.licenses="Apache License Version 2.0" \
    org.opencontainers.image.title="Apache Airflow" \
    org.opencontainers.image.description="Apache Airflow docker image"

# Extra container labels
LABEL Build="docker build --no-cache --rm \
            --build-arg PYTHON_VERSION=3.6.4 \
            --build-arg AIRFLOW_VERSION=1.8.2 \
            --build-arg ALPINE_VERSION=3.7 \
            --tag christiangda/apache-airflow:3.6.4-1.8.2-alpine \
            --tag christiangda/apache-airflow:1.8.2-alpine \
            --tag christiangda/apache-airflow:1.8.2 \
            --tag christiangda/apache-airflow:latest ." \
    Run="docker run --tty --interactive --rm --name \"airflow-01\" -p 8080:8080 christiangda/apache-airflow" \
    Connect="docker exec --tty --interactive <container id from 'doclogsker ps' command> bash"

# Service user
RUN addgroup -g 1000 ${AIRFLOW_GROUP} \
    && mkdir -p ${AIRFLOW_HOME} \
    && mkdir -p "${AIRFLOW_HOME}/dags" \
    && adduser -u 1000 -S -D -G ${AIRFLOW_GROUP} -h ${AIRFLOW_HOME} -s /sbin/nologin -g "Apache Airflow" ${AIRFLOW_USER} \
    && chmod 755 ${AIRFLOW_HOME} \
    && chown -R ${AIRFLOW_USER}.${AIRFLOW_GROUP} ${AIRFLOW_HOME}

# Copy provisioning files
# COPY provisioning/* ${AIRFLOW_HOME}/provisioning/
# RUN chmod +x ${AIRFLOW_HOME}/provisioning/*.sh

# OS dependencies
RUN apk --no-cache --update-cache update \
    && apk --no-cache --update-cache upgrade \
    && apk --no-cache --update-cache add \
        bash \
        git \
        ca-certificates \
        gcc \
        py3-libxml2 \
        linux-headers \
        build-base \
        freetype-dev \
        libpng-dev \
        openblas-dev \
        libxml2-dev \
        libxslt-dev \
        python3-dev \
        mariadb-dev \
        postgresql-dev \
        libffi-dev \
        freetds-dev \
        musl-dev \
    && ln -s /usr/include/locale.h /usr/include/xlocale.h

# Apache Airflow and its plugins
RUN pip install \
        Cython \
        celery[librabbitmq,redis,auth,msgpack] \
        cryptography \        
        apache-airflow==${AIRFLOW_VERSION} \
        apache-airflow[all] \
    && apk del \
        build-base \
        linux-headers \
    && rm -rf /tmp/* /var/tmp/* /var/cache/apk/* /root/.cache \
    && chown -R ${AIRFLOW_USER}.${AIRFLOW_GROUP} ${AIRFLOW_HOME}

# Exposed ports
EXPOSE 8080 5555 8793

VOLUME ${AIRFLOW_HOME}

USER ${AIRFLOW_USER}
WORKDIR ${AIRFLOW_HOME}

# Force any command provision the container
#ENTRYPOINT ["provisioning/docker-entrypoint.sh"]

# Default command to run on boot
#CMD [""]