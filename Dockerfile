FROM alpine:3.12

RUN apk add --no-cache && \
    addgroup -g 6838 -S gridc && \
    adduser -u 6838 -S gridc -G gridc -h /home/gridc


# Bring in gettext so we can get `envsubst`, then throw
# the rest away. To do this, we need to install `gettext`
# then move `envsubst` out of the way so `gettext` can
# be deleted completely, then move `envsubst` back.
RUN set -x \
    && tempDir="$(mktemp -d)" \
    && chown nobody:nobody $tempDir \
    && apk add --no-cache --virtual .gettext gettext \
    && mv /usr/bin/envsubst /tmp/ \
    \
    && runDeps="$( \
        scanelf --needed --nobanner /tmp/envsubst \
            | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
            | sort -u \
            | xargs -r apk info --installed \
            | sort -u \
    )" \
    && apk add --no-cache $runDeps \
    && apk del .gettext \
    && mv /tmp/envsubst /usr/local/bin/


COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh 

ADD https://www.gridlastic.com/downloads/c2/gridc-1.3-linux_64.tar.gz /home/gridc/gridc.tar.gz
RUN cd /home/gridc \
 && tar xfvz gridc.tar.gz gridc \
 && rm gridc.tar.gz \
 && chown gridc:gridc gridc \
 && chmod +x gridc \ 
 && mv gridc /bin \
 && mkdir -p .gridc \
 && chown gridc:gridc -R /home/gridc

COPY config-template.cfg /home/gridc/


USER gridc
ENV USER=gridc

ENTRYPOINT ["/entrypoint.sh"]
