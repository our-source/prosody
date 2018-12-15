FROM debian:stable

MAINTAINER Johan Smits <johan@smitsmail.net>

ENV DEBIAN_FRONTEND noninteractive
ENV __FLUSH_LOG yes
ENV HTTP_FILE_UPLOAD_SIZE 10485760

RUN echo "deb http://ftp.debian.org/debian stretch-backports main" >> /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        gnupg2 \
        lsb-release \
        mercurial \
        sasl2-bin \
        libsasl2-modules \
        openssl \
        ca-certificates \
        supervisor \
        wget \
        prosody \
        lua-bitop \
        lua-cyrussasl \
        lua-dbi-sqlite3 \
        lua-dbi-mysql \
        lua-dbi-postgresql \
        lua-sec \
        lua-zlib && \
    rm -rf /var/lib/apt/lists/* && \
    sed -i 's/daemonize = true;/daemonize = false;/g' /etc/prosody/prosody.cfg.lua && \
    sed -i 's/--"http_files";/"http_upload"; -- Enable file upload XEP-0363\n                &/g' /etc/prosody/prosody.cfg.lua && \
    sed -i 's/"vcard";/"carbons"; -- XEP-0280: Message Carbons\n                &/g' /etc/prosody/prosody.cfg.lua && \
    sed -i 's/"vcard";/"csi"; -- that allows clients to report their active\/inactive state to the server using XEP-0352\n                &/g' /etc/prosody/prosody.cfg.lua && \
    sed -i 's/--"bosh";/"bosh";/g' /etc/prosody/prosody.cfg.lua && \
    sed -i 's/--"compression";/"compression";/g' /etc/prosody/prosody.cfg.lua && \
    sed -i 's/--"mam";/"mam";/g' /etc/prosody/prosody.cfg.lua && \
    sed -i 's/--"proxy65";/"proxy65";/g' /etc/prosody/prosody.cfg.lua && \
    sed -i 's/--"websocket";/"websocket";/g' /etc/prosody/prosody.cfg.lua && \
    sed -i 's/c2s_require_encryption = false/c2s_require_encryption = true/g' /etc/prosody/prosody.cfg.lua && \
    sed -i 's/authentication = "internal_plain"/authentication = "cyrus"/g' /etc/prosody/prosody.cfg.lua && \
    mkdir /var/run/prosody && \
    hg clone https://hg.prosody.im/prosody-modules/ /tmp/prosody-modules && \
    mv /tmp/prosody-modules/mod_http_upload /usr/lib/prosody/modules/mod_http_upload && \
    mv /tmp/prosody-modules/mod_carbons /usr/lib/prosody/modules/mod_carbons && \
    mv /tmp/prosody-modules/mod_csi /usr/lib/prosody/modules/mod_csi && \
    rm -rf /opt/prosody-modules && \
    chown prosody:prosody -Rf /etc/prosody /var/run/prosody

COPY ./host_skel.cfg.lua /etc/prosody/conf.avail/

COPY ./sasl_prosody.conf /etc/sasl/prosody.conf
RUN adduser prosody sasl

# Configure supervisor
COPY ./supervisor/* /etc/supervisor/conf.d/

COPY ./entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 5000 5222 5269 5280 5281

CMD ["prosody"]
