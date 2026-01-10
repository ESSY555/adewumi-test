<?php

namespace Tests\Unit;

use App\Exceptions\SecretNotFoundException;
use App\Models\Secret;
use App\Repositories\SecretRepositoryInterface;
use App\Services\SecretService;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class SecretServiceTest extends TestCase
{
    use RefreshDatabase;

    private SecretRepositoryInterface $repository;
    private SecretService $service;

    protected function setUp(): void
    {
        parent::setUp();
        $this->repository = $this->createMock(SecretRepositoryInterface::class);
        $this->service = new SecretService($this->repository);
    }

    public function test_can_create_secret_without_ttl(): void
    {
        $content = 'My secret password';
        $uniqueId = '550e8400-e29b-41d4-a716-446655440000';

        $secret = new Secret();
        $secret->unique_id = $uniqueId;
        $secret->encrypted_content = $content;
        $secret->expires_at = null;

        $this->repository
            ->expects($this->once())
            ->method('create')
            ->with($this->callback(function ($data) use ($content) {
                return isset($data['unique_id'])
                    && isset($data['encrypted_content'])
                    && $data['encrypted_content'] === $content
                    && $data['expires_at'] === null;
            }))
            ->willReturn($secret);

        $result = $this->service->createSecret($content);

        $this->assertInstanceOf(Secret::class, $result);
        $this->assertEquals($uniqueId, $result->unique_id);
    }

    public function test_can_create_secret_with_ttl(): void
    {
        $content = 'My secret password';
        $ttlMinutes = 60;

        $secret = new Secret();
        $secret->unique_id = '550e8400-e29b-41d4-a716-446655440000';
        $secret->encrypted_content = $content;
        $secret->expires_at = Carbon::now()->addMinutes($ttlMinutes);

        $this->repository
            ->expects($this->once())
            ->method('create')
            ->with($this->callback(function ($data) use ($ttlMinutes) {
                return isset($data['expires_at'])
                    && $data['expires_at'] instanceof Carbon
                    && $data['expires_at']->isFuture();
            }))
            ->willReturn($secret);

        $result = $this->service->createSecret($content, $ttlMinutes);

        $this->assertInstanceOf(Secret::class, $result);
    }

    public function test_retrieve_and_delete_returns_decrypted_content(): void
    {
        $uniqueId = '550e8400-e29b-41d4-a716-446655440000';
        $plainText = 'My secret password';

        // Create a real secret instance to test encryption/decryption
        $secret = Secret::make([
            'unique_id' => $uniqueId,
            'encrypted_content' => $plainText, // Will be encrypted by mutator
            'expires_at' => null,
        ]);

        $this->repository
            ->expects($this->once())
            ->method('findByUniqueId')
            ->with($uniqueId)
            ->willReturn($secret);

        $this->repository
            ->expects($this->once())
            ->method('delete')
            ->with($secret);

        $result = $this->service->retrieveAndDelete($uniqueId);

        $this->assertEquals($plainText, $result);
    }

    public function test_retrieve_and_delete_throws_exception_when_secret_not_found(): void
    {
        $uniqueId = 'non-existent-id';

        $this->repository
            ->expects($this->once())
            ->method('findByUniqueId')
            ->with($uniqueId)
            ->willReturn(null);

        $this->expectException(SecretNotFoundException::class);

        $this->service->retrieveAndDelete($uniqueId);
    }

    public function test_retrieve_and_delete_deletes_expired_secret_and_throws_exception(): void
    {
        $uniqueId = '550e8400-e29b-41d4-a716-446655440000';

        $secret = new Secret();
        $secret->unique_id = $uniqueId;
        $secret->encrypted_content = 'encrypted';
        $secret->expires_at = Carbon::now()->subHour(); // Expired

        $this->repository
            ->expects($this->once())
            ->method('findByUniqueId')
            ->with($uniqueId)
            ->willReturn($secret);

        $this->repository
            ->expects($this->once())
            ->method('delete')
            ->with($secret);

        $this->expectException(SecretNotFoundException::class);

        $this->service->retrieveAndDelete($uniqueId);
    }

    /**
     * Test that verifies the note is deleted after reading (burn-on-read).
     * This is the key requirement for the Secure Drop feature.
     */
    public function test_secret_is_deleted_after_reading(): void
    {
        $uniqueId = '550e8400-e29b-41d4-a716-446655440000';
        $plainText = 'My secret password';

        $secret = Secret::make([
            'unique_id' => $uniqueId,
            'encrypted_content' => $plainText,
            'expires_at' => null,
        ]);

        // First call: secret exists
        $this->repository
            ->expects($this->exactly(2))
            ->method('findByUniqueId')
            ->with($uniqueId)
            ->willReturnOnConsecutiveCalls($secret, null);

        // Delete should be called once
        $this->repository
            ->expects($this->once())
            ->method('delete')
            ->with($secret);

        // First retrieval: should succeed
        $result = $this->service->retrieveAndDelete($uniqueId);
        $this->assertEquals($plainText, $result);

        // Second retrieval: should throw exception because secret was deleted
        $this->expectException(SecretNotFoundException::class);
        $this->service->retrieveAndDelete($uniqueId);
    }
}
