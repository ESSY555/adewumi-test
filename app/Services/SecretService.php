<?php

namespace App\Services;

use App\Exceptions\SecretNotFoundException;
use App\Models\Secret;
use App\Repositories\SecretRepositoryInterface;
use Carbon\Carbon;

class SecretService
{
    public function __construct(
        private SecretRepositoryInterface $repository
    ) {
    }

    /**
     * Create a new secret
     */
    public function createSecret(string $content, ?int $ttlMinutes = null): Secret
    {
        $uniqueId = Secret::generateUniqueId();
        $expiresAt = $ttlMinutes ? Carbon::now()->addMinutes($ttlMinutes) : null;

        return $this->repository->create([
            'unique_id' => $uniqueId,
            'encrypted_content' => $content, // Will be encrypted via model mutator
            'expires_at' => $expiresAt,
        ]);
    }

    /**
     * Retrieve and delete a secret (burn on read)
     *
     * @throws SecretNotFoundException
     */
    public function retrieveAndDelete(string $uniqueId): string
    {
        $secret = $this->repository->findByUniqueId($uniqueId);

        if (!$secret) {
            throw new SecretNotFoundException();
        }

        if ($secret->isExpired()) {
            $this->repository->delete($secret);
            throw new SecretNotFoundException();
        }

        $decryptedContent = $secret->decrypted_content;
        $this->repository->delete($secret);

        return $decryptedContent;
    }
}
