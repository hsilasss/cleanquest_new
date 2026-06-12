<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use App\Models\Voucher;

class VoucherSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Voucher 1
        Voucher::create([
            'title' => 'Voucher Es Krim Gratis',
            'image_path' => 'icecream.png', // Placeholder image path
            'points' => 500, // Poin yang dibutuhkan untuk menukarkan voucher ini
        ]);

        // Voucher 2 (Tambahan)
        Voucher::create([
            'title' => 'Diskon 30% Pakaian',
            'image_path' => 'fashion1.png', // Placeholder image path
            'points' => 1200, // Poin yang dibutuhkan untuk menukarkan voucher ini
        ]);

        // Anda bisa menambahkan voucher lain di sini
        // Voucher::create([
        //     'title' => 'Diskon 20% Kopi',
        //     'image_path' => 'coffee_discount.png',
        //     'points' => 750,
        // ]);
    }
}

