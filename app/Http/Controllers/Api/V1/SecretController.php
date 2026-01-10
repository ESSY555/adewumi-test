<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Services\SecretService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

/**
 * @group Secure Drop API
 *
 * API for creating and retrieving self-destructing secure notes.
 */
class SecretController extends Controller
{
    public function __construct(
        private SecretService $secretService
    ) {
    }

    /**
     * Create a Secret
     *
     * Creates a new secure note that will be permanently deleted after being viewed once.
     *
     * @bodyParam text string required The text content to encrypt and store. Example: "My secret password"
     * @bodyParam ttl integer optional Time to live in minutes. The secret will expire after this duration. Example: 60
     *
     * @response 201 {
     *   "id": "550e8400-e29b-41d4-a716-446655440000",
     *   "url": "http://localhost:8000/api/v1/secrets/550e8400-e29b-41d4-a716-446655440000"
     * }
     * @response 422 {
     *   "message": "The given data was invalid.",
     *   "errors": {
     *     "text": ["The text field is required."]
     *   }
     * }
     */
    public function store(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'text' => 'required|string',
            'ttl' => 'nullable|integer|min:1|max:10080', // Max 7 days
        ]);

        if ($validator->fails()) {
            return response()->json([
                'message' => 'The given data was invalid.',
                'errors' => $validator->errors(),
            ], 422);
        }

        $secret = $this->secretService->createSecret(
            $request->input('text'),
            $request->input('ttl')
        );

        return response()->json([
            'id' => $secret->unique_id,
            'url' => url("/api/v1/secrets/{$secret->unique_id}"),
        ], 201);
    }

    /**
     * Retrieve and Delete a Secret
     *
     * Retrieves the decrypted content of a secret and permanently deletes it (burn on read).
     * This endpoint can only be called once per secret.
     *
     * @urlParam id string required The unique ID of the secret. Example: 550e8400-e29b-41d4-a716-446655440000
     *
     * @response 200 {
     *   "text": "My secret password"
     * }
     * @response 404 {
     *   "message": "Secret not found or has expired."
     * }
     */
    public function show(string $id): JsonResponse
    {
        $decryptedContent = $this->secretService->retrieveAndDelete($id);

        return response()->json([
            'text' => $decryptedContent,
        ]);
    }
}
