import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'cached_tile_provider.dart';

class MapSearchPage extends StatefulWidget {
  const MapSearchPage({super.key});

  @override
  State<MapSearchPage> createState() => _MapSearchPageState();
}

class _MapSearchPageState extends State<MapSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final MapController _mapController = MapController();

  LatLng? selectedLocation;
  String? weatherInfo;
  String? locationName;
  Map<String, dynamic>? weatherData;
  bool isLoading = false;

  Future<Map<String, dynamic>?> searchLocation(String query) async {
    try {
      final url = Uri.parse(
          "");

      final response = await http.get(url, headers: {
        "User-Agent": "flutter-map-example"
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data.isNotEmpty) {
          return {
            "lat": double.parse(data[0]["lat"]),
            "lon": double.parse(data[0]["lon"]),
            "name": data[0]["display_name"],
          };
        }
      }
    } catch (e) {
      debugPrint("Error search: $e");
    }
    return null;
  }

  Future<Map<String, dynamic>?> getWeather(double lat, double lon) async {
    try {
      final key = dotenv.env["OPENWEATHER_KEY"];
      if (key == null || key.isEmpty) return null;

      final url = Uri.parse(
          "");

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          "temp": data["main"]["temp"].round(),
          "feels_like": data["main"]["feels_like"].round(),
          "description": data["weather"][0]["description"],
          "icon": data["weather"][0]["icon"],
          "humidity": data["main"]["humidity"],
          "wind_speed": data["wind"]["speed"],
        };
      }
    } catch (e) {
      debugPrint("Error weather: $e");
    }
    return null;
  }

  void onSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      isLoading = true;
    });

    final result = await searchLocation(query);

    if (result != null) {
      final lat = result["lat"];
      final lon = result["lon"];

      setState(() {
        selectedLocation = LatLng(lat, lon);
        locationName = result["name"];
        weatherData = null;
      });

      _mapController.move(LatLng(lat, lon), 15.0);
      await Future.delayed(const Duration(milliseconds: 300));

      final weather = await getWeather(lat, lon);

      setState(() {
        weatherData = weather;
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Lokasi tidak ditemukan"),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  IconData getWeatherIcon(String? description) {
    if (description == null) return Icons.wb_sunny;
    
    description = description.toLowerCase();
    if (description.contains('rain') || description.contains('hujan')) {
      return Icons.umbrella;
    } else if (description.contains('cloud') || description.contains('awan')) {
      return Icons.cloud;
    } else if (description.contains('clear') || description.contains('cerah')) {
      return Icons.wb_sunny;
    } else if (description.contains('thunder') || description.contains('petir')) {
      return Icons.flash_on;
    }
    return Icons.wb_cloudy;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            // HEADER & SEARCH BAR
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[700]!, Colors.blue[500]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                    child: Row(
                      children: [
                        Icon(Icons.map, color: Colors.white, size: 28),
                        const SizedBox(width: 12),
                        const Text(
                          "Peta & Cuaca",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onSubmitted: (_) => onSearch(),
                              decoration: InputDecoration(
                                hintText: "Cari lokasi...",
                                hintStyle: TextStyle(color: Colors.grey[400]),
                                prefixIcon: Icon(Icons.search, color: Colors.blue[700]),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 15,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.all(8),
                            child: ElevatedButton(
                              onPressed: isLoading ? null : onSearch,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[700],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 0,
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      "Cari",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // WEATHER CARD - COMPACT VERSION
            if (weatherData != null && locationName != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[400]!, Colors.blue[600]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Icon & Temp
                      Icon(
                        getWeatherIcon(weatherData!["description"]),
                        color: Colors.white,
                        size: 48,
                      ),
                      const SizedBox(width: 12),
                      
                      // Main Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  color: Colors.white.withOpacity(0.9),
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    locationName!.split(',').first,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${weatherData!["temp"]}°C",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                height: 1,
                              ),
                            ),
                            Text(
                              weatherData!["description"].toString().toUpperCase(),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Quick Stats
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _buildCompactStat(Icons.water_drop, "${weatherData!["humidity"]}%"),
                          const SizedBox(height: 8),
                          _buildCompactStat(Icons.air, "${weatherData!["wind_speed"]} m/s"),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            // MAP
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: LatLng(-7.5600, 110.8300),
                    initialZoom: 13,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          "https://cartodb-basemaps-a.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png",
                      tileProvider: CachedTileProvider(),
                      userAgentPackageName: "your.app.id",
                    ),
                    if (selectedLocation != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            width: 50,
                            height: 50,
                            point: selectedLocation!,
                            child: Icon(
                              Icons.location_pin,
                              color: Colors.red[700],
                              size: 50,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactStat(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.9), size: 16),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
