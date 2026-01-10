<?php

namespace App\Repositories;

use App\Models\Secret;

class SecretRepository implements SecretRepositoryInterface
{
    public function create(array $data): Secret
    {
        return Secret::create($data);
    }

    public function findByUniqueId(string $uniqueId): ?Secret
    {
        return Secret::where('unique_id', $uniqueId)->first();
    }

    public function delete(Secret $secret): bool
    {
        return $secret->delete();
    }
}
