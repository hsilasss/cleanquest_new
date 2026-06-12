<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB; // Import DB facade

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('user_missions', function (Blueprint $table) {
            // 1. Tambahkan kolom 'status'
            // Default: 'belum dikerjakan' adalah status awal
            $table->string('status')->default('belum dikerjakan')->after('proof');
        });

        // 2. Migrasikan data dari 'is_completed' ke 'status'
        // Ini akan menetapkan 'selesai' jika is_completed TRUE, dan 'belum dikerjakan' jika FALSE
        DB::table('user_missions')->where('is_completed', true)->update(['status' => 'selesai']);
        DB::table('user_missions')->where('is_completed', false)->update(['status' => 'belum dikerjakan']);


        Schema::table('user_missions', function (Blueprint $table) {
            // 3. Hapus kolom 'is_completed'
            $table->dropColumn('is_completed');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('user_missions', function (Blueprint $table) {
            // Saat rollback, tambahkan kembali kolom 'is_completed' (sebagai boolean)
            // Dan migrasikan data kembali (jika diperlukan untuk rollback yang utuh)
            $table->boolean('is_completed')->default(false)->after('proof');
        });

        // Migrasikan data dari 'status' kembali ke 'is_completed'
        // Ini mungkin tidak sepenuhnya akurat karena 'pending' tidak memiliki representasi boolean
        // Untuk tujuan rollback, kita asumsikan hanya 'selesai' yang menjadi TRUE
        DB::table('user_missions')->where('status', 'selesai')->update(['is_completed' => true]);
        DB::table('user_missions')->whereIn('status', ['pending', 'belum dikerjakan'])->update(['is_completed' => false]);

        Schema::table('user_missions', function (Blueprint $table) {
            // Hapus kolom 'status'
            $table->dropColumn('status');
        });
    }
};

