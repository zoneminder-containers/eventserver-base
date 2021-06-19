# eventserver-base

[![Docker Build](https://github.com/zoneminder-containers/eventserver-base/actions/workflows/docker-build.yaml/badge.svg)](https://github.com/zoneminder-containers/eventserver-base/actions/workflows/docker-build.yaml)
[![DockerHub Pulls](https://img.shields.io/docker/pulls/yaoa/eventserver-base.svg)](https://hub.docker.com/r/yaoa/eventserver-base)
![Status](https://img.shields.io/badge/Status-WIP-orange)

# Variables

New environment variables available in addition to zoneminder-base
1. ES_DEBUG_ENABLED
    - Enables --debug flag for event notification when set to 1
2. ES_COMMON_NAME
    - Defines common name for accessing zoneminder
3. ES_ENABLE_AUTH
    - Controls ES/ZM Authentication
4. USE_SECURE_RANDOM_ORG
    - Use random.org for api random string generation. Otherwise uses bash random.


# Certificates
If a certificate is located at `/config/ssl/cert.cer` with a corresponding
private key at `/config/ssl/key.pem`, a self-signed certificate will not be
generated. Otherwise, one will be automatically generated using the common name
environment variable.
