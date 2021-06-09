#!/usr/bin/with-contenv bash
. "/usr/local/bin/logger"
program_name="es-config"

# Install es config if not existing
if [ ! -f "/config/zmeventnotification.ini" ]; then
  echo "Copying ES Configuration" | init "[${program_name}] "
  s6-setuidgid www-data \
    cp -r /zoneminder/defaultconfiges/* /config
fi

echo "Setting ES ZoneMinder URL settings..." | info "[${program_name}] "

python3 -u /zoneminder/estools/config_edit.py \
    --config /config/secrets.ini \
    --output /config/secrets.ini \
    --set \
        secrets:ZMES_PICTURE_URL="https://${ES_COMMON_NAME}/index.php?view=image\&eid=EVENTID\&fid=objdetect\&width=600" \
        secrets:ZM_PORTAL="https://${ES_COMMON_NAME}"

echo "Setting ES ZoneMinder Auth settings..." | info "[${program_name}] "
enable_auth="no"
if [ "${ES_ENABLE_AUTH}" -eq "1" ]; then
  enable_auth="yes"
fi

python3 -u /zoneminder/estools/config_edit.py \
        --config /config/zmeventnotification.ini \
        --output /config/zmeventnotification.ini \
        --set \
          auth:enable="${enable_auth}"

echo "Configuring ZoneMinder Common Name in Nginx Config" | info "[${program_name}] "
sed -i "s|ES_COMMON_NAME|${ES_COMMON_NAME}|g" /etc/nginx/conf.d/ssl.conf
