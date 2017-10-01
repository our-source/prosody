FROM debian:stable

MAINTAINER Johan Smits <johan@smitsmail.net>

ENV DEBIAN_FRONTEND noninteractive
ENV __FLUSH_LOG yes

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        prosody \
        lua-zlib \
        lua-dbi-sqlite3 \
        lua-dbi-mysql \
        lua-dbi-postgresql \
        sasl2-bin \
        lua-cyrussasl \
        openssl \
        ca-certificates \
        supervisor \
        nano less && \
    rm -rf /var/lib/apt/lists/* && \

    sed -i 's/daemonize = true;/daemonize = false;/g' /etc/prosody/prosody.cfg.lua && \
    sed -i 's/--"compression";/"compression";/g' /etc/prosody/prosody.cfg.lua && \
    sed -i 's/{ levels = { "error" }; to = "syslog";  };/{ levels = { min = "info" }; to = "console";  };/g' /etc/prosody/prosody.cfg.lua && \
    sed -i 's/c2s_require_encryption = false/c2s_require_encryption = true/g' /etc/prosody/prosody.cfg.lua && \
    sed -i 's/authentication = "internal_plain"/authentication = "cyrus"/g' /etc/prosody/prosody.cfg.lua && \
    mkdir /var/run/prosody && \
    chown prosody:prosody -Rf /etc/prosody /var/run/prosody

COPY ./host_skel.cfg.lua /etc/prosody/conf.avail/

COPY ./sasl_prosody.conf /etc/sasl/prosody.conf
COPY ./saslauthd.conf /etc/saslauthd.conf

COPY ./docker-configomat/configomat.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/*

# Configure supervisor
COPY ./supervisor/* /etc/supervisor/conf.d/

COPY ./entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 80 443 5222 5269 5347 5280 5281

CMD ["prosody"]
