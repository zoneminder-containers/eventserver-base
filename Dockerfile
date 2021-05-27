# syntax=docker/dockerfile:experimental
ARG ZM_BASE=main
ARG BETA=1

FROM alpine:latest AS eventserverdownloader
ARG BETA
WORKDIR /eventserverdownloader
ENV REPO="pliablepixels/zmeventnotification"

RUN if [ "${BETA}" -eq "0" ]; then \
        LATEST_VERSION=$(wget --no-check-certificate -qO - https://api.github.com/repos/"${REPO}"/releases/latest | awk '/tag_name/{print $4;exit}' FS='[""]'); \
        URL="https://github.com/"${REPO}"/archive/refs/tags/${LATEST_VERSION}.tar.gz"; \
    else \
        URL="https://github.com/pliablepixels/zmeventnotification/archive/refs/heads/master.tar.gz"; \
    fi \
    && wget -O /tmp/eventserver.tar.gz "${URL}" \
    && mkdir -p /tmp/eventserver \
    && tar zxvf /tmp/eventserver.tar.gz --strip 1 -C /tmp/eventserver \
    && cp -r /tmp/eventserver/* .

#####################################################################
#                                                                   #
# Convert rootfs to LF using dos2unix                               #
# Alleviates issues when git uses CRLF on Windows                   #
#                                                                   #
#####################################################################
FROM alpine:latest as rootfs-converter
WORKDIR /rootfs

RUN set -x \
    && apk add --repository=http://dl-cdn.alpinelinux.org/alpine/edge/community/ \
        dos2unix

COPY root .
RUN set -x \
    && find . -type f -print0 | xargs -0 -n 1 -P 4 dos2unix

FROM ghcr.io/zoneminder-containers/zoneminder-base:${ZM_BASE}

RUN set -x \
    && apt-get update \
    && apt-get install -y \
        build-essential \
        libjson-perl \
        python3-pip \
    && PERL_MM_USE_DEFAULT=1 \
    && yes | perl -MCPAN -e "install Net::WebSocket::Server" \
    && yes | perl -MCPAN -e "install LWP::Protocol::https" \
    && yes | perl -MCPAN -e "install Config::IniFiles" \
    && yes | perl -MCPAN -e "install Time::Piece" \
    && yes | perl -MCPAN -e "install Net::MQTT::Simple" \
    && apt-get remove --purge -y \
        build-essential \
    && rm -rf /var/lib/apt/lists/*

RUN --mount=type=bind,target=/tmp/eventserver,source=/eventserverdownloader,from=eventserverdownloader,rw \
    set -x \
    && cd /tmp/eventserver \
    && mkdir -p /zoneminder/defaultconfiges \
    && TARGET_CONFIG=/zoneminder/defaultconfiges \
        MAKE_CONFIG_BACKUP='' \
        ./install.sh \
            --install-es \
            --no-install-hook \
            --install-config \
            --no-interactive \
            --no-pysudo \
            --no-hook-config-upgrade \
    && cp ./tools/config_upgrade.py /zoneminder

# Fix default es config
RUN set -x \
    && sed -i "s|^secrets.*=.*$|secrets=/config/secrets.ini|g" /zoneminder/defaultconfiges/zmeventnotification.ini \
    && sed -i "s|^token_file.*=.*$|token_file=/config/tokens.txt|g" /zoneminder/defaultconfiges/zmeventnotification.ini \
    && sed -i "s|^console_logs.*=.*$|console_logs=yes|g" /zoneminder/defaultconfiges/zmeventnotification.ini \
    && sed -i "s|^ES_CERT_FILE=.*$|ES_CERT_FILE=/config/ssl/cert.cer|g" /zoneminder/defaultconfiges/secrets.ini \
    && sed -i "s|^ES_KEY_FILE=.*$|ES_KEY_FILE=/config/ssl/key.pem|g" /zoneminder/defaultconfiges/secrets.ini

# Copy rootfs
COPY --from=rootfs-converter /rootfs /

ENV \
    ES_DEBUG_ENABLED=1 \
    ES_COMMON_NAME=localhost