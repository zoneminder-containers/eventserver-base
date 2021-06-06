# eventserver-base

<img src="https://img.shields.io/badge/Status-WIP-orange" alt="Status">

# Variables

New environment variables available in addition to zoneminder-base
1. ES_DEBUG_ENABLED
    - Enables --debug flag for event notification when set to 1
2. ES_COMMON_NAME
    - Defines common name for accessing zoneminder


# Certificates
If a certificate is located at `/config/ssl/cert.cer` with a corresponding
private key at `/config/ssl/key.pem`, a self-signed certificate will not be
generated. Otherwise, one will be automatically generated using the common name
environment variable.