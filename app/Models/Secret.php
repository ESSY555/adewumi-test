<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Crypt;

class Secret extends Model
{
    protected $fillable = [
        'unique_id',
        'encrypted_content',
        'expires_at',
    ];

    protected $casts = [
        'expires_at' => 'datetime',
    ];

    /**
     * Generate a unique ID for the secret
     */
    public static function generateUniqueId(): string
    {
        return Str::uuid()->toString();
    }

    /**
     * Encrypt the content before storing
     */
    public function setEncryptedContentAttribute($value): void
    {
        $this->attributes['encrypted_content'] = Crypt::encryptString($value);
    }

    /**
     * Decrypt the content when retrieving
     */
    public function getDecryptedContentAttribute(): string
    {
        return Crypt::decryptString($this->encrypted_content);
    }

    /**
     * Check if the secret has expired
     */
    public function isExpired(): bool
    {
        if ($this->expires_at === null) {
            return false;
        }

        return $this->expires_at->isPast();
    }
}
