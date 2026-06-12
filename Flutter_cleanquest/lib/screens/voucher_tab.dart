import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/voucher.dart';
import '../models/user.dart'; // Pastikan ini diimpor dengan benar

class VoucherTab extends StatefulWidget {
  final int userId; // userId ini mungkin tidak digunakan langsung untuk fetching di ApiService
  final VoidCallback onPointsUpdated;

  const VoucherTab({super.key, 
    required this.userId,
    required this.onPointsUpdated,
  });

  @override
  State<VoucherTab> createState() => _VoucherTabState();
}

class _VoucherTabState extends State<VoucherTab> {
  final ApiService _apiService = ApiService();
  late Future<List<Voucher>> _vouchersFuture;
  int _currentUserPoints = 0; // Poin pengguna saat ini

  @override
  void initState() {
    super.initState();
    _vouchersFuture = _apiService.fetchVouchers(); // Memuat daftar voucher
    _fetchCurrentUserPoints(); // Memuat poin pengguna saat ini
  }

  // Fungsi untuk mengambil poin pengguna saat ini
  Future<void> _fetchCurrentUserPoints() async {
    try {
      // PENTING: apiService.getUserData sekarang mengembalikan User? (bisa null)
      // Parameter userId di sini mungkin diabaikan oleh ApiService jika fetching by token.
      User? user = await _apiService.getUserData(null); // <--- UBAH DI SINI: tambahkan '?' dan kirim null

      // Jika user yang diambil adalah null, lempar exception atau tangani sesuai kebutuhan
      if (user == null) {
        throw Exception("Data pengguna tidak dapat dimuat untuk VoucherTab.");
      }

      if (mounted) {
        setState(() {
          _currentUserPoints = user.points; // Ini aman karena user sudah dipastikan tidak null
        });
      }
    } catch (e) {
      print('Error fetching current user points in VoucherTab: $e');
      // Opsional: Tampilkan SnackBar untuk memberi tahu pengguna
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat poin: ${e.toString()}')),
        );
      }
      // Set poin ke 0 atau nilai default jika gagal
      if (mounted) {
        setState(() {
          _currentUserPoints = 0;
        });
      }
    }
  }

  Future<void> _exchangeVoucher(BuildContext context, Voucher voucher) async {
    if (_currentUserPoints < voucher.points) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Poin Anda tidak mencukupi untuk voucher ini!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Konfirmasi Penukaran Voucher'),
        content: Text('Anda yakin ingin menukarkan ${voucher.points} poin untuk voucher "${voucher.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              if (!mounted) return;

              try {
                bool success = await _apiService.exchangeVoucher(
                  voucherId: voucher.id,
                );

                if (!mounted) return;

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Voucher berhasil ditukarkan!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  widget.onPointsUpdated(); // Panggil callback untuk update poin di RewardScreen
                  _fetchCurrentUserPoints(); // Refresh poin di VoucherTab
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Gagal menukarkan voucher. Coba lagi!'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                print('Error during voucher exchange: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Terjadi kesalahan: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Tukar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Voucher>>(
      future: _vouchersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Text(
              "Terjadi kesalahan: ${snapshot.error}",
              style: const TextStyle(color: Colors.red),
            ),
          );
        } else if (snapshot.hasData) {
          final vouchers = snapshot.data!;
          if (vouchers.isEmpty) {
            return const Center(
              child: Text("Tidak ada voucher yang tersedia"),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Voucher untuk Anda',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: vouchers.length,
                  itemBuilder: (context, index) {
                    final voucher = vouchers[index];
                    return _buildVoucherItem(context, voucher);
                  },
                ),
              ],
            ),
          );
        } else {
          return const Center(child: Text("Tidak ada data voucher"));
        }
      },
    );
  }

  Widget _buildVoucherItem(BuildContext context, Voucher voucher) {
    return GestureDetector(
      onTap: () => _exchangeVoucher(context, voucher),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.2),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              child: Image.network(
                voucher.imagePath,
                width: double.infinity,
                height: 100,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: double.infinity,
                    height: 100,
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image, size: 40),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    voucher.title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text('${voucher.points} Poin'),
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
}