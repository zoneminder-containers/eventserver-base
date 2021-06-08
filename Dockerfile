# syntax=docker/dockerfile:experimental
ARG ZM_VERSION=main
ARG ES_VERSION=master

FROM alpine:latest AS eventserverdownloader
ARG ES_VERSION
WORKDIR /eventserverdownloader

RUN set -x \
    && apk add git \
    && git clone https://github.com/pliablepixels/zmeventnotification.git . \
    && git checkout ${ES_VERSION}

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

#####################################################################
#                                                                   #
# Install ES                                                        #
# Apply changes to default ES config                                #
#                                                                   #
#####################################################################
FROM ghcr.io/zoneminder-containers/zoneminder-base:${ZM_VERSION}

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
    && cp ./tools/* /zoneminder/estools

# Fix default es config
RUN set -x \
    && pip3 install ConfigUpdater \
    && python3 -u /zoneminder/estools/config_edit.py \
        --config /zoneminder/defaultconfiges/zmeventnotification.ini \
        --output /zoneminder/defaultconfiges/zmeventnotification.ini \
        --set \
            general:secrets="/config/secrets.ini" \
            fcm:token_file="/config/tokens.txt" \
            customize:console_logs="yes" \
            network:address="0.0.0.0" \
            auth:enable="no" \
    && python3 -u /zoneminder/estools/config_edit.py \
        --config /zoneminder/defaultconfiges/secrets.ini \
        --output /zoneminder/defaultconfiges/secrets.ini \
        --set \
            secrets:ES_CERT_FILE="/config/ssl/cert.cer" \
            secrets:ES_KEY_FILE="/config/ssl/key.pem"

# Copy rootfs
COPY --from=rootfs-converter /rootfs /

ENV \
    ES_DEBUG_ENABLED=1 \
    ES_COMMON_NAME=localhost \
    ES_ENABLE_AUTH=0 \
    ES_ENABLE_DHPARAM=1

LABEL \
    com.github.alexyao2015.es_version=${ES_VERSION}
