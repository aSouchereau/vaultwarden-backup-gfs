ARG ALPINE_VERSION=3.18.4
FROM alpine:${ALPINE_VERSION}
LABEL Maintainer="Alex Souchereau"
LABEL Description="Easy way to manage backups of your vaultwarden data"

WORKDIR /app


# Add scripts
ADD crontab.txt /crontab.txt
ADD scripts/ /app/scripts/

RUN chmod 755 /app/scripts/entry.sh
RUN /usr/bin/crontab /crontab.txt

# forward script logs to docker log collector
RUN ln -sf /dev/stdout /var/log/output.log

CMD ["/app/scripts/entry.sh"]