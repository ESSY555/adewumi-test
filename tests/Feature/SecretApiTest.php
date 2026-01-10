<?php

namespace Tests\Feature;

use App\Models\Secret;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class SecretApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_can_create_secret(): void
    {
        $response = $this->postJson('/api/v1/secrets', [
            'text' => 'My secret password',
        ]);

        $response->assertStatus(201)
            ->assertJsonStructure([
                'id',
                'url',
            ]);

        $this->assertDatabaseHas('secrets', [
            'unique_id' => $response->json('id'),
        ]);
    }

    public function test_can_create_secret_with_ttl(): void
    {
        $response = $this->postJson('/api/v1/secrets', [
            'text' => 'My secret password',
            'ttl' => 60,
        ]);

        $response->assertStatus(201);

        $secret = Secret::where('unique_id', $response->json('id'))->first();
        $this->assertNotNull($secret->expires_at);
    }

    public function test_validation_requires_text_field(): void
    {
        $response = $this->postJson('/api/v1/secrets', []);

        $response->assertStatus(422)
            ->assertJsonStructure([
                'message',
                'errors' => [
                    'text',
                ],
            ]);
    }

    public function test_validation_rejects_invalid_ttl(): void
    {
        $response = $this->postJson('/api/v1/secrets', [
            'text' => 'My secret',
            'ttl' => -1,
        ]);

        $response->assertStatus(422);
    }

    public function test_can_retrieve_secret(): void
    {
        $secret = Secret::create([
            'unique_id' => '550e8400-e29b-41d4-a716-446655440000',
            'encrypted_content' => 'My secret password',
            'expires_at' => null,
        ]);

        $response = $this->getJson("/api/v1/secrets/{$secret->unique_id}");

        $response->assertStatus(200)
            ->assertJson([
                'text' => 'My secret password',
            ]);
    }

    public function test_retrieving_secret_returns_404_when_not_found(): void
    {
        $response = $this->getJson('/api/v1/secrets/non-existent-id');

        $response->assertStatus(404)
            ->assertJson([
                'message' => 'Secret not found or has expired.',
            ]);
    }

    /**
     * Test that verifies the note is deleted after reading (burn-on-read).
     * This is the key requirement for the Secure Drop feature.
     */
    public function test_secret_is_deleted_after_reading(): void
    {
        $secret = Secret::create([
            'unique_id' => '550e8400-e29b-41d4-a716-446655440000',
            'encrypted_content' => 'My secret password',
            'expires_at' => null,
        ]);

        $uniqueId = $secret->unique_id;

        // First retrieval: should succeed
        $response = $this->getJson("/api/v1/secrets/{$uniqueId}");
        $response->assertStatus(200)
            ->assertJson([
                'text' => 'My secret password',
            ]);

        // Verify secret is deleted from database
        $this->assertDatabaseMissing('secrets', [
            'unique_id' => $uniqueId,
        ]);

        // Second retrieval: should fail with 404
        $response = $this->getJson("/api/v1/secrets/{$uniqueId}");
        $response->assertStatus(404);
    }

    public function test_expired_secret_returns_404(): void
    {
        $secret = Secret::create([
            'unique_id' => '550e8400-e29b-41d4-a716-446655440000',
            'encrypted_content' => 'My secret password',
            'expires_at' => now()->subHour(),
        ]);

        $response = $this->getJson("/api/v1/secrets/{$secret->unique_id}");

        $response->assertStatus(404);

        // Expired secret should be deleted
        $this->assertDatabaseMissing('secrets', [
            'unique_id' => $secret->unique_id,
        ]);
    }

    public function test_rate_limiting_on_create_endpoint(): void
    {
        // Make 10 requests (the limit)
        for ($i = 0; $i < 10; $i++) {
            $response = $this->postJson('/api/v1/secrets', [
                'text' => "Secret {$i}",
            ]);
            $response->assertStatus(201);
        }

        // 11th request should be rate limited
        $response = $this->postJson('/api/v1/secrets', [
            'text' => 'Secret 11',
        ]);

        $response->assertStatus(429);
    }
}
