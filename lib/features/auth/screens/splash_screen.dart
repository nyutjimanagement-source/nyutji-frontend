import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    
    _fadeController.forward();
    _checkAuth();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 3));
    
    if (!mounted) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final hasToken = await authProvider.checkAuthStatus();
    
    if (!mounted) return;
    
    if (hasToken) {
      String targetRoute = '/login';
      switch (authProvider.role) {
        case 'PL': targetRoute = '/customer_main'; break;
        case 'ML': targetRoute = '/mitra_home'; break;
        case 'KL': targetRoute = '/courier_main'; break;
        case 'AD': targetRoute = '/admin_main'; break;
        default: targetRoute = '/login';
      }
      Navigator.pushReplacementNamed(context, targetRoute);
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F4E6),
      body: Container(
        width: double.infinity,
        color: const Color(0xFFF8F4E6),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo_nyutji.png',
                height: 140,
                errorBuilder: (context, error, stackTrace) => Column(
                  children: [
                    const Icon(Icons.local_laundry_service, size: 64, color: Color(0xFF1E5655)),
                    const SizedBox(height: 12),
                    Text(
                      'Ny Utji',
                      style: GoogleFonts.montserrat(
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E5655),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "WELCOME TO NYUTJI MANAGEMENT",
                style: GoogleFonts.montserrat(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Colors.grey[400],
                  letterSpacing: 2.5,
                ),
              ),
              const SizedBox(height: 80),
              Stack(
                alignment: Alignment.center,
                children: [
                  const SizedBox(
                    height: 50,
                    width: 50,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E5655)),
                      backgroundColor: Color(0xFFF3F4F6),
                    ),
                  ),
                  Icon(Icons.water_drop, size: 20, color: const Color(0xFF1E5655).withValues(alpha: 0.4)),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                "MEMULAI MESIN...",
                style: GoogleFonts.montserrat(
                  fontSize: 10, 
                  color: const Color(0xFF1E5655), 
                  fontWeight: FontWeight.bold, 
                  letterSpacing: 2.0,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
