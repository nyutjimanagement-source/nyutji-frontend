import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class ForecastWeather extends StatefulWidget {
  const ForecastWeather({super.key});

  @override
  State<ForecastWeather> createState() => _ForecastWeatherState();
}

class _ForecastWeatherState extends State<ForecastWeather> {
  bool _isLoading = true;
  Map<String, dynamic>? _weatherData;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
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
      return Container(
        height: 120,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFF286B6A), Color(0xFF1E5655)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
      );
    }

    if (_weatherData == null) return const SizedBox.shrink();

    final currentTemp = _weatherData!['current']['temperature_2m'].round();
    final humidity = _weatherData!['current']['relative_humidity_2m']?.round() ?? 0;
    final weatherCode = _weatherData!['current']['weather_code'];
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final city = auth.user?['owner_city_name'] ?? auth.user?['city_name'] ?? "Lokasi Mitra";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
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
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(LucideIcons.chevronDown, color: Colors.white70, size: 14),
                ],
              ),
              const Icon(LucideIcons.moreHorizontal, color: Colors.white70, size: 18),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    _getWeatherEmoji(weatherCode),
                    style: const TextStyle(fontSize: 46, height: 1),
                  ),
                  const SizedBox(width: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$currentTemp",
                        style: GoogleFonts.montserrat(
                          fontSize: 52,
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
                            fontSize: 18,
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
                  const SizedBox(width: 2),
                  const Icon(LucideIcons.chevronRight, color: Colors.white, size: 16),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
