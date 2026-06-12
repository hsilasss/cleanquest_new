import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/user_mission.dart';
import 'package:intl/intl.dart'; // Import for date and time formatting

class RiwayatMisiScreen extends StatefulWidget {
  final int userId; // Tambahkan userId sebagai parameter

  const RiwayatMisiScreen({super.key, required this.userId});

  @override
  State<RiwayatMisiScreen> createState() => _RiwayatMisiScreenState();
}

class _RiwayatMisiScreenState extends State<RiwayatMisiScreen> {
  late ApiService _apiService;
  List<UserMission> _userMissions = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _fetchRiwayatMisi();
  }

  Future<void> _fetchRiwayatMisi() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      // REVISI: Panggil API dan biarkan backend memfilter status
      final List<UserMission> fetchedMissions = await _apiService.getUserMissionsByStatus(widget.userId, ['pending', 'selesai']);

      setState(() {
        _userMissions = fetchedMissions;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching riwayat misi: $e');
      setState(() {
        _errorMessage = 'Gagal memuat riwayat misi: ${e.toString()}';
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage)),
        );
      }
    }
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'selesai':
        return const Color(0xFF4CAF50);
      case 'pending':
        return const Color(0xFFFFA726);
      default:
        return const Color(0xFF757575); // Abu-abu untuk status lain
    }
  }

  Widget buildCard({
    required String tanggal,
    required String jam,
    required String judul,
    required String status,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.calendar_today_outlined, size: 18),
              const SizedBox(width: 8),
              Text(tanggal),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: getStatusColor(status),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.access_time, size: 18),
              const SizedBox(width: 8),
              Text(jam),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.menu_book_outlined, size: 18),
              const SizedBox(width: 8),
              Text(judul),
            ]),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF557D7A),
      appBar: AppBar(
        title: const Text('Riwayat Misi'),
        centerTitle: true,
        backgroundColor: const Color(0xFF557D7A),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)))
              : _userMissions.isEmpty
                  ? const Center(
                      child: Text(
                        'Tidak ada riwayat misi untuk ditampilkan.',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      child: Column(
                        children: _userMissions.map((userMission) {
                          final mission = userMission.mission;
                          if (mission == null) {
                            return const SizedBox.shrink();
                          }
                          final String tanggal = DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(userMission.createdAt!); // Ensure createdAt is not null
                          final String jam = DateFormat('HH.mm').format(userMission.createdAt!); // Ensure createdAt is not null

                          return buildCard(
                            tanggal: tanggal,
                            jam: jam,
                            judul: mission.title,
                            status: userMission.status,
                          );
                        }).toList(),
                      ),
                    ),
    );
  }
}

