import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:permission_handler/permission_handler.dart';

class SunlightScreen extends StatefulWidget {
  @override
  _SunlightScreenState createState() => _SunlightScreenState();
}

class _SunlightScreenState extends State<SunlightScreen> {
  Position? _currentPosition;
  MapController _mapController = MapController();
  List<SeasonalData> _seasonalAverages = [];
  String? _zipCode;
  Map<String, dynamic>? _zoneData;
  bool _loading = true;
  String _error = '';

  // Demo: Sample plant min temp in °F (replace with actual from Perenual, e.g., for scanned plant)
  final double _samplePlantMinTempF = 50.0;  // e.g., Monstera min

  @override
  void initState() {
    super.initState();
    _getLocationAndData();
  }

  Future<void> _getLocationAndData() async {
    // Request permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() { _error = 'Location permission denied'; _loading = false; });
        return;
      }
    }

    try {
      _currentPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      
      // Fetch ZIP via reverse geocoding (Nominatim)
      await _fetchZipCode(_currentPosition!.latitude, _currentPosition!.longitude);
      
      // Fetch USDA Zone via ZIP
      if (_zipCode != null) {
        await _fetchZoneData(_zipCode!);
      }
      
      // Fetch sunlight data
      await _fetchSunlightData(_currentPosition!.latitude, _currentPosition!.longitude);
      
      if (mounted) setState(() { _loading = false; });
      // Center map on position
      _mapController.move(LatLng(_currentPosition!.latitude, _currentPosition!.longitude), 13.0);
    } catch (e) {
      setState(() { _error = 'Error getting location: $e'; _loading = false; });
    }
  }

  Future<void> _fetchZipCode(double lat, double lon) async {
    final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&zoom=18&addressdetails=1');
    final response = await http.get(url, headers: {'User-Agent': 'MYgardenai/1.0'});
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _zipCode = data['address']?['postcode'];
      if (mounted) setState(() {});
    }
  }

  Future<void> _fetchZoneData(String zip) async {
    final url = Uri.parse('https://phytozones.org/api/zone/$zip');  // Free phzmapi.org endpoint
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (mounted) setState(() { _zoneData = data; });
    }
  }

  Future<void> _fetchSunlightData(double lat, double lon) async {
    const startDate = '2014-01-01';
    const endDate = '2023-12-31';
    final url = Uri.parse(
      'https://archive-api.open-meteo.com/v1/archive?latitude=$lat&longitude=$lon&start_date=$startDate&end_date=$endDate&daily=sunshine_duration&timezone=auto'
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final times = List<String>.from(data['daily']['time']);
      final durations = List<double>.from(data['daily']['sunshine_duration']); // in seconds

      // Compute seasonal averages (Northern Hemisphere)
      final seasons = <String, List<double>>{
        'Winter': [], 'Spring': [], 'Summer': [], 'Fall': [],
      };
      for (int i = 0; i < times.length; i++) {
        final month = int.parse(times[i].split('-')[1]);
        String season;
        if (month >= 12 || month <= 2) season = 'Winter';
        else if (month <= 5) season = 'Spring';
        else if (month <= 8) season = 'Summer';
        else season = 'Fall';
        seasons[season]!.add(durations[i] / 3600); // Convert to hours
      }

      final averages = seasons.map((season, values) => MapEntry(
        season,
        values.isEmpty ? 0.0 : values.reduce((a, b) => a + b) / values.length
      ));

      if (mounted) {
        setState(() {
          _seasonalAverages = averages.entries.map((e) => SeasonalData(e.key, e.value)).toList();
        });
      }
    } else {
      throw Exception('Failed to load data');
    }
  }

  String _getZoneCompatibility() {
    if (_zoneData == null) return 'N/A';
    final zoneMinF = double.tryParse(_zoneData!['min_temp'] ?? '0') ?? 0.0;
    if (_samplePlantMinTempF > zoneMinF) {
      return '⚠️ Marginal—protect from frost.';
    } else {
      return '✅ Suitable for your zone.';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(appBar: AppBar(title: Text('Sunlight Map')), body: Center(child: CircularProgressIndicator()));
    }
    if (_error.isNotEmpty) {
      return Scaffold(appBar: AppBar(title: Text('Sunlight Map')), body: Center(child: Text(_error)));
    }

    return Scaffold(
      appBar: AppBar(title: Text('Sunlight & Zone Map')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(_currentPosition?.latitude ?? 52.52, _currentPosition?.longitude ?? 13.41),
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.mygardenai',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                    child: Icon(Icons.location_pin, color: Colors.red, size: 40),
                  ),
                ],
              ),
            ],
          ),
          if (_seasonalAverages.isNotEmpty || _zoneData != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: _zoneData != null ? 350 : 250,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black26)],
                ),
                child: Column(
                  children: [
                    if (_zoneData != null) ...[
                      Text('USDA Zone: `\({_zoneData!['zone'] ?? 'N/A'} (\)`{_zoneData!['name'] ?? ''})', 
                           style: Theme.of(context).textTheme.titleLarge),
                      Text('Min/Max Temp: ${_zoneData!['min_temp'] ?? ''}°F to ${_zoneData!['max_temp'] ?? ''}°F'),
                      Text('Sample Plant Fit: ${_getZoneCompatibility()}'),
                      SizedBox(height: 10),
                    ],
                    Text('Avg Daily Sunshine Hours', style: Theme.of(context).textTheme.titleLarge),
                    SizedBox(height: 10),
                    SizedBox(
                      height: 150,
                      child: BarChart(
                        BarChartData(
                          barGroups: _seasonalAverages.asMap().entries.map((e) {
                            final index = e.key;
                            final data = e.value;
                            return BarChartGroupData(
                              x: index,
                              barRods: [BarChartRodData(toY: data.hours, color: Colors.orange, width: 20)],
                            );
                          }).toList(),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) => Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Text(_seasonalAverages[value.toInt()].season.substring(0, 1)),
                              ),
                            )),
                            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
                            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false),
                          barTouchData: BarTouchData(enabled: false),
                        ),
                      ),
                    ),
                    Text('${_currentPosition!.latitude.toStringAsFixed(2)}, ${_currentPosition!.longitude.toStringAsFixed(2)}'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class SeasonalData {
  final String season;
  final double hours;
  SeasonalData(this.season, this.hours);
}
