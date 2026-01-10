<?php

namespace App\Repositories;

use App\Models\Secret;

interface SecretRepositoryInterface
{
    public function create(array $data): Secret;
    public function findByUniqueId(string $uniqueId): ?Secret;
    public function delete(Secret $secret): bool;
}
