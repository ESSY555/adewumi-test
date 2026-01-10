# Docker Setup Guide

This project uses Docker Compose to run the Laravel application with PostgreSQL.

## Prerequisites

- Docker Desktop installed and running
- Docker Compose (included with Docker Desktop)

## Quick Start

1. **Copy the environment file:**
   ```bash
   cp .env.example .env
   ```

2. **Update your `.env` file with PostgreSQL settings:**
   ```env
   DB_CONNECTION=pgsql
   DB_HOST=postgres
   DB_PORT=5432
   DB_DATABASE=laravel
   DB_USERNAME=laravel
   DB_PASSWORD=secret123
   ```

3. **Build and start the containers:**
   ```bash
   docker-compose up -d --build
   ```

4. **Run database migrations:**
   ```bash
   docker-compose exec app php artisan migrate
   ```

5. **Access the application:**
   - Application: http://localhost:8000
   - PostgreSQL: localhost:5432

## Docker Commands

### Start containers
```bash
docker-compose up -d
```

### Stop containers
```bash
docker-compose down
```

### View logs
```bash
docker-compose logs -f app
docker-compose logs -f postgres
```

### Execute commands in the app container
```bash
docker-compose exec app php artisan [command]
docker-compose exec app composer [command]
```

### Access PostgreSQL
```bash
docker-compose exec postgres psql -U laravel -d laravel
```

### Rebuild containers
```bash
docker-compose up -d --build
```

### Remove all containers and volumes
```bash
docker-compose down -v
```

## Services

- **app**: Laravel application (PHP 8.2)
- **postgres**: PostgreSQL 16 database

## Environment Variables

You can customize the setup by modifying these variables in your `.env` file:

- `DB_DATABASE`: Database name (default: laravel)
- `DB_USERNAME`: Database user (default: laravel)
- `DB_PASSWORD`: Database password (default: password)
- `DB_PORT`: PostgreSQL port (default: 5432)
- `APP_PORT`: Application port (default: 8000)

## Troubleshooting

### Port already in use
If port 8000 or 5432 is already in use, change them in your `.env` file:
```env
APP_PORT=8001
DB_PORT=5433
```

### Permission issues
If you encounter permission issues, you may need to adjust file permissions:
```bash
sudo chown -R $USER:$USER .
```

### Database connection errors
Make sure the PostgreSQL container is healthy before running migrations:
```bash
docker-compose ps
```

Wait for the postgres service to show as "healthy" before proceeding.
