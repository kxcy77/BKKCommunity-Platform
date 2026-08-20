FROM composer:2 AS vendor

WORKDIR /app
COPY services/web/composer.json services/web/composer.lock ./
RUN composer install --no-dev --prefer-dist --no-interaction --no-progress --optimize-autoloader

FROM php:8.3-fpm

RUN apt-get update \
    && apt-get install -y --no-install-recommends default-mysql-client libonig-dev nginx \
    && docker-php-ext-install pdo_mysql mbstring \
    && rm -rf /var/lib/apt/lists/*

COPY services/web/app /var/www/app
COPY services/web/bin /var/www/bin
COPY services/web/database /var/www/database
COPY services/web/public /var/www/html
COPY services/web/.env.example /var/www/.env.example
COPY services/web/docker/nginx.conf /etc/nginx/nginx.conf
COPY --from=vendor /app/vendor /var/www/vendor

RUN chmod +x /var/www/bin/*.sh \
    && chown -R www-data:www-data /var/www/app /var/www/bin /var/www/database /var/www/html

EXPOSE 8080

CMD ["sh", "-c", "set -eu; /var/www/bin/migrate.sh; php-fpm -D; exec nginx -g 'daemon off;'"]
