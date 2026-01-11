#!/bin/sh
set -e

echo "[inf] Waiting for PostgreSQL..."
until pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USERNAME"; do
  sleep 2
done
echo "[inf] PostgreSQL is ready!"

# Create .env if missing
if [ ! -f ".env" ]; then
    echo "[inf] Creating .env file from environment variables..."
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
    echo "[inf] Generating application key..."
    php artisan key:generate --force
fi

# Clear caches
php artisan config:clear || true
php artisan cache:clear || true

# Run migrations if AUTO_MIGRATE=true
if [ "$AUTO_MIGRATE" = "true" ]; then
    echo "[inf] Running migrations..."
    php artisan migrate --force || echo "[warn] Migrations skipped or failed"
fi

# Generate Nginx config dynamically for Railway
PORT=${PORT:-80}
echo "[inf] Generating Nginx config on PORT=$PORT..."
cat > /etc/nginx/conf.d/default.conf <<EOL
server {
    listen $PORT;
    server_name localhost;
    root /var/www/html/public;

    index index.php index.html;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        include fastcgi_params;
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param PATH_INFO \$fastcgi_path_info;
    }

    location ~ /\.ht {
        deny all;
    }

    error_log /var/log/nginx/error.log;
    access_log /var/log/nginx/access.log;
}
EOL

# Start PHP-FPM in background
php-fpm &

# Start Nginx in foreground
nginx -g "daemon off;"
