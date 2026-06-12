import 'dart:io'; // Import ini untuk File class
import 'package:cleanquest/screens/profile.dart';
import 'package:cleanquest/screens/reward.dart';
import 'package:flutter/material.dart';
import '../models/mission.dart';
import '../models/user.dart';
import '../models/user_mission.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart'; // Import ImagePicker

class HomeScreen extends StatefulWidget {
  final int userId;

  const HomeScreen({super.key, required this.userId});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  User? user;
  late ApiService apiService;
  List<UserMission> activeUserMissions = [];
  int completedMissionsCount = 0;
  int totalMissionsCount = 0;
  bool isLoading = true;

  // Variabel untuk menyimpan file yang dipilih dari kamera
  XFile? _pickedProofFile;
  final ImagePicker _picker = ImagePicker();

  // Variabel untuk menyimpan misi yang sedang di-*upload* saat dialog dibuka
  UserMission? _currentMissionForUpload;

  @override
  void initState() {
    super.initState();
    apiService = ApiService();
    _fetchData(); // Mengganti fetchData menjadi _fetchData (privat)
    _getTokenAndPrint();
  }

  Future<void> _getTokenAndPrint() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');
    if (token != null) {
      print('Stored Auth Token: $token');
    } else {
      print('No Auth Token found.');
    }
  }

  Future<void> _fetchData() async { // Mengganti fetchData menjadi _fetchData (privat)
    if (!mounted) return; // Pastikan widget masih ada sebelum setState

    setState(() {
      isLoading = true;
    });
    try {
      final fetchedUser = await apiService.getUserData(widget.userId);
      final fetchedActiveUserMissions = await apiService.getMissions();

      final completed = fetchedActiveUserMissions
          .where((um) => um.status == 'selesai')
          .length;

      if (!mounted) return; // Pastikan widget masih ada setelah await

      setState(() {
        user = fetchedUser;
        activeUserMissions = fetchedActiveUserMissions;
        totalMissionsCount = activeUserMissions.length;
        completedMissionsCount = completed;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching data: $e');
      if (!mounted) return; // Pastikan widget masih ada setelah await

      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal memuat data: $e')));
    }
  }

  // Fungsi untuk mengambil gambar atau video dari kamera
  Future<void> _captureProofFile(BuildContext dialogContext) async {
    // Tampilkan bottom sheet untuk opsi ambil gambar atau rekam video
    await showModalBottomSheet(
      context: dialogContext,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Ambil Gambar'),
                onTap: () async {
                  Navigator.pop(bc); // Tutup bottom sheet
                  final XFile? image = await _picker.pickImage(source: ImageSource.camera);
                  if (image != null) {
                    setState(() {
                      _pickedProofFile = image;
                    });
                    // Panggil ulang dialog untuk menampilkan preview file yang baru dipilih
                    if (_currentMissionForUpload != null) {
                      _showSubmitDialog(context, _currentMissionForUpload!);
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam),
                title: const Text('Rekam Video'),
                onTap: () async {
                  Navigator.pop(bc); // Tutup bottom sheet
                  final XFile? video = await _picker.pickVideo(source: ImageSource.camera);
                  if (video != null) {
                    setState(() {
                      _pickedProofFile = video;
                    });
                    // Panggil ulang dialog untuk menampilkan preview file yang baru dipilih
                    if (_currentMissionForUpload != null) {
                      _showSubmitDialog(context, _currentMissionForUpload!);
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Fungsi untuk menampilkan dialog pengiriman bukti misi
  void _showSubmitDialog(BuildContext context, UserMission userMission) {
    // Simpan userMission ke variabel state sementara agar tetap bisa diakses
    _currentMissionForUpload = userMission;

    // Untuk memastikan dialog direfresh dengan state terbaru dari _pickedProofFile,
    // kita memanggil showDialog. Jika _pickedProofFile sudah ada, preview akan muncul.
    // Jika belum, tombol "Ambil Bukti" akan tampil.
    showDialog(
      context: context,
      builder: (dialogContext) { // Gunakan dialogContext untuk dialog
        return AlertDialog(
          title: const Text('Kirim Bukti Misi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_pickedProofFile == null) // Jika belum ada file yang dipilih
                const Text(
                  'Silakan ambil gambar atau rekam video sebagai bukti pengerjaan misi:',
                  textAlign: TextAlign.center,
                ),
              if (_pickedProofFile != null) // Jika sudah ada file yang dipilih, tampilkan preview
                Column(
                  children: [
                    _pickedProofFile!.path.endsWith('.mp4') || _pickedProofFile!.path.endsWith('.mov')
                        ? const Icon(Icons.video_file, size: 80, color: Colors.blue) // Placeholder untuk video
                        : Image.file(
                            File(_pickedProofFile!.path),
                            height: 150,
                            fit: BoxFit.contain,
                          ),
                    const SizedBox(height: 10),
                    Text(
                      'File Terpilih: ${_pickedProofFile!.name}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ElevatedButton.icon(
                onPressed: () {
                  // Tutup dialog saat ini untuk menghindari error "setState() or markNeedsBuild() called during build"
                  // karena _captureProofFile akan memicu setState dan mungkin membuka dialog baru.
                  Navigator.pop(dialogContext);
                  // Panggil fungsi untuk mengambil gambar/video dari kamera
                  _captureProofFile(context); // Menggunakan context dari HomeScreenState
                },
                icon: Icon(_pickedProofFile == null ? Icons.camera_alt : Icons.redo), // Ikon berubah
                label: Text(_pickedProofFile == null ? 'Ambil Bukti' : 'Ambil Ulang Bukti'),
              ),
              const SizedBox(height: 10),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext); // Tutup dialog
                setState(() {
                  _pickedProofFile = null; // Hapus file yang dipilih saat batal
                  _currentMissionForUpload = null; // Reset misi
                });
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext); // Tutup dialog sebelum proses upload

                if (_pickedProofFile == null) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Anda belum memilih file bukti!'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                  return;
                }

                try {
                  // Panggil method API Service untuk upload file
                  bool success = await apiService.uploadMissionProof(
                    userMissionId: userMission.id,
                    proofFile: _pickedProofFile!, // Kirim objek XFile
                  );

                  if (!mounted) return; // Pastikan widget masih ada setelah await

                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Bukti misi berhasil diunggah!'),
                        duration: Duration(seconds: 3),
                        backgroundColor: Color.fromRGBO(76, 175, 80, 1),
                      ),
                    );
                    _fetchData(); // Refresh data setelah submit
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Gagal mengunggah bukti misi. Coba lagi!'),
                        duration: Duration(seconds: 3),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  print('Error uploading proof: $e');
                  if (mounted) { // Pastikan widget masih ada
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Terjadi kesalahan saat mengunggah: ${e.toString()}'),
                        duration: const Duration(seconds: 3),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } finally {
                  // Reset file yang dipilih setelah mencoba upload (berhasil/gagal)
                  if (mounted) { // Pastikan widget masih ada
                    setState(() {
                      _pickedProofFile = null;
                      _currentMissionForUpload = null; // Reset misi
                    });
                  }
                }
              },
              child: const Text('Upload'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Tampilkan CircularProgressIndicator di tengah layar saat loading
    if (isLoading || user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Content
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 66),
                    Text(
                      'Halo ${user!.username}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildUserStats(),
                    const SizedBox(height: 32),
                    const Text(
                      'Misi Hari Ini',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildMissionList(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildUserStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildProgressIndicator(),
        const SizedBox(width: 16),
        _buildPointsIndicator(),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.teal.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.assignment, color: Colors.teal),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$completedMissionsCount/$totalMissionsCount Misi',
                style: const TextStyle(
                  color: Colors.teal,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Telah Dikerjakan',
                style: TextStyle(color: Colors.teal, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPointsIndicator() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.star, color: Colors.amber),
          const SizedBox(width: 8),
          Text(
            '${user!.points} Poin',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionList() {
    if (activeUserMissions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Tidak ada misi aktif hari ini.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: activeUserMissions.length,
      itemBuilder: (context, index) {
        final userMission = activeUserMissions[index];
        final mission = userMission.mission;

        if (mission == null) {
          return const SizedBox.shrink();
        }

        return _buildMissionCard(mission, userMission);
      },
    );
  }

  Widget _buildMissionCard(Mission mission, UserMission userMission) {
    Color badgeColor;
    String badgeText;
    IconData badgeIcon;

    switch (userMission.status) {
      case 'selesai':
        badgeColor = Colors.green;
        badgeText = 'Selesai';
        badgeIcon = Icons.check;
        break;
      case 'pending':
        badgeColor = Colors.orange;
        badgeText = 'Pending';
        badgeIcon = Icons.hourglass_empty;
        break;
      case 'belum dikerjakan':
      default:
        badgeColor = Colors.grey;
        badgeText = 'Belum Dikerjakan';
        badgeIcon = Icons.circle_outlined;
        break;
    }

    return GestureDetector(
      onTap: () {
        if (userMission.status == 'belum dikerjakan') {
          setState(() {
            _pickedProofFile = null; // Reset file saat membuka dialog baru
          });
          _showSubmitDialog(context, userMission);
        } else if (userMission.status == 'pending') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Misi ini sedang dalam peninjauan (Pending).'),
              backgroundColor: Colors.blueAccent,
            ),
          );
        } else if (userMission.status == 'selesai') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Misi ini sudah selesai!'),
              backgroundColor: Colors.blueAccent,
            ),
          );
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: AspectRatio(
                    aspectRatio: 2,
                    child: Image.network(
                      mission.imageUrl ?? 'https://i.imgur.com/IOHiB78.jpeg',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(badgeIcon, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          badgeText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.teal,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      mission.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${mission.points}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 0.0,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30.0),
          topRight: Radius.circular(30.0),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.white,
          currentIndex: 0,
          selectedItemColor: Theme.of(context).primaryColor,
          unselectedItemColor: Colors.grey[600],
          onTap: (index) {
            if (index == 0) {
              // Stay on Home screen
            } else if (index == 1) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => RewardScreen(
                    userId: user!.id,
                  ),
                ),
              );
            } else if (index == 2) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileScreen(
                    userId: user!.id,
                  ),
                ),
              );
            }
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
              icon: Icon(Icons.card_giftcard),
              label: 'Reward',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}