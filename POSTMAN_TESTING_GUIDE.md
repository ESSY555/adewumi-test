# Postman Testing Guide - Secure Drop API

## Prerequisites
1. Make sure your Laravel application is running:
   ```bash
   docker-compose up -d
   ```
2. Open Postman (download from https://www.postman.com if needed)

## Base URL
```
http://localhost:8000/api/v1
```

---

## Test 1: Create a Secret (Basic)

### Step-by-Step:
1. **Method**: Select `POST`
2. **URL**: `http://localhost:8000/api/v1/secrets`
3. **Headers**: 
   - Click "Headers" tab
   - Add: `Content-Type: application/json`
4. **Body**:
   - Click "Body" tab
   - Select `raw`
   - Select `JSON` from dropdown
   - Paste this payload:
   ```json
   {
     "text": "My secret password is: P@ssw0rd123"
   }
   ```
5. **Click "Send"**

### Expected Response (201 Created):
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "url": "http://localhost:8000/api/v1/secrets/550e8400-e29b-41d4-a716-446655440000"
}
```

### Save the `id` value - you'll need it for the next test!

---

## Test 2: Create a Secret with TTL (Time to Live)

### Step-by-Step:
1. **Method**: `POST`
2. **URL**: `http://localhost:8000/api/v1/secrets`
3. **Headers**: `Content-Type: application/json`
4. **Body** (raw JSON):
   ```json
   {
     "text": "This secret will expire in 5 minutes",
     "ttl": 5
   }
   ```
5. **Click "Send"**

### Expected Response (201 Created):
```json
{
  "id": "another-uuid-here",
  "url": "http://localhost:8000/api/v1/secrets/another-uuid-here"
}
```

---

## Test 3: Retrieve a Secret (Burn-on-Read)

### Step-by-Step:
1. **Method**: Select `GET`
2. **URL**: `http://localhost:8000/api/v1/secrets/{id}`
   - Replace `{id}` with the `id` you got from Test 1
   - Example: `http://localhost:8000/api/v1/secrets/550e8400-e29b-41d4-a716-446655440000`
3. **No Headers needed** (GET request)
4. **No Body needed**
5. **Click "Send"**

### Expected Response (200 OK):
```json
{
  "text": "My secret password is: P@ssw0rd123"
}
```

### Important: 
- **The secret is now deleted!** Try calling this endpoint again with the same ID.

---

## Test 4: Try to Retrieve the Same Secret Again (Should Fail)

### Step-by-Step:
1. **Method**: `GET`
2. **URL**: Use the **same URL** from Test 3
3. **Click "Send"**

### Expected Response (404 Not Found):
```json
{
  "message": "Secret not found or has expired."
}
```

This proves the **burn-on-read** functionality works!

---

## Test 5: Validation Error - Missing Text Field

### Step-by-Step:
1. **Method**: `POST`
2. **URL**: `http://localhost:8000/api/v1/secrets`
3. **Headers**: `Content-Type: application/json`
4. **Body** (raw JSON):
   ```json
   {
     "ttl": 60
   }
   ```
   Note: `text` field is missing
5. **Click "Send"**

### Expected Response (422 Unprocessable Entity):
```json
{
  "message": "The given data was invalid.",
  "errors": {
    "text": [
      "The text field is required."
    ]
  }
}
```

---

## Test 6: Validation Error - Invalid TTL

### Step-by-Step:
1. **Method**: `POST`
2. **URL**: `http://localhost:8000/api/v1/secrets`
3. **Headers**: `Content-Type: application/json`
4. **Body** (raw JSON):
   ```json
   {
     "text": "My secret",
     "ttl": -10
   }
   ```
5. **Click "Send"**

### Expected Response (422 Unprocessable Entity):
```json
{
  "message": "The given data was invalid.",
  "errors": {
    "ttl": [
      "The title field must be at least 1."
    ]
  }
}
```

---

## Test 7: Test Rate Limiting

### Step-by-Step:
1. **Method**: `POST`
2. **URL**: `http://localhost:8000/api/v1/secrets`
3. **Headers**: `Content-Type: application/json`
4. **Body** (raw JSON):
   ```json
   {
     "text": "Test secret"
   }
   ```

5. **Click "Send" 11 times** (rapidly, or use Postman's Collection Runner)
   - First 10 requests should return **201 Created**
   - 11th request should return **429 Too Many Requests**

### Expected Response (429 Too Many Requests):
```json
{
  "message": "Too many requests. Please try again later."
}
```

---

## Test 8: Retrieve Non-Existent Secret

### Step-by-Step:
1. **Method**: `GET`
2. **URL**: `http://localhost:8000/api/v1/secrets/non-existent-id-12345`
3. **Click "Send"**

### Expected Response (404 Not Found):
```json
{
  "message": "Secret not found or has expired."
}
```

---

## Postman Collection Setup (Optional)

### Create a Collection:
1. Click "New" → "Collection"
2. Name it: "Secure Drop API"
3. Add all requests above to this collection

### Create Environment Variables:
1. Click "Environments" → "Create Environment"
2. Add variable:
   - **Variable**: `base_url`
   - **Initial Value**: `http://localhost:8000/api/v1`
3. In your requests, use: `{{base_url}}/secrets`

### Save Secret ID Automatically:
1. In Test 1 (Create Secret), go to "Tests" tab
2. Add this script:
   ```javascript
   var jsonData = pm.response.json();
   pm.environment.set("secret_id", jsonData.id);
   ```
3. In Test 3 (Retrieve Secret), use: `{{base_url}}/secrets/{{secret_id}}`

---

## Quick Test Workflow

### Complete Flow:
1. **Create Secret** → Get `id`
2. **Retrieve Secret** → Get decrypted text (secret deleted)
3. **Retrieve Again** → Should get 404 (proves deletion)

### Example Sequence:
```
POST /api/v1/secrets
Body: {"text": "API Key: sk-1234567890"}

Response: {
  "id": "abc-123-def",
  "url": "http://localhost:8000/api/v1/secrets/abc-123-def"
}

GET /api/v1/secrets/abc-123-def

Response: {
  "text": "API Key: sk-1234567890"
}

GET /api/v1/secrets/abc-123-def (again)

Response: {
  "message": "Secret not found or has expired."
}
```

---

## Troubleshooting

### If you get "Connection refused":
- Make sure Docker containers are running: `docker-compose ps`
- Check if app is accessible: `curl http://localhost:8000/up`

### If you get 500 errors:
- Check Laravel logs: `docker-compose exec app tail -f storage/logs/laravel.log`
- Make sure migrations ran: `docker-compose exec app php artisan migrate`

### If rate limiting doesn't work:
- Wait 1 minute between test batches
- Or clear cache: `docker-compose exec app php artisan cache:clear`

---

## Testing Tips

1. **Use Postman's Collection Runner** to test rate limiting automatically
2. **Save requests** to your collection for easy re-testing
3. **Use environment variables** for the base URL and secret IDs
4. **Check response times** - encryption/decryption should be fast
5. **Test edge cases**: empty strings, very long text, special characters
