import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Penting untuk TextInputFormatter
import 'package:intl/intl.dart'; // Penting untuk NumberFormat
import 'package:cleanquest/services/api_service.dart';
import 'package:cleanquest/models/user.dart';

const Color _kSelectedBackgroundColor = Color.fromRGBO(85, 132, 122, 0.969);
const Color _kSelectedBorderColor = Color.fromRGBO(85, 132, 122, 1);
const Color _kSelectedShadowColor = Color.fromRGBO(85, 132, 122, 0.6);

// Custom TextInputFormatter untuk pemformatan mata uang Rupiah
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // Jika input baru benar-benar kosong (misal: user menghapus semua karakter)
    if (newValue.text.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Bersihkan input baru dari semua karakter non-digit (termasuk 'Rp ' dan titik)
    final String cleanValue = newValue.text.replaceAll(RegExp(r'\D'), '');

    // Coba parse nilai numerik yang sudah dibersihkan
    int? numericValue = int.tryParse(cleanValue);

    // Tangani kasus di mana parsing gagal (misal: hanya ada 'Rp ' setelah menghapus angka),
    // atau jika nilai numeriknya adalah 0.
    if (numericValue == null || numericValue == 0) {
      // Jika nilai yang dibersihkan kosong, berarti tidak ada angka yang tersisa.
      // Kembalikan TextField ke keadaan kosong.
      if (cleanValue.isEmpty) {
        return const TextEditingValue(
          text: '',
          selection: TextSelection.collapsed(offset: 0),
        );
      }
      // Jika nilai numerik adalah 0 (misal: user mengetik '0'), tampilkan '0' saja.
      return const TextEditingValue(
        text: '0',
        selection: TextSelection.collapsed(offset: 1),
      );
    }

    // Format nilai numerik ke format mata uang Rupiah
    final NumberFormat formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final String formattedText = formatter.format(numericValue);

    // Jika teks yang diformat sama dengan teks lama, hindari update yang tidak perlu
    // untuk mencegah lompatan kursor.
    if (formattedText == oldValue.text) {
      return oldValue;
    }

    // Atur posisi kursor selalu di akhir teks yang diformat
    final int newOffset = formattedText.length;

    // Kembalikan TextEditingValue baru dengan teks yang diformat dan seleksi yang benar
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: newOffset),
    );
  }
}

class CashTab extends StatefulWidget {
  final TextEditingController customAmountController;
  final int userId;
  final VoidCallback onPointsUpdated;

  const CashTab({super.key, 
    required this.customAmountController,
    required this.userId,
    required this.onPointsUpdated,
  });

  @override
  _CashTabState createState() => _CashTabState();
}

class _CashTabState extends State<CashTab> {
  String? selectedPaymentMethod;
  int? _selectedNominal;
  int _requiredPoints = 0;
  late ApiService _apiService;
  int _currentUserPoints = 0;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _fetchCurrentUserPoints();
  }

  Future<void> _fetchCurrentUserPoints() async {
    try {
      User? user = await _apiService.getUserData(widget.userId); // Mengembalikan User?

      // PENTING: Lakukan pengecekan NULL di sini
      if (user == null) {
        throw Exception("Data pengguna tidak dapat dimuat di CashTab.");
      }

      setState(() {
        _currentUserPoints = user.points; // Ini aman karena sudah cek null
      });
    } catch (e) {
      print('Error fetching current user points: $e');
      // Tambahkan SnackBar jika mau
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0x00ededed),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPaymentOption(context, 'assets/images/gopay.png', 'GoPay'),
            const SizedBox(height: 20),
            const Text(
              'Nominal',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildNominalOptions(),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Divider(
              thickness: 1,
              color: Color.fromARGB(255, 206, 206, 206),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 4,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Penukaran',
                        style: TextStyle(fontSize: 16),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber),
                          const SizedBox(width: 8),
                          Text(
                            '$_requiredPoints',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          if (_validateInputs(context)) {
                            showRewardDialog(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromRGBO(
                            85,
                            132,
                            122,
                            0.969,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 24,
                          ),
                        ),
                        child: const Text(
                          'Tukar',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  bool _validateInputs(BuildContext context) {
    if (selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tolong pilih metode pembayaran!')),
      );
      return false;
    }

    int? nominalAmount;
    if (_selectedNominal != null) {
      nominalAmount = _selectedNominal;
    } else {
      String cleanValue = widget.customAmountController.text.replaceAll(RegExp(r'\D'), '');
      nominalAmount = int.tryParse(cleanValue);
    }
    
    if (nominalAmount == null || nominalAmount < 10000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nominal minimal Rp 10.000 untuk penukaran!'),
        ),
      );
      return false;
    }

    int calculatedRequiredPoints = nominalAmount ~/ 10;

    if (_currentUserPoints < calculatedRequiredPoints) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Poin Anda tidak mencukupi!')),
      );
      return false;
    }
    
    setState(() {
      _requiredPoints = calculatedRequiredPoints;
    });

    return true;
  }

  void showRewardDialog(BuildContext context) {
    final TextEditingController phoneController = TextEditingController();
    String userEmail = '';
    _apiService
        .getUserData(widget.userId) // Mengembalikan Future<User?>
        .then((user) {
          // PENTING: Cek 'user' di sini karena bisa null
          if (user != null) { // <--- TAMBAHKAN INI
            userEmail = user.email;
            phoneController.text = user.phoneNumber;
          } else {
            print('User null di showRewardDialog');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Gagal mendapatkan data user untuk dialog.')),
            );
          }
        });

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Masukkan Informasi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Nomor Telepon'),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                String phone = phoneController.text.trim();
                int? balance;
                if (_selectedNominal != null) {
                  balance = _selectedNominal;
                } else {
                  String cleanValue = widget.customAmountController.text.replaceAll(
                    RegExp(r'\D'),
                    '',
                  );
                  balance = int.tryParse(cleanValue);
                }

                if (phone.isNotEmpty && balance != null && balance >= 10000) {
                  bool success = await _apiService.submitReward(
                    phone: phone,
                    email: userEmail,
                    balance: balance,
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Berhasil menyimpan data!'
                            : 'Gagal menyimpan data!',
                      ),
                    ),
                  );
                  if (success) {
                    Navigator.pop(context);
                    widget.onPointsUpdated();
                    _fetchCurrentUserPoints();
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Pastikan semua informasi valid dan nominal minimal Rp 10.000',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Kirim'),
            ),
          ],
        );
      },
    );
  }

Widget _buildPaymentOption(
    BuildContext context,
    String assetPath,
    String title,
  ) {
    bool isSelected = selectedPaymentMethod == title;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,

      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? _kSelectedBackgroundColor
            : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isSelected
              ? _kSelectedBorderColor
              : Colors.grey.shade300,
          width: isSelected ? 2.5 : 1.0,
        ),
        boxShadow: [
          if (isSelected)
            BoxShadow(
              color: _kSelectedShadowColor,
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          if (!isSelected)
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.2),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: () {
            setState(() {
              selectedPaymentMethod = isSelected ? null : title;
            });
          },
          borderRadius: BorderRadius.circular(
            15,
          ),
          child: Padding(
            padding: const EdgeInsets.all(
              13.0,
            ),
            child: Row(
              children: [
                Image.asset(
                  assetPath,
                  width: 45,
                  height: 45,
                  color: isSelected
                      ? Colors.white
                      : null,
                  colorBlendMode: isSelected
                      ? BlendMode.srcIn
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : Colors.black87,
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.w600,
                      fontSize: 17,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? Colors.white
                        : Colors.white,
                    border: Border.all(
                      color: isSelected
                          ? _kSelectedBorderColor
                          : Colors.grey.shade400,
                      width: 2.0,
                    ),
                  ),
                  child: Center(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: isSelected ? 1.0 : 0.0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              _kSelectedBorderColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNominalOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildNominalButton(
                'Rp 10.000',
                10000,
              ),
              _buildNominalButton('Rp 30.000', 30000),
              _buildNominalButton('Rp 50.000', 50000),
              _buildNominalButton('Rp 100.000', 100000),
            ],
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: widget.customAmountController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            CurrencyInputFormatter(),
          ],
          onChanged: (formattedValue) {
            setState(() {
              _selectedNominal = null;
              // Selalu bersihkan nilai dari controller untuk mendapatkan nilai numerik murni
              String cleanValue = widget.customAmountController.text.replaceAll(
                RegExp(r'\D'),
                '',
              );
              int? nominal = int.tryParse(cleanValue);

              if (nominal != null) {
                if (nominal >= 10000) {
                  _requiredPoints = nominal ~/ 10;
                } else {
                  _requiredPoints = 0;
                }
              } else {
                _requiredPoints = 0;
              }
            });
          },
          decoration: InputDecoration(
            hintText: 'Masukkan nominal lain (minimal Rp 10.000)',
            hintStyle: const TextStyle(
              fontSize: 14,
              color: Color.fromARGB(255, 176, 176, 176),
            ),
            fillColor: Colors.white,
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color:
                    widget.customAmountController.text.isNotEmpty &&
                            int.tryParse(
                                    widget.customAmountController.text.replaceAll(
                                      RegExp(r'\D'),
                                      '',
                                    ),
                                  ) !=
                                  null &&
                            int.tryParse(
                                    widget.customAmountController.text.replaceAll(
                                      RegExp(r'\D'),
                                      '',
                                    ),
                                  )! <
                                  10000
                        ? Colors.red
                        : Colors.grey,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(
                  context,
                ).primaryColor,
                width: 2.0,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14.0,
              horizontal: 16.0,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Minimal Rp 10.000 untuk penukaran',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color:
                widget.customAmountController.text.isNotEmpty &&
                        int.tryParse(
                                widget.customAmountController.text.replaceAll(
                                  RegExp(r'\D'),
                                  '',
                                ),
                              ) !=
                              null &&
                        int.tryParse(
                                widget.customAmountController.text.replaceAll(
                                  RegExp(r'\D'),
                                  '',
                                ),
                              )! <
                              10000
                    ? Colors.red
                    : const Color.fromARGB(255, 84, 84, 84),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Poin yang dibutuhkan: $_requiredPoints Poin',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildNominalButton(String label, int nominalValue) {
    final bool isSelected = _selectedNominal == nominalValue;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: Theme.of(context).primaryColor.withValues(
        alpha: 0.2,
      ),
      checkmarkColor: const Color.fromRGBO(85, 132, 122, 0.969),
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedNominal = nominalValue;
            _requiredPoints = nominalValue ~/ 10;
            widget.customAmountController.clear();
          } else {
            _selectedNominal = null;
            _requiredPoints = 0;
          }
        });
      },
      labelStyle: TextStyle(
        color: isSelected
            ? Theme.of(context).primaryColor
            : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 14,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Colors.grey[400]!,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      backgroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 10,
      ),
    );
  }
}
