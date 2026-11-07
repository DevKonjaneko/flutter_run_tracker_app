import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main.dart';
import 'show_all_run_ui.dart';

class SplashScreenUi extends StatefulWidget {
  const SplashScreenUi({super.key});

  @override
  State<SplashScreenUi> createState() => _SplashScreenUiState();
}

class _SplashScreenUiState extends State<SplashScreenUi> {
  @override
  void initState() {
    super.initState();
    _checkDataAndNavigate();
  }

  Future<void> _checkDataAndNavigate() async {
    await Future.delayed(const Duration(seconds: 3));

    bool hasData = false;
    try {
      final response = await supabase.from('runs').select('id').limit(1);
      hasData = response.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking DB: $e');
      hasData = false;
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ShowAllRunUi(hasInitialData: hasData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1244),
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              const Spacer(flex: 2),

              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.directions_run_rounded,
                  size: 72,
                  color: Color(0xFF38BDF8),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'RUN TRACKER',
                style: GoogleFonts.kanit(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 14),

              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
                ),
              ),

              const Spacer(flex: 3),

              Text(
                '© 2026 RUN TRACKER\nCreated by Ninnin SAU TEAM',
                textAlign: TextAlign.center,
                style: GoogleFonts.kanit(
                  color: Colors.white54,
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}