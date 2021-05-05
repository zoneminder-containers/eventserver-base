#!/usr/bin/with-contenv bash
. "/usr/local/bin/logger"
program_name="es-config"

# Install es config if not existing
if [ ! -f "/config/zmeventnotification.ini" ]; then
  echo "Copying ES Configuration" | init "[${program_name}] "
  s6-setuidgid www-data \
    cp -r /zoneminder/defaultconfiges/* /config
fi

echo "Setting ES ZoneMinder URL" | info "[${program_name}] "
sed -i "s|^ZMES_PICTURE_URL=.*$|ZMES_PICTURE_URL=https://${ES_COMMON_NAME}/index.php?view=image\&eid=EVENTID\&fid=objdetect\&width=600|g" /config/secrets.ini
sed -i "s|^ZM_PORTAL=.*$|ZM_PORTAL=https://${ES_COMMON_NAME}|g" /config/secrets.ini

echo "Configuring ZoneMinder Common Name in Nginx Config" | info "[${program_name}] "
sed -i "s|ES_COMMON_NAME|${ES_COMMON_NAME}|g" /etc/nginx/conf.d/ssl.conf
