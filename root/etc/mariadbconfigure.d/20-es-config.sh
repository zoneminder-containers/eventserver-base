#!/usr/bin/with-contenv bash
. "/usr/local/bin/logger"
# ==============================================================================
# es-config
# Configure default es Settings
# ==============================================================================
insert_command=""

if [ "$(mysql -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -h"${MYSQL_HOST}" zm \
    -e "SELECT Value FROM Config WHERE Name = 'ZM_AUTH_HASH_SECRET';" \
    | cut -f 2 \
    | sed -n '2 p')" == "...Change me to something unique..." ]; then

  echo "Configuring ZoneMinder API Defaults..." | init
  insert_command+="UPDATE Config SET Value = 'builtin' WHERE Name = 'ZM_AUTH_TYPE';"
  insert_command+="UPDATE Config SET Value = 'hashed' WHERE Name = 'ZM_AUTH_RELAY';"
  insert_command+="UPDATE Config SET Value = 0 WHERE Name = 'ZM_AUTH_HASH_IPS';"

  if [ "${USE_SECURE_RANDOM_ORG}" -eq "1" ]; then
    echo "Fetching random secure string for ZoneMinder API from random.org..." | init
    random_string=$(
      wget -qO - \
        "https://www.random.org/strings/?num=4&len=20&digits=on&upperalpha=on&loweralpha=on&unique=on&format=plain&rnd=new" \
      | tr -d '\n' \
    )
  else
    echo "Generating standard random string for ZoneMinder API..." | init
    random_string="$RANDOM$RANDOM$RANDOM$RANDOM$RANDOM$RANDOM$RANDOM$RANDOM$RANDOM$RANDOM$RANDOM$RANDOM$RANDOM$RANDOM$RANDOM"
  fi

  insert_command+="UPDATE Config SET Value = '${random_string}' WHERE Name = 'ZM_AUTH_HASH_SECRET';"

fi

echo "Forcibly enabling API and disabling ES daemon..." | info
insert_command+="UPDATE Config SET Value = 1 WHERE Name = 'ZM_OPT_USE_API';"
insert_command+="UPDATE Config SET Value = 0 WHERE Name = 'ZM_OPT_USE_EVENTNOTIFICATION';"

echo "Applying db changes..." | info
mysql -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -h"${MYSQL_HOST}" zm -e "${insert_command}"
