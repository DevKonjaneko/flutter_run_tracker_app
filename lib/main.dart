import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'splash_screen_ui.dart';

final SupabaseClient supabase = Supabase.instance.client;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://yvavsnadcwmuwsrsbyur.supabase.co',
    anonKey: 'sb_publishable_7M9f5mThneRv74DwijIabw_4YgOEvIT',
  );

  runApp(const FlutterRunTrackerApp());
}

class FlutterRunTrackerApp extends StatelessWidget {
  const FlutterRunTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Run Tracker',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: GoogleFonts.kanit().fontFamily,
        scaffoldBackgroundColor: const Color(0xFFFBFBFE),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0A1244),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
      ),
      home: const SplashScreenUi(),
    );
  }
}