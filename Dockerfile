ARG PHP_VERSION=8.0-apache
ARG XDEBUG_VERSION=3.0.0

FROM php:${PHP_VERSION} as build

RUN apt-get update && apt-get install -y \
  apt-transport-https \
  git \
  gnupg2 \
  iputils-ping \
  jq \
  libz-dev \
  libmcrypt-dev \
  libfreetype6-dev \
  libjpeg62-turbo-dev \
  libpng-dev \
  libxml2-dev \
  librabbitmq-dev \
  nano \
  vim \
  software-properties-common \
  zlib1g-dev \
  zip \
  && rm -rf /var/lib/apt/lists/*

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

RUN ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime && echo "Europe/Berlin" > /etc/timezone

RUN docker-php-ext-install pdo_mysql && docker-php-ext-enable pdo_mysql
RUN docker-php-ext-install exif && docker-php-ext-enable exif
RUN a2enmod rewrite

ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data

COPY ./docker/php/000-default.conf /etc/apache2/sites-available

FROM build as develop

ARG XDEBUG_VERSION

RUN apt-get update && apt-get install -y golang-go git

ENV PATH=/usr/logal/go/bin:$PATH \
    GOPATH=$HOME/go

RUN go get github.com/mailhog/mhsendmail && cp $GOPATH/bin/mhsendmail /usr/bin/mhsendmail
RUN pecl install xdebug-${XDEBUG_VERSION} && docker-php-ext-enable xdebug

COPY ./docker/php/php.ini /usr/local/etc/php
COPY ./docker/php/xdebug.ini /usr/local/etc/php/conf.d/
