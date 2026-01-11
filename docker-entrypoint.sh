#!/bin/bash
set -e

# Install PostgreSQL client if missing (for pg_isready)
if ! command -v pg_isready &> /dev/null; then
    echo "Installing PostgreSQL client..."
    apt-get update && apt-get install -y postgresql-client
fi

# Create .env from example if it doesn't exist
if [ ! -f .env ]; then
    echo "Creating .env file from .env.example..."
    cp .env.example .env
fi

# Install Composer dependencies if vendor folder is missing
if [ ! -d "vendor" ]; then
    echo "Installing composer dependencies..."
    composer install --no-dev --optimize-autoloader
fi

# Generate APP_KEY if missing
if ! grep -q "APP_KEY" .env || [ -z "$(grep APP_KEY .env | cut -d '=' -f2)" ]; then
    echo "Generating Laravel APP_KEY..."
    php artisan key:generate --ansi
fi

# Wait for PostgreSQL
if [ "$DB_CONNECTION" = "pgsql" ]; then
    echo "Waiting for PostgreSQL..."
    until pg_isready -h "$DB_HOST" -p "${DB_PORT:-5432}" -U "$DB_USERNAME"; do
        sleep 2
    done
    echo "PostgreSQL is ready!"
fi

# Run migrations
echo "Running migrations..."
php artisan migrate --force

# Clear caches
php artisan config:clear
php artisan cache:clear

# Start PHP-FPM
echo "Starting PHP-FPM..."
exec php-fpm
