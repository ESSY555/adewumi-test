<?php

namespace App\Exceptions;

use Exception;
use Illuminate\Http\JsonResponse;

class SecretNotFoundException extends Exception
{
    public function render(): JsonResponse
    {
        return response()->json([
            'message' => 'Secret not found or has expired.',
        ], 404);
    }
}
