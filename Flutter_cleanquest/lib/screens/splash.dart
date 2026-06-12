import 'package:flutter/material.dart';
import 'package:cleanquest/screens/section.dart';
import 'package:cleanquest/services/api_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _waitForApiReady();
  }

  void _waitForApiReady() async {
    bool ready = false;

    print('DEBUG_SPLASH: Starting _waitForApiReady...');
    await Future.delayed(const Duration(milliseconds: 300)); // Optional small delay

    while (!ready) {
      print('DEBUG_SPLASH: Pinging API...');
      ready = await _apiService.ping();

      if (ready) {
        print('DEBUG_SPLASH: API is ready. Checking token...');
        if (!mounted) return;

        final token = await _apiService.getToken(); // Ini akan memicu print di ApiService

        print('DEBUG_SPLASH: Token status: ${token != null ? "EXISTS" : "NULL"}. Navigating...');

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                token != null ? const SectionPage() : const SectionPage(),
          ),
        );
      } else {
        print('DEBUG_SPLASH: API not ready, retrying in 300ms...');
        await Future.delayed(const Duration(milliseconds: 300));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/suBackground.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.only(bottom: 60, top: 100),
              child: const Text(
                'Clean Quest',
                style: TextStyle(
                  fontSize: 45,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  color: Color.fromRGBO(85, 132, 122, 100),
                ),
              ),
            ),
            const CircularProgressIndicator(), // Menampilkan indikator pemuatan
          ],
        ),
      ),
    );
  }
}