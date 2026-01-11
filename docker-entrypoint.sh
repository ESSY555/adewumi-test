#!/bin/bash
set -e

# Create .env from Railway environment variables if missing
if [ ! -f .env ]; then
  echo "Creating .env file from Railway environment variables..."
  
  # Parse DATABASE_URL if provided by Railway (format: postgresql://user:pass@host:port/dbname)
  if [ -n "$DATABASE_URL" ]; then
    # Remove postgresql:// or postgres:// prefix
    DB_URL_CLEAN="${DATABASE_URL#postgresql://}"
    DB_URL_CLEAN="${DB_URL_CLEAN#postgres://}"
    
    # Extract user:password@host:port/database
    DB_CREDENTIALS_HOST="${DB_URL_CLEAN%@*}"
    DB_PATH="${DB_URL_CLEAN#*@}"
    
    # Extract user and password
    DB_USER="${DB_CREDENTIALS_HOST%%:*}"
    DB_PASS="${DB_CREDENTIALS_HOST#*:}"
    DB_PASS="${DB_PASS%%@*}"
    
    # Extract host, port, and database
    DB_HOST_PORT="${DB_PATH%%/*}"
    DB_HOST="${DB_HOST_PORT%%:*}"
    DB_PORT="${DB_HOST_PORT##*:}"
    [ "$DB_PORT" = "$DB_HOST" ] && DB_PORT="5432"  # Default port if not specified
    DB_NAME="${DB_PATH##*/}"
    DB_NAME="${DB_NAME%%\?*}"  # Remove query string if present
  fi
  
  # Use Railway's PostgreSQL variables
  # Priority: PGHOST/PGUSER/etc (Railway standard) > Parsed DATABASE_URL or DB_HOST/DB_USERNAME/etc (Railway direct vars)
  FINAL_DB_HOST="${PGHOST:-${DB_HOST}}"
  FINAL_DB_PORT="${PGPORT:-${DB_PORT:-5432}}"
  FINAL_DB_NAME="${PGDATABASE:-${DB_NAME:-${DB_DATABASE}}}"
  FINAL_DB_USER="${PGUSER:-${DB_USER:-${DB_USERNAME}}}"
  FINAL_DB_PASS="${PGPASSWORD:-${DB_PASS:-${DB_PASSWORD}}}"
  
  # Create .env file
  {
    echo "APP_NAME=${APP_NAME:-Laravel}"
    echo "APP_ENV=${APP_ENV:-production}"
    # Use APP_KEY from environment if set, otherwise leave empty (will be generated)
    echo "APP_KEY=${APP_KEY:-}"
    echo "APP_DEBUG=${APP_DEBUG:-false}"
    echo "APP_URL=${APP_URL:-http://localhost}"
    echo ""
    echo "DB_CONNECTION=pgsql"
    echo "DB_HOST=${FINAL_DB_HOST}"
    echo "DB_PORT=${FINAL_DB_PORT}"
    echo "DB_DATABASE=${FINAL_DB_NAME}"
    echo "DB_USERNAME=${FINAL_DB_USER}"
    echo "DB_PASSWORD=${FINAL_DB_PASS}"
    echo ""
    echo "CACHE_DRIVER=${CACHE_DRIVER:-database}"
    echo "QUEUE_CONNECTION=${QUEUE_CONNECTION:-sync}"
    echo "SESSION_DRIVER=${SESSION_DRIVER:-database}"
  } > .env
fi

# Install deps if vendor missing
if [ ! -d "vendor" ]; then
  composer install --no-dev --optimize-autoloader
fi

# Generate APP_KEY if missing or empty
# Check if APP_KEY is set in environment variable (from Railway)
if [ -n "$APP_KEY" ]; then
  echo "Using APP_KEY from environment variable"
  # Update .env with the environment variable value
  if grep -q "^APP_KEY=" .env; then
    sed -i "s|^APP_KEY=.*|APP_KEY=$APP_KEY|" .env
  else
    echo "APP_KEY=$APP_KEY" >> .env
  fi
else
  # Check if APP_KEY exists in .env and has a value
  APP_KEY_VALUE=$(grep "^APP_KEY=" .env | cut -d '=' -f2- | tr -d ' ' | tr -d '"' | tr -d "'" || echo "")
  if [ -z "$APP_KEY_VALUE" ]; then
    echo "APP_KEY is missing or empty. Generating new key..."
    php artisan key:generate --force
  else
    echo "APP_KEY already exists in .env file"
  fi
fi

# Wait for Postgres using Railway environment variables or .env values
# Railway provides PGHOST, PGPORT, PGUSER, PGPASSWORD, PGDATABASE
# Or we can read from .env file
PG_HOST="${PGHOST:-${DB_HOST}}"
PG_PORT="${PGPORT:-${DB_PORT:-5432}}"
PG_USER="${PGUSER:-${DB_USERNAME}}"

# Try to read from .env if not in environment
if [ -z "$PG_HOST" ] && [ -f .env ]; then
  PG_HOST=$(grep "^DB_HOST=" .env | cut -d '=' -f2 | tr -d ' ' | tr -d '"' | tr -d "'")
fi
if [ -z "$PG_USER" ] && [ -f .env ]; then
  PG_USER=$(grep "^DB_USERNAME=" .env | cut -d '=' -f2 | tr -d ' ' | tr -d '"' | tr -d "'")
fi
if [ -z "$PG_PORT" ] && [ -f .env ]; then
  PG_PORT=$(grep "^DB_PORT=" .env | cut -d '=' -f2 | tr -d ' ' | tr -d '"' | tr -d "'")
  PG_PORT="${PG_PORT:-5432}"
fi

# Wait for Postgres if connection details are available
if [ -n "$PG_HOST" ] && [ -n "$PG_USER" ]; then
  echo "Waiting for PostgreSQL at $PG_HOST:$PG_PORT to be ready..."
  for i in {1..30}; do
    if pg_isready -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" >/dev/null 2>&1; then
      echo "PostgreSQL is ready!"
      break
    fi
    if [ $i -eq 30 ]; then
      echo "Warning: PostgreSQL connection check timed out, continuing anyway..."
    else
      echo "PostgreSQL is not ready yet. Waiting... ($i/30)"
      sleep 2
    fi
  done
fi

# Run migrations
php artisan migrate --force

# Clear caches
php artisan optimize:clear

# Start Laravel HTTP server (THIS is what exposes your app)
exec php artisan serve --host=0.0.0.0 --port=$PORT
