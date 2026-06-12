import 'package:flutter/material.dart';
import 'package:cleanquest/screens/register.dart';
import 'home_page.dart';
import 'package:cleanquest/services/api_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final TextEditingController identifyCon = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoggingIn = false; // Flag untuk mencegah panggilan login ganda

  @override
  void dispose() {
    identifyCon.dispose();
    passwordController.dispose();
    super.dispose();
  }

  double scale = 1.0;
  double opacity = 1.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Title
              Container(
                padding: const EdgeInsets.only(bottom: 60, top: 100),
                child: const Text(
                  'Clean Quest',
                  style: TextStyle(
                    fontSize: 45,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 80),

              // Email Field
              _buildTextField(label: "Email", controller: identifyCon),

              const SizedBox(height: 10),

              // Password Field
              _buildTextField(
                label: "Password",
                isPassword: true,
                controller: passwordController,
              ),

              const SizedBox(height: 30),

              // Login Button
              _buildLoginButton(),

              const SizedBox(height: 250),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Belum memiliki akun? ",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegisterPage(),
                        ),
                      );
                    },
                    child: const Text(
                      "Daftar",
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Method for TextField
  Widget _buildTextField({
    required String label,
    bool isPassword = false,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.only(left: 15, bottom: 5),
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontFamily: 'Poppins'),
          ),
        ),
        Container(
          height: 42,
          width: 350,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: TextField(
            controller: controller,
            obscureText: isPassword,
            style: const TextStyle(
              fontSize: 13,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
            ),
            decoration: const InputDecoration(
              filled: true,
              fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(15)),
                borderSide: BorderSide(color: Colors.transparent),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(15)),
                borderSide: BorderSide(color: Colors.transparent),
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            ),
          ),
        ),
      ],
    );
  }

  // Login button with animation
  Widget _buildLoginButton() {
    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          scale = 0.9;
          opacity = 0.7;
        });
      },
      onTapUp: (_) async {
        setState(() {
          scale = 1.0;
          opacity = 1.0;
        });
        FocusScope.of(context).unfocus();
        await Future.delayed(const Duration(milliseconds: 100));
        _login(); // Panggil logika login
      },
      child: AnimatedOpacity(
        opacity: opacity,
        duration: const Duration(milliseconds: 100),
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 100),
          child: Image.asset('assets/images/button.png'),
        ),
      ),
    );
  }

  void _login() async {
    // --- DEBUG: Cek apakah _login terpanggil lagi ---
    print('DEBUG_FLOW: _login() called. _isLoggingIn: $_isLoggingIn');

    // Mencegah panggilan login ganda jika sudah ada proses yang berjalan
    if (_isLoggingIn) {
      print('DEBUG_FLOW: Already logging in, returning early.');
      return;
    }

    String rawIdentify = identifyCon.text;
    String rawPassword = passwordController.text;

    // --- DEBUG: Tampilkan nilai mentah dari controller ---
    print('DEBUG_INPUT_RAW: identifyCon.text = "$rawIdentify" (length: ${rawIdentify.length})');
    print('DEBUG_INPUT_RAW: passwordController.text = "$rawPassword" (length: ${rawPassword.length})');

    String identify = rawIdentify.trim(); // Trim whitespace
    String password = rawPassword.trim(); // Trim whitespace

    // --- DEBUG: Tampilkan nilai setelah trim dan hasil isEmpty ---
    print('DEBUG_INPUT_TRIMMED: identify (after trim) = "$identify" (isEmpty: ${identify.isEmpty})');
    print('DEBUG_INPUT_TRIMMED: password (after trim) = "${'*' * password.length}" (isEmpty: ${password.isEmpty})'); // Jangan tampilkan password
    print('DEBUG_INPUT_CHECK: is identify.isEmpty || password.isEmpty? ${identify.isEmpty || password.isEmpty}');

    // Validasi input lokal
    if (identify.isEmpty || password.isEmpty) {
      print('DEBUG_VALIDATION_RESULT: Local validation FAILED (input empty). Showing SnackBar and returning.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email dan password harus diisi')),
      );
      return; // Hentikan eksekusi jika validasi gagal
    }

    if (password.length < 8) {
      print('DEBUG_VALIDATION_RESULT: Local validation FAILED (password too short). Showing SnackBar and returning.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password harus terdiri dari minimal 8 karakter'),
        ),
      );
      return; // Hentikan eksekusi jika validasi gagal
    }

    print('DEBUG_VALIDATION_RESULT: Local validation PASSED. Proceeding to API call.');

    // Atur flag untuk menandakan proses login telah dimulai
    setState(() {
      _isLoggingIn = true;
    });

    try {
      final response = await _apiService.login(
        identity: identify, // Pastikan ini adalah nilai yang sudah di-trim
        password: password, // Pastikan ini adalah nilai yang sudah di-trim
      );

      // --- DEBUG PRINTS DARI RESPON API (dari ApiService) ---
      print('DEBUG_API_RESPONSE_FROM_LOGIN_PAGE: success: ${response['success']}');
      print('DEBUG_API_RESPONSE_FROM_LOGIN_PAGE: message: ${response['message']}');
      // --- END DEBUG PRINTS ---

      if (response['success']) {
        print('Login berhasil: ${response['message']}');
        // Pastikan kunci 'user_id' ada di respon sukses API Anda
        int userId = response['user_id'];

        // Navigasi ke Home screen dan ganti route saat ini
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen(userId: userId)),
        );
      } else {
        // Penanganan error detail untuk login yang gagal
        String errorMessage = 'Login gagal';
        if (response.containsKey('message')) {
          errorMessage = response['message'].toString();
        } else if (response.containsKey('data') &&
            response['data'] is Map<String, dynamic>) {
          final backendResponse = response['data'] as Map<String, dynamic>;
          if (backendResponse.containsKey('message')) {
            errorMessage = backendResponse['message'].toString();
          }
          if (backendResponse.containsKey('errors')) {
            final errors = backendResponse['errors'] as Map<String, dynamic>;
            errors.forEach((field, messages) {
              errorMessage +=
                  '\n${field.toUpperCase()}: ${(messages as List).join(', ')}';
            });
          }
        }

        print('Login gagal: $errorMessage');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      print('Error selama login: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Terjadi kesalahan. Coba lagi nanti')),
      );
    } finally {
      // Selalu reset flag, terlepas dari sukses atau gagal
      if (mounted) { // Penting: Periksa apakah widget masih ada di tree sebelum memanggil setState
        setState(() {
          _isLoggingIn = false;
        });
      }
    }
  }
}