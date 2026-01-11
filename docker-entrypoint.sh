#!/bin/bash
set -e

# Wait for PostgreSQL to be ready
if [ "$DB_CONNECTION" = "pgsql" ]; then
    echo "[inf] Waiting for PostgreSQL..."
    until pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USERNAME"; do
        sleep 1
    done
    echo "[inf] PostgreSQL is ready!"
fi

# Create .env file from Railway environment variables if not exists
if [ ! -f .env ]; then
    echo "[inf] Creating .env file from environment variables..."
    cp .env.example .env
fi

# Generate APP_KEY if not set
if [ -z "$APP_KEY" ]; then
    echo "[inf] Generating application key..."
    php artisan key:generate --force
fi

# Clear caches
php artisan config:clear
php artisan cache:clear
php artisan route:clear
php artisan view:clear

# Run migrations
php artisan migrate --force

# Serve Laravel using artisan
exec php artisan serve --host=0.0.0.0 --port=${PORT:-8080}
