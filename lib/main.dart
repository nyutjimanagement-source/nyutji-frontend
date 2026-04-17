import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_util.dart';

import 'providers/auth_provider.dart';
import 'providers/wallet_provider.dart';
import 'providers/order_provider.dart';
import 'providers/issue_provider.dart';
import 'providers/sentiment_provider.dart';

import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_pelanggan_screen.dart';
import 'features/customer_pl/screens/customer_main_screen.dart';
import 'features/mitra_ml/screens/mitra_order_screen.dart';
import 'features/mitra_ml/screens/mitra_home_screen.dart';
import 'features/courier_kl/screens/courier_main_screen.dart';
import 'features/admin_ad/screens/admin_main_screen.dart';
import 'features/mitra_ml/screens/mitra_report_issue_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inisialisasi locale Indonesia
  await initializeDateFormatting('id_ID', null);
  // Hanya gunakan font lokal dari assets/google_fonts/
  GoogleFonts.config.allowRuntimeFetching = false;
  runApp(const NyutjiApp());
}

class NyutjiApp extends StatelessWidget {
  const NyutjiApp({super.key});

  @override
  Widget build(BuildContext context) {
    TextTheme textTheme = createTextTheme(context, "Montserrat", "Montserrat");
    MaterialTheme theme = MaterialTheme(textTheme);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => IssueProvider()),
        ChangeNotifierProvider(create: (_) => SentimentProvider()),
      ],
      child: MaterialApp(
        title: 'Nyutji Laundry',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.system,
        theme: theme.light(),
        darkTheme: theme.dark(),
        initialRoute: '/',
        builder: (context, child) {
          return Container(
            color: const Color(0xFF171717), // Background luar area HP
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 450),
                child: child,
              ),
            ),
          );
        },
        onGenerateRoute: (settings) {
          Widget page;
          switch (settings.name) {
            case '/':
              page = const SplashScreen();
              break;
            case '/login':
              page = const LoginScreen();
              break;
            case '/register':
              page = const RegisterPelangganScreen();
              break;
            case '/customer_main':
              page = const CustomerMainScreen();
              break;
            case '/mitra_order':
              page = const MitraOrderScreen();
              break;
            case '/mitra_home':
              page = const MitraHomeScreen();
              break;
            case '/courier_main':
              page = const CourierMainScreen();
              break;
            case '/admin_main':
              page = const AdminMainScreen();
              break;
            case '/mitra_report_issue':
              page = const MitraReportIssueScreen();
              break;
            default:
              page = const SplashScreen();
          }
          return RetroRoute(page: page);
        },
      ),
    );
  }
}
