#!/bin/bash
set -e

# Create .env from Railway environment variables if it doesn't exist
if [ ! -f .env ]; then
    echo "Creating .env file from environment variables..."
    cp .env.example .env
fi

# Generate Laravel APP_KEY if missing
if ! grep -q "APP_KEY" .env || [ -z "$(grep APP_KEY .env | cut -d '=' -f2)" ]; then
    echo "Generating application key..."
    php artisan key:generate --ansi
fi

# Wait for PostgreSQL to be ready
if [ "$DB_CONNECTION" = "pgsql" ]; then
    echo "Waiting for PostgreSQL..."
    until pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USERNAME"; do
        sleep 1
    done
    echo "PostgreSQL is ready!"
fi

# Run migrations
php artisan migrate --force

# Start PHP-FPM server
exec php-fpm
