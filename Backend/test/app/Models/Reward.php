<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Reward extends Model
{
    use HasFactory;

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'user_id',
        'email',
        'phone',
        'balance',
    ];

    /**
     * Get the user that owns the reward.
     */
    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
