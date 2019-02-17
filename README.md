# docker-prosody

[![Docker Pulls](https://img.shields.io/docker/pulls/oursource/prosody.svg)](https://hub.docker.com/r/oursource/prosody/) [![Docker layers](https://images.microbadger.com/badges/image/oursource/prosody.svg)](https://microbadger.com/images/oursource/prosody) [![Github Stars](https://img.shields.io/github/stars/our-source/prosody.svg?label=github%20%E2%98%85)](https://github.com/our-source/prosody/) [![Github Stars](https://img.shields.io/github/contributors/our-source/prosody.svg)](https://github.com/our-source/prosody/) [![Github Forks](https://img.shields.io/github/forks/our-source/prosody.svg?label=github%20forks)](https://github.com/our-source/prosody/)

This service is created to host a xmmp (jabber) server.
The service is kept simple and easy to link to a ldap authentication backend.

## Usage

#### Get the latest image

    docker pull oursource/prosody:latest

#### DNS settings

For the case you are using Bind and have the autoconfig HTTP server running on the same IP your `www.` subdomain resolves to, you can use this DNS records to configure your nameserver

```
jabber                  IN      A       {{$SERVER_IP}}
jabber                  IN      AAAA    {{$SERVER_IPv6}}
_jabber._tcp            SRV 0 1 5269    jabber.{{$DOMAIN}}.
_xmpp-client._tcp       SRV 0 1 5222    jabber.{{$DOMAIN}}.
_xmpp-server._tcp       SRV 0 1 5269    jabber.{{$DOMAIN}}.
_jabber._tcp            SRV 0 1 5269    jabber.{{$DOMAIN}}.
conference              CNAME           jabber.{{$DOMAIN}}.
```

Replace above variables with data according to this table

Variable         | Description
-----------------|-------------------------------------------------------------
DOMAIN           | Your apex/bare/naked Domain
SERVER_IP        | IP of the jabber server
SERVER_IPv6      | IPv6 of the jabber server

---

#### Create a `docker-compose.yml`

Adapt this file with your FQDN. Install [docker-compose](https://docs.docker.com/compose/) in the version `1.6` or higher.

__ssl support with jwilder and mariadb as storrage driver__:

```yaml
version: '2'

services:
  jabber:
    image: oursource/prosody:latest
    hostname: jabber
    domainname: domain.com
    container_name: jabber
    restart: always
    depends_on:
      - prosody_db
      - ldap
      - nginx_proxy
    volumes:
      - ./nginx_proxy/config/certs:/certs
      - ./data/upload:/var/lib/prosody/http_upload
    ports:
      - 5222:5222
      - 5269:5269
    environment:
      - STORRAGE_DRIVER=MySQL
      - STORRAGE_DATABASE=prosody
      - STORRAGE_USER=prosody
      - STORRAGE_PASSWORD=secret
      - STORRAGE_HOST=db
      - SASLAUTHD_LDAP_SERVERS=ldap://ldap/
      - SASLAUTHD_LDAP_BIND_DN=cn=admin,dc=domain,dc=com
      - SASLAUTHD_LDAP_PASSWORD=secret
      - SASLAUTHD_LDAP_SEARCH_BASE=dc=domain,dc=com
      - SASLAUTHD_LDAP_FILTER=(&(mail=%u@%d))
      - HTTP_FILE_UPLOAD_SIZE=10485760

  db:
    image: mariadb
    hostname: db
    domainname: domain.com
    container_name: db
    restart: always
    volumes:
      - ./jabber/data/db:/var/lib/mysql
    environment:
      - MYSQL_RANDOM_ROOT_PASSWORD=yes
      - MYSQL_PASSWORD=secret
      - MYSQL_DATABASE=prosody
      - MYSQL_USER=prosody

  ldap:
    restart: always
    image: jsmitsnl/docker-openldap-postfix-book:latest
    hostname: ldap
    domainname: domain.com
    container_name: ldap
    volumes:
      - ./ldap/data:/var/lib/ldap
      - ./ldap/config:/etc/ldap/slapd.d
    environment:
      - LDAP_ORGANISATION=Organisation
      - LDAP_DOMAIN=domain.com
      - LDAP_ADMIN_PASSWORD=secret
      - LDAP_LOG_LEVEL=0

  nginx_proxy:
    image: jwilder/nginx-proxy:alpine
    hostname: nginx_proxy
    domainname: domain.com
    container_name: nginx_proxy
    restart: always
    ports:
      - 80:80
      - 443:443
    volumes:
      - /var/run/docker.sock:/tmp/docker.sock:ro
      - ./nginx_proxy/config/template/nginx.tmpl:/etc/docker-gen/templates/nginx.tmpl:ro
      - ./nginx_proxy/config/certs:/etc/nginx/certs:ro
      - ./nginx_proxy/config/my_proxy.conf:/etc/nginx/conf.d/my_proxy.conf:ro
      - /etc/nginx/vhost.d
      - /usr/share/nginx/html
    environment:
      - ENABLE_IPV6=true
    labels:
      - com.github.jrcs.letsencrypt_nginx_proxy_companion.nginx_proxy=true
    cap_add:
      - NET_ADMIN

    letsencrypt_companion:
      image: jrcs/letsencrypt-nginx-proxy-companion
      container_name: letsencrypt_companion
      volumes_from:
        - nginx_proxy
      volumes:
        - /var/run/docker.sock:/var/run/docker.sock:ro
        - ./nginx_proxy/config/certs:/etc/nginx/certs:rw
      restart: always
```
