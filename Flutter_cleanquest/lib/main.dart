import 'package:flutter/material.dart';
import 'screens/splash.dart'; // Ensure this path is correct for your SplashScreen
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Pastikan Flutter binding sudah diinisialisasi
  await initializeDateFormatting('id_ID', null); // Inisialisasi data locale untuk Bahasa Indonesia
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clean Quest App',
      // --- START: Global Theme Colors ---
      theme: ThemeData(
        // The main color for your app's branding
        primaryColor: const Color.fromRGBO(85, 132, 122, 0.969), // A shade of Teal

        // A more modern way to define a harmonious set of colors
        // from a single "seed" color.
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromRGBO(85, 132, 122, 0.969), // Use your primary color as the seed
          primary: const Color.fromRGBO(85, 132, 122, 0.969),   // Explicit primary color
          onPrimary: Colors.white,           // Text/icons color on primary background
          secondary: const Color.fromRGBO(85, 132, 122, 0.969),  // A secondary accent color (e.g., for FABs)
          onSecondary: Colors.black,         // Text/icons color on secondary background
          background: const Color(0xFFF5F5F5), // General app background color
          onBackground: Colors.black87,      // Text/icons color on background
          surface: Colors.white,             // Card, dialog, sheet backgrounds
          onSurface: Colors.black87,         // Text/icons color on surface
        ),

        // Default background color for most screens (Scaffold)
        scaffoldBackgroundColor: const Color(0xFFF5F5F5), // Light grey

        // You can also fine-tune specific widget themes here, for example:
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromRGBO(85, 132, 122, 0.969), // Teal AppBar background
          foregroundColor: Colors.white,      // White icons/text in AppBar
        ),
        
        // This will affect your TextField's default look
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Color.fromRGBO(85, 132, 122, 0.969), width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.grey, width: 1),
          ),
        ),
      ),

      home: SplashScreen(), // Your app starts here
    );
  }
}