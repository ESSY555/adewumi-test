# Quick Test - POST /secrets Endpoint

## Basic Test (Single Request)

### Postman Setup:
1. **Method**: `POST`
2. **URL**: `http://localhost:8000/api/v1/secrets`
3. **Headers Tab**:
   ```
   Key: Content-Type
   Value: application/json
   ```
4. **Body Tab**:
   - Select `raw`
   - Select `JSON` from dropdown
   - Paste:
   ```json
   {
     "text": "My secret message"
   }
   ```
5. Click **Send**

### Expected Response (201):
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "url": "http://localhost:8000/api/v1/secrets/550e8400-e29b-41d4-a716-446655440000"
}
```

---

## Test Rate Limiting (10 requests per minute)

### Option 1: Manual Testing
1. Use the same request from above
2. Click **Send** 10 times (should all return 201)
3. Click **Send** an 11th time → Should return **429**

### Option 2: Using Postman Collection Runner
1. Save your request to a collection
2. Click on the collection → **Run**
3. Set **Iterations**: `11`
4. Set **Delay**: `100ms` (to send quickly)
5. Click **Run Secure Drop API**
6. Check results:
   - First 10: Status 201
   - 11th: Status 429

### Expected 429 Response:
```json
{
  "message": "Too many requests. Please try again later."
}
```

---

## Test with TTL (Optional)

### Same endpoint, different body:
```json
{
  "text": "Secret with expiration",
  "ttl": 60
}
```
- `ttl` = time to live in minutes (1-10080, max 7 days)

---

## Test Validation Errors

### Missing text field:
```json
{
  "ttl": 60
}
```
**Expected**: 422 with error message

### Invalid TTL:
```json
{
  "text": "My secret",
  "ttl": -1
}
```
**Expected**: 422 with validation error

---

## cURL Alternative (Command Line)

### Single request:
```bash
curl -X POST http://localhost:8000/api/v1/secrets \
  -H "Content-Type: application/json" \
  -d '{"text": "My secret message"}'
```

### Test rate limiting (11 requests):
```bash
for i in {1..11}; do
  echo "Request $i:"
  curl -X POST http://localhost:8000/api/v1/secrets \
    -H "Content-Type: application/json" \
    -d '{"text": "Test secret '$i'"}' \
    -w "\nStatus: %{http_code}\n\n"
done
```

### PowerShell (Windows):
```powershell
1..11 | ForEach-Object {
  Write-Host "Request $_"
  Invoke-RestMethod -Uri "http://localhost:8000/api/v1/secrets" `
    -Method POST `
    -ContentType "application/json" `
    -Body '{"text": "Test secret ' + $_ + '"}'
  Start-Sleep -Milliseconds 100
}
```

---

## Quick Checklist

- [ ] Request returns 201 with `id` and `url`
- [ ] First 10 requests all succeed (201)
- [ ] 11th request returns 429 (rate limited)
- [ ] Missing `text` returns 422
- [ ] Invalid `ttl` returns 422
- [ ] Response includes proper JSON structure
