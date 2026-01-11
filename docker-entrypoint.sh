#!/bin/sh
set -e

echo "Waiting for PostgreSQL..."
until pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USERNAME"; do
  sleep 2
done

# Create .env if missing
if [ ! -f ".env" ]; then
    echo "Creating .env file from environment variables..."
    {
        echo "APP_NAME=${APP_NAME:-Laravel}"
        echo "APP_ENV=${APP_ENV:-production}"
        echo "APP_KEY="
        echo "APP_DEBUG=${APP_DEBUG:-false}"
        echo "APP_URL=${APP_URL:-http://localhost}"
        echo ""
        echo "DB_CONNECTION=${DB_CONNECTION:-pgsql}"
        echo "DB_HOST=${DB_HOST:-postgres}"
        echo "DB_PORT=${DB_PORT:-5432}"
        echo "DB_DATABASE=${DB_DATABASE:-laravel}"
        echo "DB_USERNAME=${DB_USERNAME:-laravel}"
        echo "DB_PASSWORD=${DB_PASSWORD:-secret123}"
        echo ""
        echo "CACHE_DRIVER=${CACHE_DRIVER:-database}"
        echo "QUEUE_CONNECTION=${QUEUE_CONNECTION:-sync}"
        echo "SESSION_DRIVER=${SESSION_DRIVER:-database}"
    } > .env
fi

# Generate APP_KEY if missing
if ! grep -q "APP_KEY=base64:" .env; then
    echo "Generating application key..."
    php artisan key:generate --force
fi

# Clear caches
php artisan config:clear || true
php artisan cache:clear || true

# Run migrations if AUTO_MIGRATE=true
if [ "$AUTO_MIGRATE" = "true" ]; then
    echo "Running database migrations..."
    php artisan migrate --force || echo "Migrations skipped or failed"
fi

# Start PHP-FPM in background
echo "Starting PHP-FPM..."
php-fpm &

# Start Nginx in foreground
echo "Starting Nginx..."
nginx -g "daemon off;"
