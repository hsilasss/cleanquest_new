import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/user_mission.dart';
import '../models/voucher.dart';
import 'dart:async';
import 'package:image_picker/image_picker.dart'; // <<< PENTING: Pastikan ini ada
// <<< PENTING: Pastikan ini ada

class ApiService {
  // Ganti dengan base URL API Laravel Anda yang sudah di-deploy
  // Pastikan ini adalah URL dasar, tanpa /api
  static const String _baseUrl = 'http://http://127.0.0.1:8000/api';

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('authToken', token);
  }

  Future<String?> getToken() async {
    return _getToken();
  }

  Future<User?> getCurrentUser() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/user'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        // Pastikan User.fromJson menerima langsung object user, bukan di dalam key 'user'
        // Jika server mengembalikan {"user": {...}}, ubah menjadi User.fromJson(json['user'])
        return User.fromJson(json);
      } else {
        print(
          'Failed to fetch current user: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      print('Error getCurrentUser: $e');
      return null;
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    print(
  'DEBUG_API_SERVICE: Retrieved token: ${token != null ? token.substring(0, 20) + "..." : "NULL"}',
    );
    return token;
  }

  Future<void> _deleteToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('authToken');
  }

  Future<bool> ping() async {
    // CORRECTED: kBaseUrl should only be the domain, without the endpoint path
    const String kBaseUrl = String.fromEnvironment(
      'BASE_URL',
      // CHANGE THIS DEFAULT VALUE TO JUST THE BASE DOMAIN
      // For your Railway app, it should be: 'https://test-production-6d06.up.railway.app'
      defaultValue:
          'http://127.0.0.1:8000/api', // <--- Cek lagi apakah ini URL base saja tanpa '/api'
    );

    // The endpoint path
    final String endpointPath = '/ping';

    // Concatenate them
    final String apiUrl = '$kBaseUrl$endpointPath';

    // --- LOGGING DEBUGGING DIMULAI ---
    print('--- DEBUG API PING ---');
    print('Base URL (from app): $kBaseUrl');
    print(
      'Full API URL being used by app: $apiUrl',
    ); // This should now be correct
    // --- LOGGING DEBUGGING BERAKHIR ---

    try {
      final response = await http
          .get(Uri.parse(apiUrl))
          .timeout(const Duration(seconds: 15));

      // --- LOGGING DEBUGGING DIMULAI ---
      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('--- END DEBUG API PING ---');
      // --- LOGGING DEBUGGING BERAKHIR ---

      return response.statusCode == 200;
    } catch (e) {
      // --- LOGGING DEBUGGING DIMULAI ---
      print('Error during ping: $e');
      if (e is http.ClientException) {
        print('HTTP Client Exception Message: ${e.message}');
      } else if (e is FormatException) {
        print('Format Exception (likely bad URL): ${e.message}');
      } else if (e is TimeoutException) {
        print('Timeout Exception: Server took too long to respond.');
      }
      print('--- END DEBUG API PING ---');
      // --- LOGGING DEBUGGING BERAKHIR ---
      return false;
    }
  }

  Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (includeAuth) {
      final token = await _getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  // ---------------------------------------------------------------------------
  // Autentikasi (Register, Login, Logout)
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String phoneNumber,
    required String birthDate,
  }) async {
    final url = Uri.parse('$_baseUrl/register');
    final response = await http.post(
      url,
      headers: await _getHeaders(includeAuth: false),
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'phone_number': phoneNumber,
        'birth_date': birthDate,
      }),
    );

    final responseData = jsonDecode(response.body);
    if (response.statusCode == 201) {
      await _saveToken(responseData['access_token']);
      return {
        'success': true,
        'message': responseData['message'],
        'user_id': responseData['user']['id'],
      };
    } else {
      return {'success': false, 'data': responseData};
    }
  }

  Future<Map<String, dynamic>> login({
    required String identity,
    required String password,
  }) async {
    final url = Uri.parse('$_baseUrl/login');

      // DEBUG
      print('LOGIN URL: $url');
      print('BASE URL: $_baseUrl');
      print('IDENTITY: $identity');


    final response = await http.post(
      url,
      headers: await _getHeaders(includeAuth: false),
      body: jsonEncode({'identity': identity, 'password': password}),
    );

    // --- DEBUG PRINTS (KEEP THESE FOR NOW) ---
    print('DEBUG: Login API Response Status Code: ${response.statusCode}');
    print('DEBUG: Login API Response Body: ${response.body}');
    // -----------------------------------------

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200) {
      // REVISED: Look for 'access_token' instead of 'token'
      final token = responseData['access_token'];

      if (token != null && (token is String && token.isNotEmpty)) {
        // Added check for empty string
        await _saveToken(token);
        int? userId;
        // Ensure 'user' and 'id' exist in the response
        if (responseData.containsKey('user') &&
            responseData['user'] is Map &&
            (responseData['user'] as Map).containsKey('id')) {
          userId = responseData['user']['id'];
        }

        if (userId != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('currentUserId', userId);
          return {
            'success': true,
            'message': responseData['message'] ?? 'Login successful',
            'user_id': userId,
          };
        } else {
          print(
            'WARNING: Login successful (200 OK), but user ID missing from response.',
          );
          return {
            'success': false,
            'message': 'Login successful, but user ID missing.',
            'data': responseData,
          };
        }
      } else {
        print(
          'WARNING: Login successful (200 OK), but token not received or empty.',
        );
        return {
          'success': false,
          'message': 'Login successful, but token not received or empty.',
          'data': responseData,
        };
      }
    } else {
      // This path is for any non-200 status code (e.g., 401, 422, 500)
      return {
        'success': false,
        'data': responseData,
        'message': responseData['message'] ?? 'Unknown error from server',
      };
    }
  }

  Future<bool> logout() async {
    final url = Uri.parse('$_baseUrl/logout');
    final response = await http.post(url, headers: await _getHeaders());

    print('DEBUG_HTTP_RESPONSE_STATUS: ${response.statusCode}');
    print('DEBUG_HTTP_RESPONSE_BODY: ${response.body}');

    if (response.statusCode == 200) {
      await _deleteToken();
      return true;
    } else {
      print('Failed to logout: ${response.body}');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Data Pengguna (User)
  // ---------------------------------------------------------------------------

  Future<User?> getUserData(int? userId) async {
    final token = await _getToken(); // Mengambil token

    if (token == null) {
      print('GET_USER_DATA_ERROR: Autentikasi diperlukan. Tidak ada token ditemukan.');
      return null; // Mengembalikan null jika tidak ada token
    }

    // URL endpoint HANYA /user, karena server akan mengidentifikasi user dari token
    final url = Uri.parse('$_baseUrl/user');
    try {
      final response = await http.get(url, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        // Penting: Pastikan struktur JSON respons sesuai.
        // Jika responsnya { "user": { "id": 1, ... } }, maka perlu User.fromJson(data['user'])
        // Jika responsnya langsung { "id": 1, ... }, maka User.fromJson(data) sudah benar.
        // Berdasarkan controller yang diberikan sebelumnya (Auth::user()), kemungkinan respons langsung objek User.
        return User.fromJson(data);
      } else if (response.statusCode == 401) {
        print('GET_USER_DATA_ERROR: Token tidak valid atau kedaluwarsa. Status: 401 - ${response.body}');
        // Opsional: Lakukan logout otomatis di sini jika 401
        // _deleteToken(); // Jika token invalid, hapus token lama
        return null; // Mengembalikan null jika autentikasi gagal
      } else {
        // Tangani status code lain yang menunjukkan kegagalan
        print('GET_USER_DATA_ERROR: Gagal memuat data pengguna: ${response.statusCode} - ${response.body}');
        return null; // Mengembalikan null untuk error lain
      }
    } catch (e) {
      // Tangani error jaringan atau lainnya
      print('GET_USER_DATA_ERROR: Terjadi Exception saat mengambil data pengguna: $e');
      return null; // Mengembalikan null jika ada exception
    }
  }

  Future<List<UserMission>> getMissions() async {
    final url = Uri.parse('$_baseUrl/missions/active'); // Asumsi endpoint ini
    try {
      final response = await http.get(
      url,
      headers: await _getHeaders(),
    );

    print("=== MISSIONS RESPONSE ===");
    print("STATUS : ${response.statusCode}");
    print("BODY   : ${response.body}");
      

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        // Pastikan 'missions' ada dan berupa List
        if (data.containsKey('missions') && data['missions'] is List) {
          final List<dynamic> userMissionData = data['missions'];
          return userMissionData.map((json) => UserMission.fromJson(json)).toList();
        } else {
          print('GET_MISSIONS_ERROR: Response body does not contain "missions" list.');
          return []; // Mengembalikan list kosong jika data tidak valid
        }
      } else {
        print('GET_MISSIONS_ERROR: Failed to load active missions: ${response.statusCode} - ${response.body}');
        return []; // Mengembalikan list kosong jika status code non-200
      }
    } catch (e) {
      print('GET_MISSIONS_ERROR: Exception during getMissions: $e');
      return []; // Mengembalikan list kosong jika ada exception jaringan dll.
    }
  }

  // --- Metode LAMA untuk submit proof by URL (Opsional, bisa dihapus jika tidak dipakai) ---
  Future<bool> submitMissionProof({
    required int userMissionId,
    required String proofUrl,
  }) async {
    final url = Uri.parse('$_baseUrl/missions/$userMissionId/submit-proof'); // Pastikan endpoint ini benar
    final response = await http.post(
      url,
      headers: await _getHeaders(),
      body: jsonEncode({'proof_url': proofUrl}), // Mengirim URL
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      print(
        'Failed to submit proof by URL: ${response.statusCode} - ${response.body}',
      );
      return false;
    }
  }
  // --- END Metode LAMA ---

  // --- Metode BARU untuk upload bukti misi via file (sesuai kebutuhan Anda) ---
  Future<bool> uploadMissionProof({
    required int userMissionId,
    required XFile proofFile,
  }) async {
    // Perhatikan URL endpoint, sesuaikan dengan rute Laravel Anda
    final url = Uri.parse('$_baseUrl/user-missions/$userMissionId/submit-proof');
    final headers = await _getHeaders(includeAuth: true); // Dapatkan header dengan token

    try {
      var request = http.MultipartRequest('POST', url);

      // Tambahkan headers ke request.headers.
      // Penting: Jangan sertakan 'Content-Type': 'application/json' di sini,
      // karena MultipartRequest akan secara otomatis mengatur Content-Type yang benar.
      request.headers.addAll({
        'Accept': 'application/json',
        if (headers.containsKey('Authorization')) 'Authorization': headers['Authorization']!,
      });

      // Tambahkan file bukti. 'proof_file' harus cocok dengan nama field di backend Laravel.
      request.files.add(await http.MultipartFile.fromPath(
        'proof_file', // <<< PASTIKAN INI SAMA PERSIS dengan field di Laravel Controller Anda!
        proofFile.path,
        filename: proofFile.name,
      ));

     print('REQUEST HEADERS: ${request.headers}');
print('REQUEST URL: ${request.url}');
print('FILE PATH: ${proofFile.path}');

var response = await request.send();

print('STATUS CODE: ${response.statusCode}');

final responseBody = await response.stream.bytesToString();
print('RESPONSE BODY: $responseBody');

if (response.statusCode == 200) {
  print('Upload bukti berhasil!');
  return true;
} else {
  print('Gagal upload bukti.');
  final errorData = json.decode(responseBody);
  throw Exception(
      errorData['message'] ?? 'Failed to upload proof.');
}
    } catch (e) {
      print('Error dalam uploadMissionProof: $e');
      rethrow; // Lempar kembali exception agar bisa ditangkap di UI
    }
  }
  // --- END Metode BARU ---


  Future<List<UserMission>> getUserMissionsByStatus(int userId, List<String> statuses) async {
    // Bangun URL dengan parameter query untuk statuses
    final Map<String, dynamic> queryParams = {
      'statuses[]': statuses, // Kirim sebagai array parameter
    };
    final url = Uri.parse('$_baseUrl/user-missions-history/$userId').replace(queryParameters: queryParams);

    final response = await http.get(
      url,
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List<dynamic> userMissionData = data['user_missions'];
      return userMissionData.map((json) => UserMission.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load user missions history: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> updateUserProfile(Map<String, dynamic> userData) async {
    final url = Uri.parse('$_baseUrl/user/profile');
    final response = await http.post( // Menggunakan POST karena laravel Sanctum defaultnya POST untuk update profil
      url,
      headers: await _getHeaders(),
      body: jsonEncode(userData),
    );

    final responseData = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return {'success': true, 'message': responseData['message'], 'user': responseData['user']};
    } else {
      return {'success': false, 'data': responseData}; // Mengembalikan seluruh responseData untuk error
    }
  }

  // ---------------------------------------------------------------------------
  // Voucher
  // ---------------------------------------------------------------------------

  Future<List<Voucher>> fetchVouchers() async {
    final url = Uri.parse('$_baseUrl/vouchers');
    final response = await http.get(url, headers: await _getHeaders());

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List<dynamic> voucherData = data['vouchers'];
      return voucherData.map((json) => Voucher.fromJson(json)).toList();
    } else {
      throw Exception(
        'Failed to load vouchers: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<bool> exchangeVoucher({required int voucherId}) async {
    final url = Uri.parse('$_baseUrl/vouchers/exchange');
    final response = await http.post(
      url,
      headers: await _getHeaders(),
      body: jsonEncode({'voucher_id': voucherId}),
    );

    if (response.statusCode == 201) {
      return true;
    } else {
      print(
        'Failed to exchange voucher: ${response.statusCode} - ${response.body}',
      );
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Reward (Tukar Uang)
  // ---------------------------------------------------------------------------

  Future<bool> submitReward({
    required String phone,
    required String email,
    required int balance,
  }) async {
    final url = Uri.parse('$_baseUrl/rewards/exchange');
    final response = await http.post(
      url,
      headers: await _getHeaders(),
      body: jsonEncode({'phone': phone, 'email': email, 'amount': balance}),
    );

    if (response.statusCode == 201) {
      return true;
    } else {
      print(
        'Failed to submit reward: ${response.statusCode} - ${response.body}',
      );
      return false;
    }
  }

  // <<< TAMBAHKAN METODE BARU INI UNTUK UPLOAD FOTO PROFIL >>>
  Future<bool> uploadProfilePicture({
    required XFile profileImage,
  }) async {
    final url = Uri.parse('$_baseUrl/user/profile-picture'); // Pastikan ini URL yang sesuai
    final headers = await _getHeaders(includeAuth: true); // Ambil token autentikasi

    try {
      var request = http.MultipartRequest('POST', url);

      request.headers.addAll({
        'Accept': 'application/json',
        if (headers.containsKey('Authorization')) 'Authorization': headers['Authorization']!,
      });

      request.files.add(await http.MultipartFile.fromPath(
        'profile_picture', // <<< INI HARUS SAMA DENGAN NAMA FIELD DI BACKEND LARAVEL
        profileImage.path,
        filename: profileImage.name,
      ));

      var response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        print('Upload foto profil berhasil! Respon: $responseBody');
        return true;
      } else {
        print('Gagal upload foto profil. Status: ${response.statusCode}, Respon: $responseBody');
        final errorData = json.decode(responseBody);
        throw Exception(errorData['message'] ?? 'Gagal mengunggah foto profil.');
      }
    } catch (e) {
      print('Error dalam uploadProfilePicture: $e');
      rethrow;
    }
  }
  // <<< AKHIR METODE BARU >>>
}