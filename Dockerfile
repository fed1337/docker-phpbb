FROM php:8.4-fpm-alpine3.24 AS builder

ENV PHPBB_VERSION=3.3.17
ENV PHPBB_SHA256=b52fd231e612a099c0af1d2dcb73a79f7d03926a482842c4ee2830d12f461b67

RUN apk add --no-cache --virtual .build-deps \
    $PHPIZE_DEPS \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    libzip-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j"$(nproc)" gd zip mysqli \
    && apk del .build-deps

RUN apk add --no-cache curl \
    && curl -fsSL "https://download.phpbb.com/pub/release/3.3/${PHPBB_VERSION}/phpBB-${PHPBB_VERSION}.tar.bz2" -o phpbb.tar.bz2 \
    && echo "${PHPBB_SHA256}  phpbb.tar.bz2" | sha256sum -c - \
    && tar -xjf phpbb.tar.bz2 \
    && mkdir -p /phpbb/sqlite \
    && mv phpBB3 /phpbb/www \
    && rm -rf phpbb.tar.bz2 \
    && apk del curl


FROM php:8.4-fpm-alpine3.24

RUN apk add --no-cache \
    nginx \
    su-exec \
    netcat-openbsd \
    libpng \
    libjpeg-turbo \
    freetype \
    libzip \
    && rm -f /etc/nginx/http.d/default.conf \
    && mkdir -p /run/nginx /phpbb/opcache \
    && chown nginx:nginx /run/nginx /phpbb/opcache

COPY --from=builder /usr/local/lib/php/extensions/ /usr/local/lib/php/extensions/
COPY --from=builder /usr/local/etc/php/conf.d/docker-php-ext-gd.ini \
    /usr/local/etc/php/conf.d/docker-php-ext-mysqli.ini \
    /usr/local/etc/php/conf.d/docker-php-ext-zip.ini \
    /usr/local/etc/php/conf.d/
COPY --from=builder /phpbb /phpbb

COPY phpbb/config.php /phpbb/www/
COPY nginx/nginx.conf /etc/nginx/
COPY nginx/http.d/* /etc/nginx/http.d/
COPY php/php.ini php/php-cli.ini /usr/local/etc/php/
COPY php/conf.d/* /usr/local/etc/php/conf.d/
COPY php-fpm.d/* /usr/local/etc/php-fpm.d/
COPY start.sh /usr/local/bin/

RUN chown -R nginx:nginx /phpbb
WORKDIR /phpbb/www

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
