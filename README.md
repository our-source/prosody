# docker-prosody

[![Docker Pulls](https://img.shields.io/docker/pulls/jsmitsnl/docker-prosody.svg)](https://hub.docker.com/r/jsmitsnl/docker-prosody/) [![Docker layers](https://images.microbadger.com/badges/image/jsmitsnl/docker-prosody.svg)](https://microbadger.com/images/jsmitsnl/docker-prosody) [![Github Stars](https://img.shields.io/github/stars/johansmitsnl/docker-prosody.svg?label=github%20%E2%98%85)](https://github.com/johansmitsnl/docker-prosody/) [![Github Stars](https://img.shields.io/github/contributors/johansmitsnl/docker-prosody.svg)](https://github.com/johansmitsnl/docker-prosody/) [![Github Forks](https://img.shields.io/github/forks/johansmitsnl/docker-prosody.svg?label=github%20forks)](https://github.com/johansmitsnl/docker-prosody/)

This service is created to host a xmmp (jabber) server.
The service is kept simple and easy to link to a ldap authentication backend.

## Usage

#### Get the latest image

    docker pull jsmitsnl/docker-prosody:latest

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

__ssl support with jwilder__:

```yaml
version: '2'

services:
  jabber:
    image: jsmitsnl/docker-prosody:latest
    hostname: jabber
    domainname: domain.com
    container_name: jabber
    restart: always
    volumes:
      - ./nginx_proxy/config/certs:/certs
    ports:
      - 5222:5222
      - 5269:5269
    environment:
      - STORRAGE_DRIVER=MySQL
      - STORRAGE_DATABASE=prosody
      - STORRAGE_USER=prosody
      - STORRAGE_PASSWORD=secret
      - STORRAGE_HOST=prosody_db
      - SASLAUTHD_LDAP_SERVERS=ldap://ldap.domain.com/
      - SASLAUTHD_LDAP_BIND_DN=cn=admin,dc=domain,dc=com
      - SASLAUTHD_LDAP_PASSWORD=secret
      - SASLAUTHD_LDAP_SEARCH_BASE=dc=domain,dc=com
      - SASLAUTHD_LDAP_FILTER=(&(mail=%u@%d))

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
