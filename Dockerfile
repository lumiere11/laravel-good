# Stage 1: Build
FROM composer:2 as vendor
WORKDIR /app
COPY . .
RUN composer install --no-dev --optimize-autoloader --prefer-dist

# Stage 2: Production image
FROM php:8.4-fpm-alpine
WORKDIR /var/www/html

# Install PHP extensions
RUN docker-php-ext-install pdo pdo_mysql opcache

# Enable OPcache for production
RUN { \
    echo 'opcache.enable=1'; \
    echo 'opcache.enable_cli=1'; \
    echo 'opcache.memory_consumption=128'; \
    echo 'opcache.max_accelerated_files=10000'; \
    echo 'opcache.validate_timestamps=0'; \
} > /usr/local/etc/php/conf.d/opcache.ini

# Copy app and vendor files
COPY --from=vendor /app ./

# Set permissions
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

USER www-data

# Nginx container for static assets
FROM nginx:1.27-alpine as nginx
COPY ./docker/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=vendor /app/public /var/www/html/public
