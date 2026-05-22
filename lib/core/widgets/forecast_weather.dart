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
          "https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lng&current=temperature_2m,weather_code&daily=weather_code,temperature_2m_max,temperature_2m_min&timezone=auto");
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

  IconData _getWeatherIcon(int code) {
    if (code == 0) return LucideIcons.sun;
    if (code <= 3) return LucideIcons.cloudSun;
    if (code <= 48) return LucideIcons.cloudFog;
    if (code <= 55) return LucideIcons.cloudDrizzle;
    if (code <= 65) return LucideIcons.cloudRain;
    if (code <= 75) return LucideIcons.snowflake;
    if (code <= 82) return LucideIcons.cloudRain;
    if (code <= 99) return LucideIcons.cloudLightning;
    return LucideIcons.cloud;
  }

  String _getWeatherDesc(int code) {
    if (code == 0) return "Cerah";
    if (code <= 3) return "Berawan";
    if (code <= 48) return "Berkabut";
    if (code <= 55) return "Gerimis";
    if (code <= 65) return "Hujan";
    if (code <= 75) return "Salju";
    if (code <= 82) return "Hujan Deras";
    if (code <= 99) return "Badai Petir";
    return "Berawan";
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
    final weatherCode = _weatherData!['current']['weather_code'];
    final daily = _weatherData!['daily'];
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final city = auth.user?['owner_city_name'] ?? auth.user?['city_name'] ?? "Lokasi Mitra";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF2E8B89), Color(0xFF1E5655)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E5655).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.mapPin, color: Colors.white70, size: 14),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            city.toUpperCase(),
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.white70,
                              letterSpacing: 1,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$currentTemp",
                        style: GoogleFonts.montserrat(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          "°C",
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getWeatherDesc(weatherCode),
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Icon(
                  _getWeatherIcon(weatherCode),
                  size: 60,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildForecastItem("Hari Ini", daily['temperature_2m_max'][0].round(), daily['weather_code'][0]),
                _buildDivider(),
                _buildForecastItem("2 Hari", daily['temperature_2m_max'][2].round(), daily['weather_code'][2]),
                _buildDivider(),
                _buildForecastItem("5 Hari", daily['temperature_2m_max'][5].round(), daily['weather_code'][5]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 20, color: Colors.white24);
  }

  Widget _buildForecastItem(String label, int temp, int code) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_getWeatherIcon(code), size: 14, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              "$temp°",
              style: GoogleFonts.montserrat(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ],
    );
  }
}
