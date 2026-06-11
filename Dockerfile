FROM php:8.4-fpm-alpine3.24

RUN apk add --no-cache \
    curl \
    imagemagick \
    apache2 \
    apache2-proxy \
    su-exec \
    netcat-openbsd \
    libpng \
    libjpeg-turbo \
    freetype \
    libzip \
    libpq \
    && apk add --no-cache --virtual .build-deps \
    $PHPIZE_DEPS \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    libzip-dev \
    postgresql-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j"$(nproc)" gd zip mysqli pdo_pgsql pgsql \
    && apk del .build-deps

# phpBB
ENV PHPBB_VERSION=3.3.17
ENV PHPBB_SHA256=b52fd231e612a099c0af1d2dcb73a79f7d03926a482842c4ee2830d12f461b67

WORKDIR /tmp

RUN curl -fsSL "https://download.phpbb.com/pub/release/3.3/${PHPBB_VERSION}/phpBB-${PHPBB_VERSION}.tar.bz2" -o phpbb.tar.bz2 \
    && echo "${PHPBB_SHA256}  phpbb.tar.bz2" | sha256sum -c - \
    && tar -xjf phpbb.tar.bz2 \
    && mkdir -p /phpbb/sqlite \
    && mv phpBB3 /phpbb/www \
    && rm -f phpbb.tar.bz2

COPY phpbb/config.php /phpbb/www

# Server
RUN mkdir -p /run/apache2 /phpbb/opcache \
    && chown apache:apache /run/apache2 /phpbb/opcache

COPY apache2/httpd.conf /etc/apache2/
COPY apache2/conf.d/* /etc/apache2/conf.d/
COPY php/php.ini php/php-cli.ini /usr/local/etc/php/
COPY php/conf.d/* /usr/local/etc/php/conf.d/
COPY php-fpm.d/* /usr/local/etc/php-fpm.d/
COPY start.sh /usr/local/bin/

RUN chown -R apache:apache /phpbb
WORKDIR /phpbb/www

#VOLUME /phpbb/sqlite
#VOLUME /phpbb/www/files
#VOLUME /phpbb/www/store
#VOLUME /phpbb/www/images/avatars/upload

ENV PHPBB_INSTALL= \
    PHPBB_DB_DRIVER=sqlite3 \
    PHPBB_DB_HOST=/phpbb/sqlite/sqlite.db \
    PHPBB_DB_PORT= \
    PHPBB_DB_NAME= \
    PHPBB_DB_USER= \
    PHPBB_DB_PASSWD= \
    PHPBB_DB_TABLE_PREFIX=phpbb_ \
    PHPBB_DB_AUTOMIGRATE= \
    PHPBB_DISPLAY_LOAD_TIME= \
    PHPBB_DEBUG= \
    PHPBB_DEBUG_CONTAINER=

EXPOSE 80
CMD ["start.sh"]
