#!/bin/bash
set -e

# Setup the host for the environment
DOMAINNAME="$(hostname -d)"
if [ -z "$DOMAINNAME" ]; then
    echo "The domain is not set"
    exit 1;
fi

VIRTUAL_HOST="/etc/prosody/conf.avail/${DOMAINNAME}.cfg.lua"
cp /etc/prosody/conf.avail/host_skel.cfg.lua $VIRTUAL_HOST
sed -i "s/example.host/${DOMAINNAME}/g" $VIRTUAL_HOST
cat $VIRTUAL_HOST >> /etc/prosody/prosody.cfg.lua

# Setup the storrage driver by default sqlite3
if [ "$STORRAGE_DRIVER" == "SQLite3" ]; then
  sed -i 's/--storage = "sql"/storage = "sql"/g' /etc/prosody/prosody.cfg.lua
  sed "/storage = \"sql\"/a\sql = { driver = \"${STORRAGE_DRIVER}\", database = \"${STORRAGE_DATABASE}\" }" /etc/prosody/prosody.cfg.lua
elif [ -n "${STORRAGE_DRIVER}" ] && [ -n "${STORRAGE_DATABASE}" ] && [ -n "${STORRAGE_USER}" ] && [ -n "${STORRAGE_PASSWORD}" ] && [ -n "${STORRAGE_HOST}" ]; then
  sed -i 's/--storage = "sql"/storage = "sql"/g' /etc/prosody/prosody.cfg.lua
  sed -i "/storage = \"sql\"/a\sql = { driver = \"${STORRAGE_DRIVER}\", database = \"${STORRAGE_DATABASE}\", username = \"${STORRAGE_USER}\", password = \"${STORRAGE_PASSWORD}\", host = \"${STORRAGE_HOST}\" }" /etc/prosody/prosody.cfg.lua
fi

# Enable the https server
mkdir /var/lib/prosody/http_upload
cat >> /etc/prosody/prosody.cfg.lua << EOF

-- Define ports
http_ports = { 5280 }
http_interfaces = { "*" }

https_ports = { 5281 }
https_interfaces = { "*" }

-- Set up the default HTTP host
default_http_host = "xmpp.${DOMAINNAME}";

-- Consigure the ssl path
https_ssl = {
  key = "/certs/${DOMAINNAME}/key.pem";
  certificate = "/certs/${DOMAINNAME}/fullchain.pem";
}

-- Change the default HTTP upload path
http_upload_path = "/var/lib/prosody/http_upload";
EOF

# Configure ldap attributes
cat > /etc/saslauthd.conf << EOF
ldap_servers: ${SASLAUTHD_LDAP_SERVERS}

ldap_auth_method: bind
ldap_bind_dn: ${SASLAUTHD_LDAP_BIND_DN}
ldap_bind_pw: ${SASLAUTHD_LDAP_PASSWORD}

ldap_search_base: ${SASLAUTHD_LDAP_SEARCH_BASE}
ldap_filter: ${SASLAUTHD_LDAP_FILTER}

ldap_referrals: yes
log_level: 10
EOF

if [[ "$1" != "prosody" ]]; then
    exec prosodyctl $*
    exit 0;
fi

if [ "$LOCAL" -a  "$PASSWORD" -a "$DOMAIN" ] ; then
    prosodyctl register $LOCAL $DOMAIN $PASSWORD
fi

supervisord -c /etc/supervisor/supervisord.conf
