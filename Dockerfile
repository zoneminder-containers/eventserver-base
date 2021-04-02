# syntax=docker/dockerfile:experimental
ARG ZM_BASE=main
ARG BETA=0

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

FROM ghcr.io/zoneminder-containers/zoneminder-base:${ZM_BASE}

RUN apt-get update \
    && apt-get install -y \
        build-essential \
        libjson-perl \
    && PERL_MM_USE_DEFAULT=1 \
    && perl -MCPAN -e "install Net::WebSocket::Server" \
    && perl -MCPAN -e "install LWP::Protocol::https" \
    && perl -MCPAN -e "install Config::IniFiles" \
    && perl -MCPAN -e "install Time::Piece" \
    && perl -MCPAN -e "install Net::MQTT::Simple"

