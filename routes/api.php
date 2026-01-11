<?php

use App\Http\Controllers\Api\V1\SecretController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {
    // Rate limit: 10 requests per minute for creating secrets
    Route::post('/secrets', [SecretController::class, 'store'])->middleware('throttle:10,1');
    Route::get('/secrets/{id}', [SecretController::class, 'show']);
});



