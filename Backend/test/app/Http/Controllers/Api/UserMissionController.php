<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\UserMission;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Validator;
use Carbon\Carbon;
use GuzzleHttp\Client;

/**
 * @mixin \Illuminate\Filesystem\FilesystemManager // Tambahkan baris ini
 */

class UserMissionController extends Controller
{
    /**
     * Display active missions for the authenticated user.
     * Missions are active if their 'tanggal_aktif' is today.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function activeMissions(Request $request)
{
    $user = Auth::user();

    $allUserMissions = UserMission::with('mission')
        ->where('user_id', $user->id)
        ->get();

    return response()->json([
        'user_id' => $user->id,
        'count' => $allUserMissions->count(),
        'missions' => $allUserMissions,
    ]);
}

    /**
     * Display the progress of a specific user mission.
     *
     * @param  int  $userMissionId
     * @return \Illuminate\Http\JsonResponse
     */
    public function showMissionProgress($userMissionId)
    {
        // Get the authenticated user
        $user = Auth::user();

        // Find the user mission by ID and ensure it belongs to the authenticated user
        $userMission = UserMission::with('mission')
            ->where('id', $userMissionId)
            ->where('user_id', $user->id)
            ->first();

        // If user mission not found, return error
        if (!$userMission) {
            return response()->json(['message' => 'User mission not found or does not belong to you.'], 404);
        }

        // Return the mission progress
        return response()->json([
            'message' => 'Mission progress retrieved successfully.',
            'mission_progress' => [
                'id' => $userMission->id,
                'title' => $userMission->mission->title,
                'description' => $userMission->mission->description,
                'points' => $userMission->mission->points,
                'status' => $userMission->status, // Mengembalikan status
                'proof' => $userMission->proof,
            ],
        ]);
    }

    /**
     * Submit proof of mission completion from the user as a file upload.
     * The mission status will be set to 'pending' after submission.
     * Proof will be uploaded to Imgur.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  int  $userMissionId
     * @return \Illuminate\Http\JsonResponse
     */
    public function submitMissionProof(Request $request, $userMissionId)
    {
        try {
            $user = Auth::user();

            $validator = Validator::make($request->all(), [
                'proof_file' => 'required|file|mimes:jpeg,png,jpg,mp4,mov,avi|max:10240', // Max 10MB
            ]);

            if ($validator->fails()) {
                return response()->json(['errors' => $validator->errors()], 422);
            }

            $userMission = UserMission::where('id', $userMissionId)
                ->where('user_id', $user->id)
                ->first();

            if (!$userMission) {
                return response()->json(['message' => 'User mission not found or does not belong to you.'], 404);
            }

            if ($userMission->status == 'pending' || $userMission->status == 'selesai') {
                return response()->json(['message' => 'Mission cannot be submitted. Its status is already ' . $userMission->status . '.'], 400);
            }

            if ($request->hasFile('proof_file')) {
                $file = $request->file('proof_file');

                // --- INI ADALAH BAGIAN BARU UNTUK UPLOAD KE IMGUR ---
                $client = new Client();
                $imgurClientId = env('IMGUR_CLIENT_ID');

                if (empty($imgurClientId)) {
                    return response()->json(['message' => 'Imgur Client ID is not configured.'], 500);
                }

                try {
                    // Konversi file ke base64
                    $base64File = base64_encode(file_get_contents($file->getRealPath()));

                    // Kirim request POST ke Imgur API
                    $response = $client->request('POST', 'https://api.imgur.com/3/image', [ // Imgur menerima video juga di endpoint ini
                        'headers' => [
                            'Authorization' => 'Client-ID ' . $imgurClientId,
                            'Content-Type' => 'application/x-www-form-urlencoded',
                        ],
                        'form_params' => [
                            'image' => $base64File,
                            'type' => ($file->getClientMimeType() === 'video/mp4' || $file->getClientMimeType() === 'video/quicktime' || $file->getClientMimeType() === 'video/x-msvideo') ? 'video' : 'base64', // Tentukan tipe untuk Imgur
                            // Anda bisa menambahkan 'title', 'description', dll.
                        ],
                    ]);

                    $responseData = json_decode($response->getBody()->getContents(), true);

                    if ($responseData['success'] && isset($responseData['data']['link'])) {
                        $fileUrl = $responseData['data']['link']; // Ini adalah URL gambar/video dari Imgur

                        // Catatan: Imgur tidak menyediakan API untuk menghapus file hanya dengan URL.
                        // Jika Anda ingin menghapus bukti misi lama, Anda perlu menyimpan 'deletehash'
                        // yang diberikan Imgur di database dan menggunakan API penghapusan Imgur.
                        // Untuk saat ini, kita abaikan penghapusan file lama di Imgur.

                        $userMission->proof = $fileUrl;
                        $userMission->status = 'pending';
                        $userMission->save();

                        return response()->json([
                            'message' => 'Bukti misi berhasil diunggah via Imgur!',
                            'user_mission' => $userMission->fresh(),
                            'file_url' => $fileUrl,
                        ], 200);
                    } else {
                        return response()->json([
                            'message' => 'Gagal mengunggah bukti misi ke Imgur.',
                            'imgur_response' => $responseData,
                        ], 500);
                    }
                } catch (\GuzzleHttp\Exception\ClientException $e) {
                    $responseBody = $e->getResponse()->getBody()->getContents();
                    return response()->json([
                        'message' => 'Imgur API Error: ' . $e->getMessage(),
                        'imgur_error_response' => json_decode($responseBody, true),
                    ], $e->getCode());
                } catch (\Exception $e) {
                    return response()->json([
                        'message' => 'Server Error: ' . $e->getMessage(),
                        'line' => $e->getLine(),
                        'file' => $e->getFile(),
                    ], 500);
                }
            }

            return response()->json(['message' => 'No file was uploaded.'], 400);
        } catch (\Exception $e) {
            return response()->json([
                'message' => 'Server Error: ' . $e->getMessage(),
                'line' => $e->getLine(),
                'file' => $e->getFile(),
            ], 500);
        }
    }
    /**
     * Get user missions history for a specific user, filtered by status.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  int  $userId
     * @return \Illuminate\Http\JsonResponse
     */
    public function getUserMissionsHistory(Request $request, $userId)
    {
        // Pastikan hanya user yang bersangkutan atau admin yang bisa mengakses
        if (Auth::id() != $userId) {
            return response()->json(['message' => 'Unauthorized access.'], 403);
        }

        $query = UserMission::with('mission')
            ->where('user_id', $userId);

        // REVISI: Filter berdasarkan status jika disediakan dalam request
        if ($request->has('statuses') && is_array($request->input('statuses'))) {
            $query->whereIn('status', $request->input('statuses'));
        }

        // Tambahkan pengurutan berdasarkan tanggal terbaru
        $userMissions = $query->orderBy('created_at', 'desc')->get(); // Mengurutkan berdasarkan waktu dibuat terbaru

        return response()->json([
            'message' => 'User missions history retrieved successfully.',
            'user_missions' => $userMissions,
        ]);
    }
}
