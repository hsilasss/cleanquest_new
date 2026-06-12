<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use App\Models\Mission;
use Carbon\Carbon; // Import Carbon for date handling

class MissionSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Mission 1
        Mission::create([
            'title' => 'Bersihkan Taman Depan',
            'description' => 'Misi membersihkan area taman depan rumah dari sampah dan daun kering.',
            'points' => 100,
            'image_url' => 'clean_garden.png', // Placeholder image URL
            'tanggal_aktif' => Carbon::today()->toDateString(), // Set to today's date
        ]);

        // Mission 2
        Mission::create([
            'title' => 'Rapikan Kamar Tidur',
            'description' => 'Misi merapikan tempat tidur, melipat pakaian, dan menyapu lantai kamar.',
            'points' => 75,
            'image_url' => 'clean_room.png', // Placeholder image URL
            'tanggal_aktif' => Carbon::today()->toDateString(), // Set to today's date
        ]);

        // Anda bisa menambahkan misi lain di sini
        // Mission::create([
        //     'title' => 'Daur Ulang Botol Plastik',
        //     'description' => 'Kumpulkan 10 botol plastik dan daur ulang.',
        //     'points' => 120,
        //     'image_url' => 'recycle_bottles.png',
        //     'tanggal_aktif' => Carbon::today()->toDateString(),
        // ]);
    }
}

