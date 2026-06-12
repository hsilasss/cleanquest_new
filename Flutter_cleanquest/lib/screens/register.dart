import 'package:flutter/material.dart';
import 'package:cleanquest/screens/login.dart';
import 'package:cleanquest/services/api_service.dart';
import 'package:intl/intl.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  RegisterPageState createState() => RegisterPageState();
}

class RegisterPageState extends State<RegisterPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController birthDateController = TextEditingController();
  final ApiService _apiService = ApiService();

  DateTime? _selectedDate;

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    phoneNumberController.dispose();
    birthDateController.dispose();
    super.dispose();
  }

  double scale = 1.0;
  double opacity = 1.0;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        birthDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/suBackground.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.only(top: 65, right: 330),
                  child: IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: Image.asset('assets/images/backArr.png'),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 50),
                  child: const Text(
                    'Selamat Datang!',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Mari bersama kita menjaga lingkungan',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    color: Color.fromRGBO(85, 132, 122, 100),
                  ),
                ),
                const SizedBox(height: 60),
                _buildTextField(hintText: "Masukan username", controller: usernameController),
                const SizedBox(height: 30),
                _buildTextField(hintText: "Masukan email", controller: emailController),
                const SizedBox(height: 30),
                _buildTextField(
                    hintText: "Masukan password",
                    isPassword: true,
                    controller: passwordController),
                const SizedBox(height: 30),
                _buildTextField(
                    hintText: "Konfirmasi password",
                    isPassword: true,
                    controller: confirmPasswordController),
                const SizedBox(height: 30),
                _buildTextField(hintText: "Nomor Telepon", controller: phoneNumberController),
                const SizedBox(height: 30),
                _buildDateField(context, hintText: "Tanggal Lahir (YYYY-MM-DD)", controller: birthDateController),
                const SizedBox(height: 50),
                _buildRegisterButton(),
                const SizedBox(height: 50),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Sudah memiliki akun? ",
                      style: TextStyle(
                        color: Color.fromARGB(255, 0, 0, 0),
                        fontSize: 14,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginPage()),
                        );
                      },
                      child: const Text(
                        "Login",
                        style: TextStyle(
                          color: Color.fromARGB(255, 0, 0, 0),
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      {required String hintText,
      bool isPassword = false,
      required TextEditingController controller}) {
    return Container(
      height: 40,
      width: 335,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: const TextStyle(
          fontSize: 13,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w400,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color.fromARGB(255, 255, 255, 255),
          enabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            borderSide: BorderSide(color: Colors.transparent),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            borderSide: BorderSide(color: Colors.transparent),
          ),
          hintText: hintText,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildDateField(BuildContext context, {
    required String hintText,
    required TextEditingController controller,
  }) {
    return Container(
      height: 40,
      width: 335,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: TextField(
        controller: controller,
        readOnly: true,
        onTap: () => _selectDate(context),
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color.fromARGB(255, 255, 255, 255),
          enabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            borderSide: BorderSide(color: Colors.transparent),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            borderSide: BorderSide(color: Colors.transparent),
          ),
          hintText: hintText,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
      ),
    );
  }


  Widget _buildRegisterButton() {
    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          scale = 0.9;
          opacity = 0.7;
        });
      },
      onTapUp: (_) {
        setState(() {
          scale = 1.0;
          opacity = 1.0;
        });
        _register();
      },
      child: AnimatedOpacity(
        opacity: opacity,
        duration: const Duration(milliseconds: 100),
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 100),
          child: Image.asset(
            'assets/images/buttondft.png',
          ),
        ),
      ),
    );
  }

  void _register() async {
    String username = usernameController.text.trim();
    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    String confirmPassword = confirmPasswordController.text.trim();
    String phoneNumber = phoneNumberController.text.trim();
    String birthDate = birthDateController.text.trim();

    if (username.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty ||
        phoneNumber.isEmpty ||
        birthDate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua field harus diisi')),
      );
      return;
    }

    if (password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Password harus terdiri dari minimal 8 karakter')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Password dan konfirmasi password harus sama')),
      );
      return;
    }

    bool isValidEmail(String email) {
      String pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
      RegExp regex = RegExp(pattern);
      return regex.hasMatch(email);
    }

    if (!isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Format email tidak valid')),
      );
      return;
    }

    try {
      final response = await _apiService.register(
        username: username,
        email: email,
        password: password,
        passwordConfirmation: confirmPassword,
        phoneNumber: phoneNumber,
        birthDate: birthDate,
      );

      if (response['success']) {
        print('Registration successful: ${response['message']}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registrasi berhasil! Silakan login')),
        );
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        });
      } else {
        // REVISI: Penanganan error yang lebih detail
        String errorMessage = 'Gagal registrasi';
        if (response['data'] != null && response['data'] is Map<String, dynamic>) {
          final backendResponse = response['data'] as Map<String, dynamic>;
          if (backendResponse.containsKey('message')) {
            errorMessage = backendResponse['message'].toString();
          }
          if (backendResponse.containsKey('errors')) {
            final errors = backendResponse['errors'] as Map<String, dynamic>;
            errors.forEach((field, messages) {
              errorMessage += '\n${field.toUpperCase()}: ${(messages as List).join(', ')}';
            });
          }
        }

        print('Registration failed: $errorMessage');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      print("Error during registration: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Terjadi kesalahan. Coba lagi nanti')),
      );
    }
  }
}

