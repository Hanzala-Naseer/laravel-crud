
FROM php:8.3-apache

RUN apt-get update && apt-get install -y \
    git unzip libzip-dev curl default-mysql-client \
    && docker-php-ext-install pdo pdo_mysql \
    && a2enmod rewrite \
    && rm -rf /var/lib/apt/lists/*

ENV APACHE_DOCUMENT_ROOT=/var/www/html/public

RUN sed -ri 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' \
    /etc/apache2/sites-available/*.conf \
    /etc/apache2/apache2.conf \
    /etc/apache2/conf-available/*.conf

WORKDIR /var/www/html

COPY . .

RUN curl -4 -fSs https://getcomposer.org/installer -o /tmp/composer-setup.php \
    && php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer \
    && composer install --no-dev --optimize-autoloader --no-interaction \
    && rm -f /tmp/composer-setup.php

RUN mkdir -p \
    storage/framework/cache \
    storage/framework/sessions \
    storage/framework/views \
    storage/logs \
    bootstrap/cache \
    && chown -R www-data:www-data storage bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache

EXPOSE 80

CMD ["sh", "-c", "until php -r '$s=@fsockopen(getenv(\"DB_HOST\"), (int)getenv(\"DB_PORT\"), $errno, $errstr, 5); if($s){fclose($s); exit(0);} exit(1);'; do echo 'Waiting for MySQL...'; sleep 5; done; php artisan config:clear && php artisan migrate --force && apache2-foreground"]
