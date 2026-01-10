#!/bin/sh
set -e

echo "Starting Laravel application setup..."

# Install dependencies if vendor directory doesn't exist
if [ ! -d "vendor" ]; then
    echo "Installing Composer dependencies..."
    composer install --no-interaction --prefer-dist --optimize-autoloader
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

echo "Starting Laravel development server..."
exec php artisan serve --host=0.0.0.0 --port=8000
