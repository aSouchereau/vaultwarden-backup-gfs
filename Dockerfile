ARG ALPINE_VERSION=3.20.2
FROM alpine:${ALPINE_VERSION}
LABEL Maintainer="Alex Souchereau"
LABEL Description="Easy way to manage backups of your vaultwarden data"

WORKDIR /app


# Add scripts
ADD crontab.txt /crontab.txt
ADD crontab-dev.txt /crontab-dev.txt
ADD scripts/ /app/scripts/

RUN chmod -R 755 /app/scripts/
# RUN /usr/bin/crontab /crontab.txt

# Add Packages
RUN apk update && apk upgrade
RUN apk add --no-cache \
  sqlite \
  mariadb-client \
  rsync

# forward script logs to docker log collector
RUN ln -sf /dev/stdout /var/log/output.log

CMD ["/app/scripts/entry.sh"]