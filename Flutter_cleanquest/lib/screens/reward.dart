import 'package:flutter/material.dart';
import 'home_page.dart'; // Pastikan HomeScreen diimport dengan benar
import 'profile.dart'; // Pastikan ProfileScreen diimport dengan benar
import 'cash_tab.dart'; // Pastikan CashTab diimport dengan benar
import 'voucher_tab.dart'; // Pastikan VoucherTab diimport dengan benar
import '../services/api_service.dart'; // Pastikan ApiService diimport dengan benar
import '../models/user.dart'; // Pastikan User model diimport dengan benar

class RewardScreen extends StatefulWidget {
  final int userId;

  const RewardScreen({
    super.key,
    required this.userId,
  }); // Tambah const constructor

  @override
  _RewardScreenState createState() => _RewardScreenState();
}

class _RewardScreenState extends State<RewardScreen> {
  final TextEditingController _customAmountController = TextEditingController();
  int _currentIndex = 1; // Set the default selected index to 1 (Reward tab)
  late ApiService _apiService;
  int _userPoints = 0; // State untuk menyimpan poin pengguna
  bool isLoading =
      true; // Set true secara default agar indikator loading tampil saat awal

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _fetchUserPoints(); // Panggil fungsi untuk mengambil poin saat inisialisasi
  }

  // Fungsi untuk mengambil data poin pengguna
  Future<void> _fetchUserPoints() async {
    setState(() {
      isLoading = true; // Mulai loading
    });
    try {
      User? user = await _apiService.getUserData(widget.userId); // Mengembalikan User?

      // PENTING: Lakukan pengecekan NULL di sini
      if (user == null) {
        throw Exception("Data pengguna tidak dapat dimuat di Reward Screen.");
      }

      setState(() {
        _userPoints = user.points; // Ini sudah aman karena sudah cek null
      });
    } catch (e) {
      print('Error fetching user points: $e');
      // Tampilkan SnackBar jika terjadi error
      if (mounted) {
        // Pastikan widget masih ada sebelum menampilkan SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat poin pengguna: $e')),
        );
      }
    } finally {
      // Pastikan isLoading diatur ke false setelah proses selesai (sukses atau gagal)
      if (mounted) {
        // Pastikan widget masih ada sebelum memanggil setState
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _customAmountController.dispose(); // Pastikan controller di-dispose
    super.dispose();
  }

  Widget _buildBottomNavBar() {
  return Padding(
    // Tambahkan padding di bagian bawah untuk mendorong navbar ke atas
    padding: const EdgeInsets.only(bottom: 0.0), // Sesuaikan nilai 20.0 ini jika perlu
    child: ClipRRect(
      // Ini adalah bagian untuk membuat sudut melengkung di bagian atas
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(30.0), // Radius lengkungan sudut kiri atas
        topRight: Radius.circular(30.0), // Radius lengkungan sudut kanan atas
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.white, // Warna latar belakang navbar
        currentIndex: _currentIndex, // Menggunakan state _currentIndex untuk item terpilih
        selectedItemColor: Theme.of(context).primaryColor, // Warna ikon/teks saat terpilih (ambil dari tema)
        unselectedItemColor: Colors.grey[600], // Warna ikon/teks saat tidak terpilih
        onTap: (index) {
          // Perbarui _currentIndex saat item ditekan
          setState(() {
            _currentIndex = index;
          });

          // Logika navigasi berdasarkan item yang ditekan
          if (index == 0) {
             Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomeScreen(userId: widget.userId),
              ),
            );
          } else if (index == 1) {
            // Navigasi ke RewardScreen
          } else if (index == 2) {
            // Navigasi ke ProfileScreen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileScreen(userId: widget.userId),
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

  @override
 Widget build(BuildContext context) {
  return DefaultTabController(
    length: 2,
    child: Scaffold(
      extendBody: true,
      body: isLoading
          ? Container(
              // Tambahkan warna solid ke container ini untuk menutupi seluruh layar
              color: Colors.white, // Contoh: warna putih solid saat loading
              child: const Center(child: CircularProgressIndicator()),
            )
          : Stack(
              children: [
                // Layer Gambar Latar Belakang (ini hanya akan aktif saat isLoading false)
                Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage("assets/images/background.png"),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Tampilan Poin di Atas
                Positioned(
                  top: 40,
                  left: 20,
                  right: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(15),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TOTAL POIN',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              '$_userPoints Poin',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // TabBar dan TabBarView
                Positioned(
                  top: 120,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Column(
                    children: [
                      TabBar(
                        indicatorColor: const Color.fromRGBO(
                          85,
                          132,
                          122,
                          0.97,
                        ),
                        labelColor: Colors.black,
                        unselectedLabelColor: Colors.grey,
                        tabs: const [
                          Tab(text: "Tukar Uang"),
                          Tab(text: "Tukar Voucher"),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            CashTab(
                              customAmountController: _customAmountController,
                              userId: widget.userId,
                              onPointsUpdated: _fetchUserPoints,
                            ),
                            VoucherTab(
                              userId: widget.userId,
                              onPointsUpdated: _fetchUserPoints,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: _buildBottomNavBar(),
    ),
  );
}
}
