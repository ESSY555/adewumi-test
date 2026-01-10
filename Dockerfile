FROM php:8.2-cli-alpine

# Set working directory
WORKDIR /var/www/html

# Install system dependencies
RUN apk add --no-cache \
    git \
    curl \
    libpng-dev \
    libzip-dev \
    zip \
    unzip \
    postgresql-dev \
    postgresql-client \
    oniguruma-dev \
    icu-dev \
    nodejs \
    npm \
    bash

# Install PHP extensions
RUN docker-php-ext-install \
    pdo \
    pdo_pgsql \
    pgsql \
    mbstring \
    exif \
    pcntl \
    bcmath \
    gd \
    zip \
    intl

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Copy entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Copy existing application directory permissions
RUN chown -R www-data:www-data /var/www/html

# Expose port 8000
EXPOSE 8000

# Use entrypoint script
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
