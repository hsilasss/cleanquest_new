<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Voucher extends Model
{
    use HasFactory;

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'title',
        'image_path',
        'points',
    ];

    /**
     * Get the voucher exchanges associated with the voucher.
     */
    public function voucherExchanges()
    {
        return $this->hasMany(VoucherExchange::class);
    }
}

