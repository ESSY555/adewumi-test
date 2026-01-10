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

# Generate application key if not set
if [ -z "$APP_KEY" ] || ! grep -q "APP_KEY=base64:" .env 2>/dev/null; then
    echo "Generating application key..."
    php artisan key:generate --force || true
fi

# Clear and cache config
php artisan config:clear || true
php artisan cache:clear || true

# Run migrations (optional - uncomment to run automatically)
# echo "Running database migrations..."
# php artisan migrate --force

# Use Railway's PORT environment variable if available, otherwise default to 8000
PORT=${PORT:-8000}

echo "Starting Laravel development server on port $PORT..."
exec php artisan serve --host=0.0.0.0 --port=$PORT
