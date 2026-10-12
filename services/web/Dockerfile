FROM composer:2 AS vendor

WORKDIR /app
COPY composer.json composer.lock ./
RUN composer install --no-dev --prefer-dist --no-interaction --no-progress --optimize-autoloader

FROM php:8.3-fpm

RUN apt-get update \
    && apt-get install -y --no-install-recommends default-mysql-client gnupg libcurl4-openssl-dev libonig-dev nginx \
    && docker-php-ext-install pdo_mysql mbstring curl \
    && rm -rf /var/lib/apt/lists/*

COPY app /var/www/app
COPY bin /var/www/bin
COPY database /var/www/database
COPY public /var/www/html
COPY .env.example /var/www/.env.example
COPY docker/nginx.conf /etc/nginx/nginx.conf
COPY --from=vendor /app/vendor /var/www/vendor

RUN chmod +x /var/www/bin/*.sh \
    && chown -R www-data:www-data /var/www/app /var/www/bin /var/www/database /var/www/html

EXPOSE 8080

CMD ["sh", "/var/www/bin/start.sh"]
