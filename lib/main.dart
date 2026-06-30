import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:firebase_core/firebase_core.dart';
import 'data/services/fcm_service.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_util.dart';

import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_pelanggan_screen.dart';
import 'features/customer_pl/screens/customer_main_screen.dart';
import 'features/mitra_ml/screens/mitra_order_screen.dart';
import 'features/mitra_ml/screens/mitra_home_screen.dart';
import 'features/kurir_kl/screens/courier_main_screen.dart';
import 'features/admin_ad/screens/admin_main_screen.dart';
import 'features/mitra_ml/screens/mitra_kendala_screen.dart';
import 'features/notifications/screens/notification_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inisialisasi Database Lokal untuk Offline Queue
  await Hive.initFlutter();
  await Hive.openBox('offline_queue');
  await Hive.openBox('nyutji_cache');
  await Hive.openBox('nyutji_notifications');

  // Inisialisasi Firebase & FCM Notifikasi secara aman
  try {
    await Firebase.initializeApp();
    await FcmService().initNotifications();
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }
  
  // Inisialisasi Background Sync
  // BackgroundSyncService.initialize();

  // Inisialisasi locale Indonesia
  await initializeDateFormatting('id_ID', null);
  // Hanya gunakan font lokal dari assets/google_fonts/
  GoogleFonts.config.allowRuntimeFetching = false;
  runApp(const ProviderScope(child: NyutjiApp()));
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class NyutjiApp extends ConsumerWidget {
  const NyutjiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    TextTheme textTheme = createTextTheme(context, "Montserrat", "Montserrat");
    MaterialTheme theme = MaterialTheme(textTheme);

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Nyutji Laundry',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      theme: theme.light(),
      initialRoute: '/',
      builder: (context, child) {
          return Container(
            color: const Color(0xFF171717),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 450),
                child: MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: const TextScaler.linear(1.0),
                  ),
                  child: child!,
                ),
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
              page = const MitraKendalaScreen();
              break;
            case '/notifications':
              page = const NotificationScreen();
              break;
            default:
              page = const SplashScreen();
          }
          return RetroRoute(page: page);
        },
      );
  }
}
