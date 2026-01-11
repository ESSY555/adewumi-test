#!/bin/bash
set -e

# Create .env if missing
if [ ! -f .env ]; then
  cp .env.example .env
fi

# Install deps if vendor missing
if [ ! -d "vendor" ]; then
  composer install --no-dev --optimize-autoloader
fi

# Generate APP_KEY if missing
if ! grep -q "APP_KEY" .env || [ -z "$(grep APP_KEY .env | cut -d '=' -f2)" ]; then
  php artisan key:generate --force
fi

# Wait for Postgres
if [ "$DB_CONNECTION" = "pgsql" ]; then
  until pg_isready -h "$DB_HOST" -p "${DB_PORT:-5432}" -U "$DB_USERNAME"; do
    sleep 2
  done
fi

# Run migrations
php artisan migrate --force

# Clear caches
php artisan optimize:clear

# Start Laravel HTTP server (THIS is what exposes your app)
exec php artisan serve --host=0.0.0.0 --port=$PORT
