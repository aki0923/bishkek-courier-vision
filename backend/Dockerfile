# Multi-stage build for smaller image
FROM composer:2.6 as composer

WORKDIR /app
COPY composer.json composer.lock* ./
RUN composer install --no-dev --no-scripts --no-autoloader --prefer-dist

# Main stage
FROM php:8.1-apache

# Install dependencies in one layer
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd \
    && a2enmod rewrite \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /var/www/html

# Copy composer dependencies from previous stage
COPY --from=composer /app/vendor ./vendor

# Copy application files
COPY . .

# Generate autoloader
COPY --from=composer:2.6 /usr/bin/composer /usr/bin/composer

RUN composer dump-autoload --optimize

# Set permissions
RUN chown -R www-data:www-data /var/www/html \
    && find /var/www/html -type f -exec chmod 644 {} \; \
    && find /var/www/html -type d -exec chmod 755 {} \; \
    && mkdir -p /var/www/html/storage/uploads \
    && chmod -R 775 /var/www/html/storage

# Apache configuration
COPY docker/apache/000-default.conf /etc/apache2/sites-available/000-default.conf

# Enable mod_headers for security
RUN a2enmod headers

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost/api/health || exit 1

EXPOSE 80

CMD ["apache2-foreground"]