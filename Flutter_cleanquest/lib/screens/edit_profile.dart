import 'dart:io'; // Import ini untuk menggunakan File class
import 'package:flutter/material.dart';
import 'package:cleanquest/services/api_service.dart'; // Import ApiService
import 'package:cleanquest/models/user.dart'; // Import User model
import 'package:intl/intl.dart'; // For date formatting
import 'package:image_picker/image_picker.dart'; // <<< PENTING: Pastikan ini sudah diimpor

class EditProfileScreen extends StatefulWidget {
  final int userId; // Menerima userId dari ProfileScreen

  const EditProfileScreen({super.key, required this.userId});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  late ApiService _apiService;
  User? _currentUser;
  bool _isLoading = true;
  DateTime? _selectedDate;

  XFile? _pickedProfileImage; // <<< Variabel untuk menyimpan gambar profil yang dipilih
  final ImagePicker _picker = ImagePicker(); // <<< Instance ImagePicker

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _fetchUserProfile(); // Panggil ini untuk memuat data user saat inisialisasi
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserProfile() async {
    if (!mounted) return; // Penting untuk memeriksa apakah widget masih aktif

    setState(() {
      _isLoading = true;
    });
    try {
      final user = await _apiService.getUserData(widget.userId);
      if (mounted) {
        setState(() {
          _currentUser = user!;
          _usernameController.text = user.username;
          _emailController.text = user.email;
          _phoneController.text = user.phoneNumber;
          _birthDateController.text = DateFormat(
            'yyyy-MM-dd',
          ).format(user.birthDate);
          _selectedDate = user.birthDate;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching user profile: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _currentUser = null; // Set null jika gagal
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat profil pengguna: ${e.toString()}'),
          ),
        );
      }
    }
  }

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
        _birthDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  // <<< FUNGSI UNTUK MEMILIH GAMBAR PROFIL (DARI KAMERA ATAU GALERI) >>>
  Future<void> _pickProfileImage() async {
    await showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Pilih dari Galeri'),
                onTap: () async {
                  Navigator.pop(bc); // Tutup bottom sheet
                  final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    setState(() {
                      _pickedProfileImage = image;
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Ambil dengan Kamera'),
                onTap: () async {
                  Navigator.pop(bc); // Tutup bottom sheet
                  final XFile? image = await _picker.pickImage(source: ImageSource.camera);
                  if (image != null) {
                    setState(() {
                      _pickedProfileImage = image;
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveProfile() async {
    if (!mounted) return;

    // Validasi dasar form teks
    if (_usernameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _birthDateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Semua field wajib diisi!')));
      return;
    }

    if (_passwordController.text.isNotEmpty &&
        _passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Konfirmasi password tidak cocok!')));
      return;
    }

    setState(() {
      _isLoading = true; // Tampilkan loading
    });

    try {
      // --- 1. Update Data Profil Teks ---
      final Map<String, dynamic> dataToUpdate = {
        'username': _usernameController.text,
        'email': _emailController.text,
        'phone_number': _phoneController.text,
        'birth_date': _birthDateController.text,
      };

      if (_passwordController.text.isNotEmpty) {
        dataToUpdate['password'] = _passwordController.text;
        dataToUpdate['password_confirmation'] = _confirmPasswordController.text;
      }

      final response = await _apiService.updateUserProfile(dataToUpdate);

      if (!mounted) return; // Cek mounted setelah operasi async

      // --- 2. Upload Foto Profil (Jika ada perubahan) ---
      bool profilePicUploadSuccess = true; // Asumsikan sukses jika tidak ada gambar baru
      if (_pickedProfileImage != null) {
        try {
          profilePicUploadSuccess = await _apiService.uploadProfilePicture(
            profileImage: _pickedProfileImage!, // Kirim file gambar yang dipilih
          );
        } catch (e) {
          profilePicUploadSuccess = false; // Setel gagal jika ada error upload gambar
          print('Error uploading profile picture: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Gagal mengunggah foto profil: ${e.toString()}')),
            );
          }
        }
      }

      // --- 3. Tangani Respons Akhir (Gabungan Teks dan Foto) ---
      if (response['success'] && profilePicUploadSuccess) {
        // Jika kedua operasi (update teks dan upload foto) berhasil
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profil berhasil diperbarui!')));
        // Penting: Panggil _fetchUserProfile() untuk memuat ulang data user dan memperbarui UI
        await _fetchUserProfile();
        Navigator.pop(context, true); // Kembali ke layar sebelumnya dengan indikasi sukses
      } else {
        // Jika update teks gagal, tampilkan pesan dari backend
        String errorMessage = 'Gagal memperbarui profil.';
        if (response.containsKey('data') && response['data'] is Map<String, dynamic>) {
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    } catch (e) {
      // Tangani error umum (misalnya masalah koneksi)
      print('Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: ${e.toString()}')),
        );
      }
    } finally {
      // Pastikan loading dimatikan dan gambar yang dipilih direset
      if (mounted) {
        setState(() {
          _isLoading = false;
          _pickedProfileImage = null; // Reset gambar yang dipilih setelah selesai
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color.fromARGB(235, 255, 255, 255),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color.fromARGB(235, 255, 255, 255),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: const Text('Save', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Gambar background
          SizedBox(
            height: 250,
            width: double.infinity,
            child: Image.asset(
              'assets/images/background.png',
              fit: BoxFit.cover,
            ),
          ),

          // Avatar profile
          Positioned(
            top: 120,
            left: 0,
            right: 0,
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Gambar Profil (menggunakan _pickedProfileImage atau _currentUser.profilePicture)
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0xFFE0DDFB),
                    // Tentukan sumber gambar:
                    // 1. Jika ada gambar baru yang dipilih (_pickedProfileImage)
                    // 2. Jika user punya profile_picture dari server
                    // 3. Fallback ke placeholder default
                    backgroundImage: _pickedProfileImage != null
                        ? FileImage(File(_pickedProfileImage!.path)) as ImageProvider // Gambar dari file lokal
                        : (_currentUser?.profilePicture != null && _currentUser!.profilePicture!.isNotEmpty
                            ? NetworkImage(_currentUser!.profilePicture!) as ImageProvider // Gambar dari network
                            : null), // Jika tidak ada, fallback ke null
                    child: _pickedProfileImage == null && (_currentUser?.profilePicture == null || _currentUser!.profilePicture!.isEmpty)
                        ? const Icon(Icons.person, size: 50, color: Colors.white) // Placeholder default jika tidak ada gambar
                        : null, // Jika ada gambar, tidak perlu placeholder
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickProfileImage, // <<< Panggil fungsi pemilihan gambar
                      child: CircleAvatar(
                        radius: 15,
                        backgroundColor: const Color.fromRGBO(
                          85,
                          132,
                          122,
                          0.97,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 15,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Form
          // Gunakan SingleChildScrollView di dalam Container agar form bisa discroll jika keyboard muncul
          Container(
            margin: const EdgeInsets.only(top: 250), // Atur margin agar tidak menumpuk dengan avatar
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            decoration: const BoxDecoration(
              color: Color.fromRGBO(85, 132, 122, 0.97),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: ListView( // Gunakan ListView agar konten bisa discroll
              children: [
                _buildTextField(label: 'Nama', controller: _usernameController),
                const SizedBox(height: 10),
                _buildTextField(label: 'Email', controller: _emailController),
                const SizedBox(height: 10),
                _buildTextField(
                  label: 'No. Handphone',
                  controller: _phoneController,
                ),
                const SizedBox(height: 10),
                _buildDateField(
                  context,
                  label: 'Tanggal Lahir',
                  controller: _birthDateController,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  label: 'Password Baru (opsional)',
                  controller: _passwordController,
                  isPassword: true,
                ),
                const SizedBox(height: 10),
                _buildTextField(
                  label: 'Konfirmasi Password Baru',
                  controller: _confirmPasswordController,
                  isPassword: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    TextEditingController? controller,
    String? hintText,
    bool enabled = true,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white)),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          enabled: enabled,
          obscureText: isPassword,
          style: const TextStyle(color: Colors.black),
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white)),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          readOnly: true,
          onTap: () => _selectDate(context),
          style: const TextStyle(color: Colors.black),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            suffixIcon: const Icon(Icons.calendar_today),
          ),
        ),
      ],
    );
  }
}