#!/bin/bash
set -e

# Setup the host for the environment
DOMAINNAME="$(hostname -d)"
if [ -z "$DOMAINNAME" ]; then
    echo "The domain is not set"
    exit 1;
fi

VIRTUAL_HOST="/etc/prosody/conf.avail/${DOMAINNAME}.cfg.lua"
mv /etc/prosody/conf.avail/host_skel.cfg.lua $VIRTUAL_HOST
sed -i "s/example.host/${DOMAINNAME}/g" $VIRTUAL_HOST
ln -s $VIRTUAL_HOST /etc/prosody/conf.d/${DOMAINNAME}.cfg.lua

# Setup the storrage driver by default sqlite3
STORRAGE_DRIVER=${STORRAGE_DRIVER:="SQLite3"}
STORRAGE_DATABASE=${STORRAGE_DATABASE:="prosody.sqlite"}

if [ "$STORRAGE_DRIVER" == "SQLite3" ]; then
  sed -i 's/--storage = "sql"/storage = "sql"/g' /etc/prosody/prosody.cfg.lua
  echo "sql = { driver = \"${STORRAGE_DRIVER}\", database = \"${STORRAGE_DATABASE}\" }" >> /etc/prosody/prosody.cfg.lua
elif [ -n "${STORRAGE_DRIVER}" ] && [ -n "${STORRAGE_DATABASE}" ] && [ -n "${STORRAGE_USER}" ] && [ -n "${STORRAGE_PASSWORD}" ] && [ -n "${STORRAGE_HOST}" ]; then
  sed -i 's/--storage = "sql"/storage = "sql"/g' /etc/prosody/prosody.cfg.lua
  echo "sql = { driver = \"${STORRAGE_DRIVER}\", database = \"${STORRAGE_DATABASE}\", username = \"${STORRAGE_USER}\", password = \"${STORRAGE_PASSWORD}\", host = \"${STORRAGE_HOST}\" }" >> /etc/prosody/prosody.cfg.lua
fi

if [[ "$1" != "prosody" ]]; then
    exec prosodyctl $*
    exit 0;
fi

if [ "$LOCAL" -a  "$PASSWORD" -a "$DOMAIN" ] ; then
    prosodyctl register $LOCAL $DOMAIN $PASSWORD
fi

exec "$@"
