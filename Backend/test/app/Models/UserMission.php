<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class UserMission extends Model
{
    use HasFactory;

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'user_id',
        'mission_id',
        'proof',
        'status', // REVISI: Ganti is_completed dengan status
    ];

    /**
     * Get the user that owns the user mission.
     */
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Get the mission that owns the user mission.
     */
    public function mission()
    {
        return $this->belongsTo(Mission::class);
    }
}

