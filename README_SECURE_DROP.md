# Secure Drop API - Implementation Summary

## Overview
A RESTful API built with Laravel 11 that allows users to create and retrieve "self-destructing" secure notes. Once a note is viewed, it is permanently deleted from the database.

## Architecture

### Service-Repository Pattern
- **Controller** (`SecretController`): Handles HTTP requests/responses, validation
- **Service** (`SecretService`): Contains business logic (create, retrieve, delete)
- **Repository** (`SecretRepository`): Handles all database operations
- **Model** (`Secret`): Eloquent model with encryption/decryption

### Code Structure
```
app/
├── Exceptions/
│   └── SecretNotFoundException.php
├── Http/Controllers/Api/V1/
│   └── SecretController.php
├── Models/
│   └── Secret.php
├── Repositories/
│   ├── SecretRepositoryInterface.php
│   └── SecretRepository.php
└── Services/
    └── SecretService.php
```

## API Endpoints

### POST /api/v1/secrets
Creates a new secure note.

**Request:**
```json
{
  "text": "My secret password",
  "ttl": 60  // Optional: Time to live in minutes (max 7 days)
}
```

**Response (201):**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "url": "http://localhost:8000/api/v1/secrets/550e8400-e29b-41d4-a716-446655440000"
}
```

**Rate Limit:** 10 requests per minute

### GET /api/v1/secrets/{id}
Retrieves and permanently deletes a secret (burn-on-read).

**Response (200):**
```json
{
  "text": "My secret password"
}
```

**Response (404):**
```json
{
  "message": "Secret not found or has expired."
}
```

## Security Features

1. **Encryption**: All content is encrypted using Laravel's `Crypt` facade before storage
2. **Unique IDs**: Uses UUIDs instead of auto-incrementing integers
3. **Burn-on-Read**: Secrets are permanently deleted after being viewed once
4. **Expiration**: Optional TTL support (max 7 days)
5. **Rate Limiting**: 10 requests per minute on creation endpoint

## Error Handling

Standardized JSON error responses:
- **422**: Validation errors
- **404**: Resource not found
- **429**: Rate limit exceeded
- **500**: Server errors

## Testing

### Unit Tests
- `tests/Unit/SecretServiceTest.php`: Tests service layer with mocks
- Key test: `test_secret_is_deleted_after_reading()` - Verifies burn-on-read

### Feature Tests
- `tests/Feature/SecretApiTest.php`: End-to-end API tests
- Key test: `test_secret_is_deleted_after_reading()` - Verifies burn-on-read via API

Run tests:
```bash
php artisan test
```

## API Documentation

Documentation is generated using Scribe and available at:
- `/docs` - Interactive API documentation

Generate documentation:
```bash
php artisan scribe:generate
```

## Docker Setup

The application is fully dockerized:

```bash
# Start services
docker-compose up -d

# Run migrations
docker-compose exec app php artisan migrate

# Generate documentation
docker-compose exec app php artisan scribe:generate
```

Access the application at `http://localhost:8000`

## Database Schema

```sql
secrets
  - id (bigint, primary key)
  - unique_id (string, unique, indexed)
  - encrypted_content (text)
  - expires_at (timestamp, nullable)
  - created_at (timestamp)
  - updated_at (timestamp)
```

## Key Implementation Details

1. **Encryption**: Handled via model mutator/accessor in `Secret` model
2. **Burn-on-Read**: Implemented in `SecretService::retrieveAndDelete()`
3. **Exception Handling**: Custom `SecretNotFoundException` with standardized JSON responses
4. **Rate Limiting**: Laravel's built-in throttle middleware
5. **Validation**: Request validation in controller with standardized error format
