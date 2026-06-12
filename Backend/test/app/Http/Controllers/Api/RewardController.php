<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Reward;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Validator;

class RewardController extends Controller
{
    /**
     * Handle the exchange of points for e-wallet balance.
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
            'amount' => 'required|integer|min:5000', // Minimum exchange amount, adjust as needed
            'email' => 'required|string|email',
            'phone' => 'required|string|max:20',
        ]);

        // If validation fails, return error response
        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        // Define a conversion rate
        $pointsPerUnit = 0.1;
        $requiredPoints = $request->amount * $pointsPerUnit;

        // Check if the user has enough points
        if ($user->points < $requiredPoints) {
            return response()->json(['message' => 'Insufficient points for this exchange amount.'], 400);
        }

        // Deduct points from the user
        $user->points -= $requiredPoints;
        $user->save();

        // Create a new reward record
        $reward = Reward::create([
            'user_id' => $user->id,
            'email' => $request->email,
            'phone' => $request->phone,
            'balance' => $request->amount, // The amount of e-wallet balance
        ]);

        // In a real application, you would integrate with an e-wallet API here
        // to actually transfer the balance. For this example, we just record it.

        // Return success response
        return response()->json([
            'message' => 'Points successfully exchanged for e-wallet balance.',
            'reward' => $reward,
            'current_points' => $user->points,
        ], 201);
    }
}

