<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class VoucherExchange extends Model
{
    use HasFactory;

    protected $table = 'vouchers_exchange'; // Specify the table name if it's different from the model name's plural form

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'user_id',
        'voucher_id',
        'token',
    ];

    /**
     * Get the user that owns the voucher exchange.
     */
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Get the voucher that was exchanged.
     */
    public function voucher()
    {
        return $this->belongsTo(Voucher::class);
    }
}

