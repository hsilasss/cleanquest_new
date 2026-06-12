<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Mission;
use App\Models\UserMission;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\Rule;
use GuzzleHttp\Client;

class ApiController extends Controller
{
    /**
     * Handle user registration.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function register(Request $request)
    {
        // Validate incoming request data
        $validator = Validator::make($request->all(), [
            'username' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
            'password' => 'required|string|min:8|confirmed',
            'phone_number' => 'required|string|max:20',
            'birth_date' => 'required|date',
        ]);

        // If validation fails, return error response
        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        // Create a new user
        $user = User::create([
            'username' => $request->username,
            'email' => $request->email,
            'password' => Hash::make($request->password),
            'phone_number' => $request->phone_number,
            'birth_date' => $request->birth_date,
            'points' => 0, // Default points for new users
            'profile_picture' => null, // <<< HANYA INI YANG DITAMBAHKAN/DIUBAH
        ]);

        // Attach all existing missions to the new user
        $missions = Mission::all();
        foreach ($missions as $mission) {
            UserMission::create([
                'user_id' => $user->id,
                'mission_id' => $mission->id,
                'proof' => '', // No proof initially
                'is_completed' => false, // Not completed initially
            ]);
        }

        // Generate a new API token for the user
        $token = $user->createToken('authToken')->plainTextToken;

        // Return success response with user data and token
        return response()->json([
            'message' => 'User registered successfully and missions assigned.',
            'user' => $user,
            'access_token' => $token,
            'token_type' => 'Bearer',
        ], 201);
    }

    /**
     * Handle user login.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function login(Request $request)
    {
        // Ubah 'email' jadi 'identity'
        $validator = Validator::make($request->all(), [
            'identity' => 'required|string',
            'password' => 'required|string',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        // Cari user berdasarkan username atau email
        $user = \App\Models\User::where('email', $request->identity)
            ->orWhere('username', $request->identity)
            ->first();

        // Jika user tidak ditemukan atau password salah
        if (!$user || !\Hash::check($request->password, $user->password)) {
            return response()->json(['message' => 'Invalid login credentials.'], 401);
        }

        // Hapus token sebelumnya
        $user->tokens()->delete();

        // Buat token baru
        $token = $user->createToken('authToken')->plainTextToken;

        return response()->json([
            'message' => 'User logged in successfully.',
            'user' => $user,
            'access_token' => $token,
            'token_type' => 'Bearer',
        ]);
    }

    /**
     * Handle user logout.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function logout(Request $request)
    {
        // Revoke the current user's API token
        $request->user()->currentAccessToken()->delete();

        // Return success response
        return response()->json(['message' => 'Successfully logged out.']);
    }

    /**
     * Get the authenticated user's data.
     * Mengambil data user yang sedang login.
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function getUserData(Request $request)
    {
        // $request->user() secara otomatis mendapatkan user yang sedang login
        // berdasarkan token yang dikirim di header.
        return response()->json($request->user());
    }

    /**
     * Update the authenticated user's profile.
     * Memperbarui profil user yang sedang login.
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function updateProfile(Request $request)
    {
        $user = Auth::user(); // Get the authenticated user

        // Validate incoming request data
        $validator = Validator::make($request->all(), [
            'username' => 'required|string|max:255',
            'email' => [
                'required',
                'string',
                'email',
                'max:255',
                Rule::unique('users')->ignore($user->id), // Ignore current user's ID
            ],
            'phone_number' => 'required|string|max:20',
            'birth_date' => 'required|date',
            // Password fields are optional, only validate if provided
            'password' => 'nullable|string|min:8|confirmed',
        ]);

        // If validation fails, return error response
        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        // Update user data
        $user->username = $request->username;
        $user->email = $request->email;
        $user->phone_number = $request->phone_number;
        $user->birth_date = $request->birth_date;

        // Update password if provided
        if ($request->filled('password')) {
            $user->password = Hash::make($request->password);
        }

        $user->save();

        return response()->json([
            'message' => 'Profil berhasil diperbarui.',
            'user' => $user->fresh(), // <<< HANYA INI YANG DIUBAH (agar foto profil terbaru ikut terupdate)
        ], 200);
    }

    // --- BAGIAN BARU UNTUK FOTO PROFIL ---
    /**
     * Update the user's profile picture using Imgur.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function updateProfilePicture(Request $request)
    {
        $user = Auth::user();

        $validator = Validator::make($request->all(), [
            'profile_picture' => 'required|image|mimes:jpeg,png,jpg,gif|max:2048', // Max 2MB
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        if ($request->hasFile('profile_picture')) {
            $file = $request->file('profile_picture');

            // Inisialisasi Guzzle HTTP client
            $client = new Client();
            $imgurClientId = env('IMGUR_CLIENT_ID');

            if (empty($imgurClientId)) {
                return response()->json(['message' => 'Imgur Client ID is not configured.'], 500);
            }

            try {
                // Konversi gambar ke base64 (Imgur API sering menerima ini)
                $base64Image = base64_encode(file_get_contents($file->getRealPath()));

                // Kirim request POST ke Imgur API
                $response = $client->request('POST', 'https://api.imgur.com/3/image', [
                    'headers' => [
                        'Authorization' => 'Client-ID ' . $imgurClientId,
                        'Content-Type' => 'application/x-www-form-urlencoded',
                    ],
                    'form_params' => [
                        'image' => $base64Image,
                        // Anda bisa menambahkan 'title', 'description', 'album', dll.
                    ],
                ]);

                $responseData = json_decode($response->getBody()->getContents(), true);

                if ($responseData['success'] && isset($responseData['data']['link'])) {
                    $fileUrl = $responseData['data']['link']; // Ini adalah URL gambar dari Imgur

                    // Hapus gambar lama jika ada dan bukan gambar default (dari Imgur juga)
                    if ($user->profile_picture && !str_contains($user->profile_picture, 'default_avatar.png')) {
                        // Untuk Imgur, biasanya tidak ada API untuk menghapus gambar hanya dengan URL.
                        // Imgur menyediakan 'deletehash' saat upload. Anda harus menyimpan deletehash
                        // di database untuk bisa menghapus gambar lama. Ini membuat kompleksitas sangat tinggi.
                        // Untuk saat ini, kita abaikan penghapusan gambar lama di Imgur.
                        // Anda harus mempertimbangkan konsekuensinya (gambar lama tetap ada di Imgur).
                    }

                    $user->profile_picture = $fileUrl;
                    $user->save();

                    return response()->json([
                        'message' => 'Foto profil berhasil diperbarui via Imgur!',
                        'profile_picture_url' => $fileUrl,
                        'user' => $user->fresh(),
                    ]);
                } else {
                    return response()->json([
                        'message' => 'Gagal mengunggah foto ke Imgur.',
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

        return response()->json(['message' => 'Tidak ada foto profil yang diunggah.'], 400);
    }
    // --- AKHIR BAGIAN BARU UNTUK FOTO PROFIL ---

    // Catatan: Jika ada metode lain seperti activeMissions, submitMissionProof,
    // getUserMissionsHistory, dll. yang sebelumnya ada di UserMissionController,
    // pastikan Anda sudah memindahkannya ke ApiController ini jika ApiController ini adalah
    // satu-satunya controller API Anda. Kode yang Anda berikan tidak mencakupnya,
    // jadi saya tidak menyertakannya di sini.
}
