import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:http/http.dart' as http;
import '../../providers/auth_provider.dart';
import 'shimmer_loading.dart';

class ForecastWeather extends ConsumerStatefulWidget {
  const ForecastWeather({super.key});

  @override ConsumerState<ForecastWeather> createState() => _ForecastWeatherState();
}

class _ForecastWeatherState extends ConsumerState<ForecastWeather> {
  bool _isLoading = true;
  Map<String, dynamic>? _weatherData;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    final auth = ref.read(authProvider);
    final lat = auth.user?['lat'] ?? -6.2088;
    final lng = auth.user?['lng'] ?? 106.8456;

    try {
      final url = Uri.parse(
          "https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lng&current=temperature_2m,relative_humidity_2m,weather_code&timezone=auto");
      final response = await http.get(url);
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _weatherData = json.decode(response.body);
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Weather Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getWeatherEmoji(int code) {
    if (code == 0) return "☀️";
    if (code <= 3) return "⛅";
    if (code <= 48) return "🌫️";
    if (code <= 55) return "🌧️";
    if (code <= 65) return "🌧️";
    if (code <= 75) return "❄️";
    if (code <= 82) return "⛈️";
    if (code <= 99) return "🌩️";
    return "☁️";
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: ShimmerLoading(
          height: 90, 
          borderRadius: 16,
          baseColor: Color(0xFF1E293B),
          highlightColor: Color(0xFF334155),
        ),
      );
    }

    if (_weatherData == null) return const SizedBox.shrink();

    final currentTemp = _weatherData!['current']['temperature_2m'].round();
    final humidity = _weatherData!['current']['relative_humidity_2m']?.round() ?? 0;
    final weatherCode = _weatherData!['current']['weather_code'];
    final auth = ref.read(authProvider);
    final city = auth.user?['owner_city_name'] ?? auth.user?['city_name'] ?? "Lokasi Mitra";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF334155)], 
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.navigation, color: Colors.white, size: 14),
                  const SizedBox(width: 8),
                  Text(
                    city,
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    _getWeatherEmoji(weatherCode),
                    style: const TextStyle(fontSize: 40, height: 1),
                  ),
                  const SizedBox(width: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$currentTemp",
                        style: GoogleFonts.montserrat(
                          fontSize: 42,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 2),
                        child: Text(
                          "°C",
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(LucideIcons.droplet, color: Colors.lightBlueAccent, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    "Kelembapan $humidity%",
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
