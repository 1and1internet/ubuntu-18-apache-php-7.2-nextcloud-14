FROM golang as configurability_opcache
MAINTAINER brian.wilkinson@1and1.co.uk
WORKDIR /go/src/github.com/1and1internet/configurability
RUN git clone https://github.com/1and1internet/configurability.git /go/src/github.com/1and1internet/configurability \
	&& make php_opcache \
	&& echo "configurability opcache plugin successfully built"

FROM 1and1internet/ubuntu-18-apache-php-7.2
LABEL maintainer="brian.wilkinson@1and1.co.uk"
ARG DEBIAN_FRONTEND=noninteractive
COPY files /
COPY --from=configurability_opcache /go/src/github.com/1and1internet/configurability/bin/plugins/php_opcache.so /opt/configurability/goplugins

ENV NEXTCLOUD_VERSION=14 \
    RELEASES_URL="https://download.nextcloud.com/server/releases/" \
    RELEASES_FILE=/tmp/releases.html \
    SOURCE_FOLDER=/opt/nextcloud \
    DOCUMENT_ROOT=nextcloud \
    MYSQL_DATABASE=nextcloud

ENV SITE_FOLDER=/var/www/${DOCUMENT_ROOT} \
    DATA_FOLDER=/var/www/${DOCUMENT_ROOT}/data

RUN \
  apt-get update && apt-get install -y php-redis && \
  cd $SOURCE_FOLDER && \
  curl -s $RELEASES_URL > $RELEASES_FILE && \
  LATEST_VERSION=$(cat $RELEASES_FILE | grep "nextcloud-${NEXTCLOUD_VERSION}" | grep "tar.bz2" | sed "s/.*nextcloud-\(${NEXTCLOUD_VERSION}.*\).tar.bz2.*/\1/" | tail -1) && \
  FILES=$(grep "nextcloud-${LATEST_VERSION}" $RELEASES_FILE | grep "tar.bz2" | sed "s/.*\(nextcloud-${LATEST_VERSION}[^\<]*\).*/\1/") && \
  for RELEASE_FILENAME in $FILES; \
  do \
    wget -q ${RELEASES_URL}/${RELEASE_FILENAME}; \
  done && \
  INSTALLATION_FILE=$(ls nextcloud-*.tar.bz2) && \
  sha256sum -c ${INSTALLATION_FILE}.sha256 < ${INSTALLATION_FILE} | grep -q OK && echo "Verified" && \
  chmod -R 777 $SOURCE_FOLDER && \
  apt-get -y clean && \
  rm -rf /var/lib/apt/lists/*
