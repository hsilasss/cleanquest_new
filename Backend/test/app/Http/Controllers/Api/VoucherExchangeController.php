<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\VoucherExchange;
use App\Models\Voucher;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Str; // For generating random strings (tokens)
use Illuminate\Support\Facades\Validator;

class VoucherExchangeController extends Controller
{
    /**
     * Handle the exchange of points for a voucher.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function exchange(Request $request)
    {
        // Get the authenticated user
        $user = Auth::user();

        // Validate incoming request data
        $validator = Validator::make($request->all(), [
            'voucher_id' => 'required|exists:vouchers,id', // Ensure voucher_id exists in the vouchers table
        ]);

        // If validation fails, return error response
        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        // Find the voucher to be exchanged
        $voucher = Voucher::find($request->voucher_id);

        // Check if the user has enough points
        if ($user->points < $voucher->points) {
            return response()->json(['message' => 'Insufficient points to exchange for this voucher.'], 400);
        }

        // Deduct points from the user
        $user->points -= $voucher->points;
        $user->save();

        // Generate a unique token for the voucher exchange
        $token = Str::random(32); // Generates a random 32-character string

        // Create a new voucher exchange record
        $voucherExchange = VoucherExchange::create([
            'user_id' => $user->id,
            'voucher_id' => $voucher->id,
            'token' => $token,
        ]);

        // In a real application, you would typically send this token to the user via email, SMS, or display it in the app.
        // For this example, we'll just return it in the response.

        // Return success response
        return response()->json([
            'message' => 'Voucher exchanged successfully. Here is your token:',
            'voucher_exchange' => $voucherExchange,
            'voucher_token' => $token,
            'current_points' => $user->points,
        ], 201);
    }
}

