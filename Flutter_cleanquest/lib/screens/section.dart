import 'package:flutter/material.dart';
import 'package:cleanquest/screens/login.dart';
import 'register.dart';

class SectionPage extends StatefulWidget {
  const SectionPage({super.key});

  @override
  Sectionstate createState() => Sectionstate();
}

class Sectionstate extends State<SectionPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    // Pastikan untuk membuang controller saat halaman dihapus
    nameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // Variabel untuk mengontrol skala tombol
  double scale = 1.0;
  double opact = 1.0;

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
              // Judul
              Container(
                padding: const EdgeInsets.only(bottom: 60, top: 300),
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

              // Tombol Login
              button(),

              const SizedBox(height: 25),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                      );
                    },
                    child: const Text(
                      "Log in",
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Poppins',
                        fontSize: 15,
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

  // Method untuk membangun tombol dengan gambar
  Widget button() {
    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          scale = 0.9;
          opact = 0.7;
        });
      },
      onTapUp: (_) {
        setState(() {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RegisterPage()),
          );
          scale = 1.0;
          opact = 1.0;
        });
      },
      child: AnimatedOpacity(
        opacity: opact,
        duration: const Duration(milliseconds: 100),
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 100),
          child: Image.asset(
            'assets/images/Secbutton.png',
          ),
        ),
      ),
    );
  }
}
