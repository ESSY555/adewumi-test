#!/bin/sh
set -e

echo "Starting Laravel application setup..."

# Wait for composer.json to be available (in case of volume mount timing issues)
if [ ! -f "composer.json" ]; then
    echo "Waiting for composer.json to be available..."
    sleep 2
fi

# Install dependencies if vendor directory doesn't exist
if [ ! -d "vendor" ] && [ -f "composer.json" ]; then
    echo "Installing Composer dependencies..."
    composer install --no-interaction --prefer-dist --optimize-autoloader
elif [ ! -f "composer.json" ]; then
    echo "ERROR: composer.json not found. Please ensure the application files are properly mounted."
    exit 1
fi

# Create .env file if it doesn't exist (for Railway/deployment environments)
if [ ! -f ".env" ]; then
    echo "Creating .env file from environment variables..."
    # Create a basic .env file with essential variables
    {
        echo "APP_NAME=${APP_NAME:-Laravel}"
        echo "APP_ENV=${APP_ENV:-production}"
        echo "APP_KEY=${APP_KEY:-}"
        echo "APP_DEBUG=${APP_DEBUG:-false}"
        echo "APP_URL=${APP_URL:-http://localhost}"
        echo ""
        echo "DB_CONNECTION=${DB_CONNECTION:-pgsql}"
        echo "DB_HOST=${DB_HOST:-postgres}"
        echo "DB_PORT=${DB_PORT:-5432}"
        echo "DB_DATABASE=${DB_DATABASE:-laravel}"
        echo "DB_USERNAME=${DB_USERNAME:-laravel}"
        echo "DB_PASSWORD=${DB_PASSWORD:-}"
        echo ""
        echo "CACHE_DRIVER=${CACHE_DRIVER:-database}"
        echo "QUEUE_CONNECTION=${QUEUE_CONNECTION:-sync}"
        echo "SESSION_DRIVER=${SESSION_DRIVER:-database}"
    } > .env
fi

# Generate application key if not set
if [ -z "$APP_KEY" ] || ! grep -q "APP_KEY=base64:" .env 2>/dev/null; then
    echo "Generating application key..."
    php artisan key:generate --force || true
fi

# Clear and cache config (skip if database tables don't exist yet)
php artisan config:clear || true
# Skip cache:clear if database tables don't exist (common on first run)
php artisan cache:clear 2>/dev/null || echo "Cache clear skipped (database may not be ready)"

# Run migrations if AUTO_MIGRATE is set to true (useful for Railway)
if [ "$AUTO_MIGRATE" = "true" ]; then
    echo "Running database migrations..."
    php artisan migrate --force || echo "Migrations failed or already up to date"
fi

# Use Railway's PORT environment variable if available, otherwise default to 8000
PORT=${PORT:-8000}

echo "Starting Laravel development server on port $PORT..."
exec php artisan serve --host=0.0.0.0 --port=$PORT
