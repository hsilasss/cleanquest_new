<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Mission extends Model
{
    use HasFactory;

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'title',
        'description',
        'points',
        'image_url',
        'tanggal_aktif',
    ];

    /**
     * The attributes that should be cast.
     *
     * @var array<string, string>
     */
    protected $casts = [
        'tanggal_aktif' => 'date', // Cast tanggal_aktif to a date object
    ];

    /**
     * Get the user missions associated with the mission.
     */
    public function userMissions()
    {
        return $this->hasMany(UserMission::class);
    }
}
