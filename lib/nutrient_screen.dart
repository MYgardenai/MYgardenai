import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'nutrient_details_screen.dart';

class NutrientScreen extends StatefulWidget {
  @override
  _NutrientScreenState createState() => _NutrientScreenState();
}

class _NutrientScreenState extends State<NutrientScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  String _result = '';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final camera = cameras.first;
    _controller = CameraController(camera, ResolutionPreset.high);
    _initializeControllerFuture = _controller!.initialize();
    setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;
      final image = await _controller!.takePicture();
      final identifiedDeficiency = await _identifyDeficiency(image.path);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NutrientDetailsScreen(deficiencyData: identifiedDeficiency),
        ),
      );
    } catch (e) {
      setState(() { _result = 'Error: $e'; });
    }
  }

  Future<Map<String, dynamic>> _identifyDeficiency(String imagePath) async {
    final uri = Uri.parse('https://api.crop.health/v1/identification');
    var request = http.MultipartRequest('POST', uri);
    request.fields['api_key'] = 'YOUR_CROP_HEALTH_KEY';  // Replace with your key
    request.files.add(await http.MultipartFile.fromPath('images[0]', imagePath));
    request.fields['plant_language'] = 'en';
    // Optional: request.fields['modifiers'] = 'crop_name:apple';  // e.g., for specific crop

    var streamedResponse = await request.send();
    var response = http.Response.fromStream(streamedResponse);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final healthSuggestions = data['health']?['suggestions'] ?? [];
      // Filter for nutrient-related
      final nutrientSuggestions = healthSuggestions.where((s) => 
        (s['class']?.toLowerCase().contains('deficiency') ?? false) ||
        (s['cause']?.toLowerCase().contains('nutrient') ?? false)
      ).toList();
      if (nutrientSuggestions.isNotEmpty) {
        return nutrientSuggestions[0];  // Top nutrient match
      }
    }
    throw Exception('Nutrient deficiency identification failed');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Scan for Nutrient Deficiencies')),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                Positioned.fill(child: CameraPreview(_controller!)),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: ElevatedButton(
                      onPressed: _takePicture,
                      child: Text('Capture & Identify Deficiency'),
                      style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50)),
                    ),
                  ),
                ),
                if (_result.isNotEmpty)
                  Positioned(
                    top: 100,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: EdgeInsets.all(10),
                      color: Colors.red.withOpacity(0.8),
                      child: Text(_result, style: TextStyle(color: Colors.white)),
                    ),
                  ),
              ],
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
