<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Voucher;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class VoucherController extends Controller
{
    /**
     * Display a list of active vouchers.
     * For simplicity, all vouchers in the 'vouchers' table are considered active.
     *
     * @return \Illuminate\Http\JsonResponse
     */
    public function index()
    {
        // Retrieve all vouchers
        $vouchers = Voucher::all();

        // Return the list of vouchers
        return response()->json([
            'message' => 'Active vouchers retrieved successfully.',
            'vouchers' => $vouchers,
        ]);
    }

    /**
     * Display a specific voucher.
     *
     * @param  int  $id
     * @return \Illuminate\Http\JsonResponse
     */
    public function show($id)
    {
        // Find the voucher by ID
        $voucher = Voucher::find($id);

        // If voucher not found, return error
        if (!$voucher) {
            return response()->json(['message' => 'Voucher not found.'], 404);
        }

        // Return the voucher details
        return response()->json([
            'message' => 'Voucher details retrieved successfully.',
            'voucher' => $voucher,
        ]);
    }
}